// lib/screens/user/cart_screen.dart
import 'package:flutter/material.dart';
import '../../models/canteen_model.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../services/payment_service.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/pdf_service.dart';

class CartScreen extends StatefulWidget {
  final Canteen canteen;
  final List<Map<String, dynamic>> cartItems;
  const CartScreen({super.key, required this.canteen, required this.cartItems});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool processing = false;
  final PaymentService _payment = PaymentService();

  @override
  void dispose() {
    _payment.dispose();
    super.dispose();
  }

  int get total => widget.cartItems.fold(0, (s, e) => s + ((e['price'] as int) * (e['qty'] as int)));

  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    // save order in Firestore
    final auth = Provider.of<AuthService>(context, listen: false);
    final fs = Provider.of<FirestoreService>(context, listen: false);
    final uid = auth.currentUser!.uid;
    final orderId = await fs.createOrder(
      userId: uid,
      canteenId: widget.canteen.id,
      items: widget.cartItems,
      totalAmount: total,
      paymentId: response.paymentId ?? 'razorpay_noid',
    );
    // optionally generate PDF and share
    final pdfSrv = PdfService();
    final bytes = await pdfSrv.generateBillPdf(
      orderId: orderId,
      canteenName: widget.canteen.name,
      token: 'TBD',
      items: widget.cartItems,
      total: total,
    );
    await pdfSrv.sharePdf(bytes, 'krave_bill_$orderId.pdf');

    if (!mounted) return;
    setState(() { processing = false; });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order placed')));
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void _onPaymentError(PaymentFailureResponse r) {
    if (!mounted) return;
    setState(() { processing = false; });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment failed')));
  }

  void _onExternal(ExternalWalletResponse r) {
    // handle external
  }

  void checkout() {
    setState(() { processing = true; });
    _payment.init(onSuccess: (p) => _onPaymentSuccess(p), onError: (e) => _onPaymentError(e), onExternal: (ex) => _onExternal(ex));
    final auth = Provider.of<AuthService>(context, listen: false);
    final email = auth.currentUser!.email ?? '';
    // your razorpay test key here
    const razorKey = 'rzp_test_xxxxxxxxxxxxxx';
    _payment.openCheckout(amountInPaise: total * 100, orderNote: 'Krave Order', email: email, contact: '', razorpayKey: razorKey);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: processing ? const Center(child: CircularProgressIndicator()) : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: widget.cartItems.length,
              itemBuilder: (c, i) {
                final it = widget.cartItems[i];
                return ListTile(title: Text(it['name']), subtitle: Text('Qty: ${it['qty']}'), trailing: Text('₹${it['price'] * it['qty']}'));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(children: [
Text('Total: ₹$total', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: checkout, child: const Text('Pay & Place Order')),
            ]),
          )
        ],
      ),
    );
  }
}