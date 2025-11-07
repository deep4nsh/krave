import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../models/canteen_model.dart';
import '../../services/payment_service.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/cart_provider.dart';
import '../../config.dart';
import '../../widgets/gradient_background.dart';
import 'order_history.dart';

class CartScreen extends StatefulWidget {
  final Canteen canteen;
  const CartScreen({super.key, required this.canteen});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final PaymentService _payment = PaymentService();
  bool _isProcessing = false;

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
      await fs.createOrder(
        userId: auth.currentUser!.uid,
        canteenId: widget.canteen.id,
        items: cart.items.values.map((item) => item.toMap()).toList(),
        totalAmount: cart.totalAmount.toInt(),
        paymentId: response.paymentId ?? 'razorpay_noid',
      );

      setState(() => _isProcessing = false);
      cart.clearCart();

      navigator.popUntil((route) => route.isFirst);
      navigator.pushReplacement(MaterialPageRoute(builder: (_) => const OrderHistoryScreen()));
      
    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save order: $e')));
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

    _payment.openCheckout(
      amountInPaise: (cart.totalAmount * 100).toInt(),
      orderNote: 'Krave Canteen Order',
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Your Cart')),
      body: GradientBackground(
        child: _isProcessing
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text('Processing Payment...', style: TextStyle(fontSize: 16)),
                  ],
                ),
              )
            : CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
                    sliver: SliverList(delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = cart.items.values.toList()[index];
                        return _CartItemTile(item: item);
                      },
                      childCount: cart.items.length,
                    )),
                  ),
                  SliverToBoxAdapter(child: _BillDetailsCard(cart: cart)),
                ],
              ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: cart.items.isEmpty || _isProcessing
          ? null
          : FloatingActionButton.extended(
              onPressed: _checkout,
              label: const Text('PAY & PLACE ORDER'),
              icon: const Icon(Icons.payment),
            ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Text('${item.quantity}x', style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(item.name, style: theme.textTheme.bodyLarge),
            ),
            const SizedBox(width: 16),
            Text('₹${item.price * item.quantity}', style: theme.textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

class _BillDetailsCard extends StatelessWidget {
  final CartProvider cart;
  const _BillDetailsCard({required this.cart});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Bill Details', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Item Total', style: theme.textTheme.bodyLarge),
                Text('₹${cart.totalAmount.toStringAsFixed(2)}', style: theme.textTheme.bodyLarge),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Taxes & Charges', style: theme.textTheme.bodyLarge),
                Text('₹0.00', style: theme.textTheme.bodyLarge),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Grand Total', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                Text('₹${cart.totalAmount.toStringAsFixed(2)}', style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
