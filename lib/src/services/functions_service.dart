import 'package:cloud_functions/cloud_functions.dart';

class FunctionsService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // Calls a Cloud Function to create a Razorpay order and returns the server-generated order_id
  Future<String> createRazorpayOrder({required int amountInPaise, required String receipt, required Map<String, String> notes}) async {
    final callable = _functions.httpsCallable('createRazorpayOrder');
    final response = await callable.call({
      'amount': amountInPaise,
      'receipt': receipt,
      'notes': notes,
    });
    return response.data['orderId'] as String;
  }

  // Calls a Cloud Function to confirm payment and create the Firestore order document
  Future<String> confirmRazorpayPayment({
    required String orderId,
    required String paymentId,
    required String signature,
    required String userId,
    required String canteenId,
    required List<Map<String, dynamic>> items,
    required int totalAmount,
  }) async {
    final callable = _functions.httpsCallable('confirmRazorpayPayment');
    final response = await callable.call({
      'razorpay_order_id': orderId,
      'razorpay_payment_id': paymentId,
      'razorpay_signature': signature,
      'userId': userId,
      'canteenId': canteenId,
      'items': items,
      'totalAmount': totalAmount,
    });
    return response.data['firestoreOrderId'] as String;
  }
}
