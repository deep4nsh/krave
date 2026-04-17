// lib/src/models/order_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String userId;
  final String canteenId;
  final List<Map<String, dynamic>> items;
  final int totalAmount;
  final String tokenNumber;
  final String status;
  final DateTime timestamp;
  final String paymentId;
  final String? riderId;

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
    this.riderId,
  });

  factory OrderModel.fromMap(String id, Map<String, dynamic> m) {
    return OrderModel(
      id: id,
      userId: m['userId'] ?? m['user_uid'] ?? '',
      canteenId: m['canteenId'] ?? m['canteen_id'] ?? '',
      items: List<Map<String, dynamic>>.from(m['items'] ?? []),
      totalAmount: (m['totalAmount'] ?? 0).toInt(),
      tokenNumber: m['tokenNumber'] ?? '',
      status: m['status'] ?? 'Pending',
      timestamp: (m['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paymentId: m['paymentId'] ?? '',
      riderId: m['riderId'],
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
    'riderId': riderId,
  };

  /// Human-readable items summary e.g. "2x Chole Bhature, 1x Burger"
  String get itemsSummary {
    return items.map((i) {
      final qty = i['quantity'] ?? 1;
      final name = i['name'] ?? '?';
      return '${qty}x $name';
    }).join(', ');
  }

  /// Total item count
  int get itemCount => items.fold(0, (s, i) => s + ((i['quantity'] as int?) ?? 1));

  /// Status helper getters
  bool get isPending => status == 'Pending';
  bool get isPreparing => status == 'Preparing';
  bool get isPickupReady => status == 'Ready for Pickup';
  bool get isDone => status == 'Completed' || status == 'Cancelled';
}