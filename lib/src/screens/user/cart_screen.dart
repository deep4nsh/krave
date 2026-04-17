import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../models/canteen_model.dart';
import '../../services/payment_service.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/cart_provider.dart';
import '../../config.dart';
import '../../theme/app_colors.dart';
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
  String _orderType = 'dineIn'; // Default to Dine-in

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
    final cart = context.read<CartProvider>();
    final auth = context.read<AuthService>();
    final fs = context.read<FirestoreService>();
    final navigator = Navigator.of(context);

    try {
      final orderId = await fs.createOrder(
        userId: auth.currentUser!.uid,
        canteenId: widget.canteen.id,
        items: cart.items.values.map((item) => item.toMap()).toList(),
        totalAmount: (cart.totalAmount + (_orderType == 'delivery' ? 15 : 2)).toInt(),
        paymentId: response.paymentId ?? 'razorpay_noid',
        orderType: _orderType,
      );

      setState(() => _isProcessing = false);
      cart.clearCart();

      if (mounted) {
        navigator.popUntil((route) => route.isFirst);
        navigator.pushReplacement(MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: orderId)));
      }
      
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save order: $e')));
      }
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment Failed. Please try again.')));
  }

  void _onExternalWallet(ExternalWalletResponse response) {}

  void _checkout() {
    final cart = context.read<CartProvider>();
    final auth = context.read<AuthService>();

    setState(() => _isProcessing = true);

    final total = cart.totalAmount + (_orderType == 'delivery' ? 15 : 2);

    _payment.openCheckout(
      amountInPaise: (total * 100).toInt(),
      orderNote: 'Krave Order (${_orderType.toUpperCase()})',
      email: auth.currentUser?.email ?? '',
      contact: '', 
      razorpayKey: KraveConfig.razorpayKeyId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isProcessing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  const SizedBox(height: 32),
                  Text(
                    'Securing your meal...',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            )
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 120,
                  floating: true,
                  pinned: true,
                  backgroundColor: AppColors.background.withOpacity(0.8),
                  elevation: 0,
                  title: Text(
                    'Your Cart',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textHigh),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: _OrderTypeToggle(
                      selectedType: _orderType,
                      onChanged: (type) => setState(() => _orderType = type),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = cart.items.values.toList()[index];
                        return _CartItemTile(item: item);
                      },
                      childCount: cart.items.length,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _BillDetailsCard(cart: cart, orderType: _orderType),
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
                height: 60,
                child: ElevatedButton(
                  onPressed: _checkout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 8,
                    shadowColor: AppColors.primary.withOpacity(0.3),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_outline_rounded, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'PAY ₹${(cart.totalAmount + (_orderType == 'delivery' ? 15 : 2)).toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
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
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder),
      ),
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
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : AppColors.textLow,
            fontWeight: FontWeight.bold,
          ),
        ),
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${item.quantity}x',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              item.name,
              style: const TextStyle(color: AppColors.textHigh, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '₹${item.price * item.quantity}',
            style: const TextStyle(color: AppColors.textHigh, fontWeight: FontWeight.bold),
          ),
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
    final double deliveryFee = orderType == 'delivery' ? 15 : 0;
    final double platformFee = 2;
    final double total = cart.totalAmount + deliveryFee + platformFee;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Bill Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textHigh),
          ),
          const SizedBox(height: 20),
          _BillRow(label: 'Item Total', value: '₹${cart.totalAmount.toStringAsFixed(0)}'),
          const SizedBox(height: 12),
          _BillRow(label: 'Delivery Fee', value: orderType == 'delivery' ? '₹15' : '₹0', isGreen: orderType == 'dineIn'),
          const SizedBox(height: 12),
          _BillRow(label: 'Platform Fee', value: '₹2'),
          const Divider(height: 40, thickness: 1, color: AppColors.glassBorder),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Pay', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textHigh)),
              Text(
                '₹${total.toStringAsFixed(0)}',
                style: const TextStyle(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.bold),
              ),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textLow)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isGreen ? AppColors.primary : AppColors.textHigh,
          ),
        ),
      ],
    );
  }
}
