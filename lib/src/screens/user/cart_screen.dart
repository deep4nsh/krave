import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../models/canteen_model.dart';
import '../../services/payment_service.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/cart_provider.dart';
import '../../services/user_provider.dart';
import '../../config.dart';
import '../../theme/app_colors.dart';
import '../../widgets/krave_loading.dart';
import 'order_tracking.dart';

class CartScreen extends StatefulWidget {
  final Canteen canteen;
  const CartScreen({super.key, required this.canteen});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final PaymentService _payment = PaymentService();
  bool _isProcessing = false;
  String _orderType = 'dineIn'; 
  String _paymentMethod = 'razorpay'; 

  @override
  void initState() {
    super.initState();
    _payment.init(
      onSuccess: _onPaymentSuccess,
      onError: _onPaymentError,
      onExternal: _onExternalWallet,
    );
  }

  @override
  void dispose() {
    _payment.dispose();
    super.dispose();
  }

  Future<void> _onPaymentSuccess(PaymentSuccessResponse response) async {
    _completeOrder(response.paymentId ?? 'external_id');
  }

  Future<void> _completeOrder(String txId) async {
    final cart = context.read<CartProvider>();
    final userProvider = context.read<UserProvider>();
    final fs = context.read<FirestoreService>();
    final navigator = Navigator.of(context);

    try {
      final orderId = await fs.createOrder(
        user: userProvider.user!,
        canteen: widget.canteen,
        items: cart.items.values.map((item) => item.toMap()).toList(),
        totalAmount: (cart.totalAmount + (_orderType == 'delivery' ? 15 : 2)).toInt(),
        paymentId: txId,
        orderType: _orderType,
      );

      setState(() => _isProcessing = false);
      cart.clearCart();

      if (mounted) {
        navigator.popUntil((route) => route.isFirst);
        navigator.push(MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: orderId)));
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order failed: $e')));
      }
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment Failed.')));
  }

  void _onExternalWallet(ExternalWalletResponse response) {}

  Future<void> _checkout() async {
    final cart = context.read<CartProvider>();
    final userProvider = context.read<UserProvider>();
    final fs = context.read<FirestoreService>();

    final total = cart.totalAmount + (_orderType == 'delivery' ? 15 : 2);

    setState(() => _isProcessing = true);

    if (_paymentMethod == 'wallet') {
      if (userProvider.balance < total) {
        HapticFeedback.vibrate();
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient Wallet Balance!')));
        return;
      }
      
      try {
        HapticFeedback.mediumImpact();
        await fs.processWalletPayment(userProvider.user!.id, total.toDouble(), 'pending_order');
        _completeOrder('wallet_tx_${DateTime.now().millisecondsSinceEpoch}');
      } catch (e) {
        if (mounted) {
          HapticFeedback.vibrate();
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Wallet Error: $e')));
        }
      }
    } else {
      HapticFeedback.lightImpact();
      _payment.openCheckout(
        amountInPaise: (total * 100).toInt(),
        orderNote: 'Krave Order',
        email: userProvider.user?.email ?? '',
        contact: '', 
        razorpayKey: KraveConfig.razorpayKeyId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final userProvider = context.watch<UserProvider>();
    final theme = Theme.of(context);
    final total = cart.totalAmount + (_orderType == 'delivery' ? 15 : 2);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isProcessing
          ? KraveLoading(size: 80)
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 120,
                  floating: true,
                  pinned: true,
                  backgroundColor: AppColors.background.withOpacity(0.8),
                  title: Text('Your Cart', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: _OrderTypeToggle(
                      selectedType: _orderType,
                      onChanged: (type) {
                        HapticFeedback.selectionClick();
                        setState(() => _orderType = type);
                      },
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _CartItemTile(item: cart.items.values.toList()[index]),
                      childCount: cart.items.length,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _PaymentMethodSelector(
                          selectedMethod: _paymentMethod,
                          balance: userProvider.balance,
                          onChanged: (m) {
                            HapticFeedback.selectionClick();
                            setState(() => _paymentMethod = m);
                          },
                        ),
                        const SizedBox(height: 20),
                        _BillDetailsCard(cart: cart, orderType: _orderType),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: cart.items.isEmpty || _isProcessing
          ? null
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: _checkout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text('PAY ₹${total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                ),
              ),
            ),
    );
  }
}

class _PaymentMethodSelector extends StatelessWidget {
  final String selectedMethod;
  final double balance;
  final Function(String) onChanged;

  const _PaymentMethodSelector({required this.selectedMethod, required this.balance, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textHigh)),
        const SizedBox(height: 12),
        _MethodTile(
          label: 'Krave Wallet',
          type: 'wallet',
          selected: selectedMethod == 'wallet',
          icon: Icons.account_balance_wallet_rounded,
          subtitle: 'Available: ₹${balance.toStringAsFixed(2)}',
          onTap: () => onChanged('wallet'),
        ),
        const SizedBox(height: 8),
        _MethodTile(
          label: 'Online Payment',
          type: 'razorpay',
          selected: selectedMethod == 'razorpay',
          icon: Icons.payments_rounded,
          subtitle: 'UPI, Cards, Netbanking',
          onTap: () => onChanged('razorpay'),
        ),
      ],
    );
  }
}

class _MethodTile extends StatelessWidget {
  final String label;
  final String type;
  final bool selected;
  final IconData icon;
  final String subtitle;
  final VoidCallback onTap;

  const _MethodTile({required this.label, required this.type, required this.selected, required this.icon, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppColors.primary : AppColors.glassBorder, width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? AppColors.primary : AppColors.textMed),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textHigh)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textLow)),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _OrderTypeToggle extends StatelessWidget {
  final String selectedType;
  final Function(String) onChanged;
  const _OrderTypeToggle({required this.selectedType, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.glassBorder)),
      child: Row(
        children: [
          Expanded(child: _ToggleBtn(label: 'Dine-in', type: 'dineIn', selected: selectedType == 'dineIn', onTap: () => onChanged('dineIn'))),
          Expanded(child: _ToggleBtn(label: 'Delivery', type: 'delivery', selected: selectedType == 'delivery', onTap: () => onChanged('delivery'))),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final String type;
  final bool selected;
  final VoidCallback onTap;
  const _ToggleBtn({required this.label, required this.type, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: selected ? AppColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(color: selected ? Colors.black : AppColors.textLow, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.glassBorder)),
      child: Row(
        children: [
          Text('${item.quantity}x', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
          Expanded(child: Text(item.name, style: const TextStyle(color: AppColors.textHigh, fontWeight: FontWeight.w600))),
          Text('₹${item.price * item.quantity}', style: const TextStyle(color: AppColors.textHigh, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _BillDetailsCard extends StatelessWidget {
  final CartProvider cart;
  final String orderType;
  const _BillDetailsCard({required this.cart, required this.orderType});

  @override
  Widget build(BuildContext context) {
    const double platformFee = 2;
    final double deliveryFee = orderType == 'delivery' ? 15 : 0;
    final double total = cart.totalAmount + deliveryFee + platformFee;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.glassBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Bill Details', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textHigh)),
          const SizedBox(height: 20),
          _BillRow(label: 'Item Total', value: '₹${cart.totalAmount.toStringAsFixed(0)}'),
          _BillRow(label: 'Delivery Fee', value: '₹$deliveryFee', isGreen: orderType == 'dineIn'),
          const _BillRow(label: 'Platform Fee', value: '₹$platformFee'),
          const Divider(height: 40, thickness: 1, color: AppColors.glassBorder),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Pay', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textHigh)),
              Text('₹${total.toStringAsFixed(0)}', style: GoogleFonts.outfit(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isGreen;
  const _BillRow({required this.label, required this.value, this.isGreen = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textLow)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: isGreen ? AppColors.primary : AppColors.textHigh)),
        ],
      ),
    );
  }
}
