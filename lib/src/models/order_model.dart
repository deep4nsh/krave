import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String userId;
  final String canteenId;
  final List<Map<String, dynamic>> items;
  final int totalAmount;
  final String tokenNumber;
  final String status; // 'Pending', 'Preparing', 'Ready for Pickup', 'Out for Delivery', 'Completed', 'Cancelled'
  final DateTime timestamp;
  final String paymentId;
  final String orderType; // 'dineIn' or 'delivery'
  final String? riderId;

  // New Professional Fields
  final Map<String, dynamic> fees; // { delivery: 15, platform: 2 }
  final Map<String, dynamic> payment; // { status: 'paid', method: 'wallet', txId: '...' }
  final Map<String, DateTime> statusTimeline; // { 'Preparing': DateTime, ... }
  final Map<String, dynamic>? deliveryLocation; // { hostel: '...', room: '...', spec: '...' }
  
  // Denormalized Fields for UI Optimization
  final String canteenName;
  final String? canteenImage;
  final String userName;
  final String? cancellationReason;

  OrderModel({
    required this.id,
    required this.userId,
    required this.canteenId,
    required this.items,
    required this.totalAmount,
    required this.tokenNumber,
    required this.status,
    required this.timestamp,
    required this.paymentId,
    required this.orderType,
    this.riderId,
    this.fees = const {'delivery': 0, 'platform': 2},
    this.payment = const {'status': 'pending', 'method': 'external'},
    this.statusTimeline = const {},
    this.deliveryLocation,
    this.canteenName = 'Canteen',
    this.canteenImage,
    this.userName = 'User',
    this.cancellationReason,
  });

  factory OrderModel.fromMap(String id, Map<String, dynamic> m) {
    // Parse status timeline
    Map<String, DateTime> timeline = {};
    if (m['statusTimeline'] != null) {
      (m['statusTimeline'] as Map).forEach((k, v) {
        if (v is Timestamp) timeline[k.toString()] = v.toDate();
      });
    }

    return OrderModel(
      id: id,
      userId: m['userId'] ?? '',
      canteenId: m['canteenId'] ?? '',
      items: List<Map<String, dynamic>>.from(m['items'] ?? []),
      totalAmount: (m['totalAmount'] ?? 0).toInt(),
      tokenNumber: m['tokenNumber'] ?? '',
      status: m['status'] ?? 'Pending',
      timestamp: (m['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paymentId: m['paymentId'] ?? '',
      orderType: m['orderType'] ?? 'delivery',
      riderId: m['riderId'],
      fees: Map<String, dynamic>.from(m['fees'] ?? {}),
      payment: Map<String, dynamic>.from(m['payment'] ?? {}),
      statusTimeline: timeline,
      deliveryLocation: m['deliveryLocation'] != null ? Map<String, dynamic>.from(m['deliveryLocation']) : null,
      canteenName: m['canteenName'] ?? 'Canteen',
      canteenImage: m['canteenImage'],
      userName: m['userName'] ?? 'User',
      cancellationReason: m['cancellationReason'],
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'canteenId': canteenId,
    'items': items,
    'totalAmount': totalAmount,
    'tokenNumber': tokenNumber,
    'status': status,
    'timestamp': timestamp,
    'paymentId': paymentId,
    'orderType': orderType,
    'riderId': riderId,
    'fees': fees,
    'payment': payment,
    'statusTimeline': statusTimeline,
    'deliveryLocation': deliveryLocation,
    'canteenName': canteenName,
    'canteenImage': canteenImage,
    'userName': userName,
    'cancellationReason': cancellationReason,
  };

  /// UI Helpers
  String get itemsSummary => items.map((i) => '${i['quantity'] ?? 1}x ${i['name'] ?? '?'}').join(', ');
  bool get isDineIn => orderType == 'dineIn';
  bool get isDelivery => orderType == 'delivery';
  bool get isPaid => payment['status'] == 'paid';
}