// lib/services/payment_service.dart
import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentService {
  final Razorpay _rzp = Razorpay();

  void init({required Function(PaymentSuccessResponse) onSuccess, required Function(PaymentFailureResponse) onError, required Function(ExternalWalletResponse) onExternal}) {
    _rzp.on(Razorpay.EVENT_PAYMENT_SUCCESS, onSuccess);
    _rzp.on(Razorpay.EVENT_PAYMENT_ERROR, onError);
    _rzp.on(Razorpay.EVENT_EXTERNAL_WALLET, onExternal);
  }

  void dispose() {
    _rzp.clear();
  }

  void openCheckout({required int amountInPaise, required String orderNote, required String email, required String contact, required String razorpayKey}) {
    var options = {
      'key': razorpayKey,
      'amount': amountInPaise, // paise
      'name': 'Krave',
      'description': orderNote,
      'prefill': {'contact': contact, 'email': email},
    };
    _rzp.open(options);
  }
}