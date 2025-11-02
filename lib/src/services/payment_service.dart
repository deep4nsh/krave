import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentService {
  late Razorpay _razorpay;

  void init({
    required void Function(PaymentSuccessResponse) onSuccess,
    required void Function(PaymentFailureResponse) onError,
    required void Function(ExternalWalletResponse) onExternal,
  }) {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (r) => onSuccess(r!));
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (r) => onError(r!));
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (r) => onExternal(r!));
  }

  void dispose() {
    _razorpay.clear();
  }

  void openCheckout({
    required int amountInPaise,
    required String orderNote,
    required String email,
    required String contact,
    required String razorpayKey,
  }) {
    final options = {
      'key': razorpayKey,
      'amount': amountInPaise,
      'name': 'Krave App',
      'description': orderNote,
      'prefill': {
        'contact': contact,
        'email': email,
      },
    };
    _razorpay.open(options);
  }
}
