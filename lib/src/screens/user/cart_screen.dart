import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../models/canteen_model.dart';
import '../../services/payment_service.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/cart_provider.dart';
import '../../config.dart';
import 'order_history.dart'; // Import the new history screen

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

      // FIX: Navigate to Order History Screen after payment
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

  void _onExternalWallet(ExternalWalletResponse response) {
    // Handle external wallet responses if necessary
  }

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

    return Scaffold(
      appBar: AppBar(title: const Text('Your Cart')),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing Payment...'),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (context, i) {
                      final item = cart.items.values.toList()[i];
                      return ListTile(
                        title: Text(item.name),
                        subtitle: Text('₹${item.price}'),
                        leading: CircleAvatar(child: Text(item.quantity.toString())),
                        trailing: Text('₹${item.price * item.quantity}'),
                      );
                    },
                  ),
                ),
                _buildTotalSection(cart),
              ],
            ),
    );
  }

  Widget _buildTotalSection(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: const [BoxShadow(blurRadius: 5, color: Colors.black12, offset: Offset(0, -2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Total: ₹${cart.totalAmount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: cart.items.isEmpty ? null : _checkout,
            child: const Text('Pay and Place Order'),
          ),
        ],
      ),
    );
  }
}
