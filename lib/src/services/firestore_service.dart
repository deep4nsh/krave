import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/canteen_model.dart';
import '../models/menu_item_model.dart';
import '../models/order_model.dart';
import '../models/rider_model.dart';
import '../models/transaction_model.dart';
import 'package:uuid/uuid.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // ─── User Management ───────────────────────────────────────────────────────

  Future<void> createUser(KraveUser user) async {
    await _db.collection('Users').doc(user.id).set(user.toMap());
  }

  Future<KraveUser?> getUser(String uid) async {
    final doc = await _db.collection('Users').doc(uid).get();
    if (!doc.exists) return null;
    return KraveUser.fromMap(doc.id, doc.data()!);
  }

  Future<String> getUserRole(String uid) async {
    try {
      final adminDoc = await _db.collection('Admins').doc(uid).get();
      if (adminDoc.exists) return 'admin';
    } catch (_) {}

    try {
      final ownerDoc = await _db.collection('Owners').doc(uid).get();
      if (ownerDoc.exists) {
        final status = ownerDoc.data()?['status'] ?? 'pending';
        return status == 'approved' ? 'approvedOwner' : 'pendingOwner';
      }
    } catch (_) {}

    final userDoc = await _db.collection('Users').doc(uid).get();
    if (userDoc.exists) return 'user';

    return 'none';
  }

  // ─── Wallet System ────────────────────────────────────────────────────────

  Future<void> processWalletPayment(String userId, double amount, String orderId) async {
    final userRef = _db.collection('Users').doc(userId);
    final txRef = _db.collection('Transactions').doc();

    await _db.runTransaction((tx) async {
      final userSnap = await tx.get(userRef);
      if (!userSnap.exists) throw Exception('User not found');
      
      final currentBalance = (userSnap.data()?['walletBalance'] ?? 0.0).toDouble();
      if (currentBalance < amount) throw Exception('Insufficient wallet balance');

      // 1. Deduct from wallet
      tx.update(userRef, {
        'walletBalance': currentBalance - amount,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Log transaction
      final walletTx = WalletTransaction(
        id: txRef.id,
        userId: userId,
        amount: amount,
        type: TransactionType.debit,
        status: TransactionStatus.success,
        timestamp: DateTime.now(),
        title: 'Order Payment',
        refId: orderId,
      );
      tx.set(txRef, {
        ...walletTx.toMap(),
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }

  // ─── Canteen Management ────────────────────────────────────────────────────

  Stream<List<Canteen>> streamApprovedCanteens() {
    return _db.collection('Canteens')
        .where('approved', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Canteen.fromMap(d.id, d.data())).toList());
  }

  Future<void> updateCanteenStatus(String canteenId, VenueStatus status) async {
    await _db.collection('Canteens').doc(canteenId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── Orders ─────────────────────────────────────────────────────────────────

  Future<String> createOrder({
    required KraveUser user,
    required Canteen canteen,
    required List<Map<String, dynamic>> items,
    required int totalAmount,
    required String paymentId,
    required String orderType,
    Map<String, dynamic>? deliveryLocation,
    Map<String, dynamic>? fees,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    
    final order = OrderModel(
      id: id,
      userId: user.id,
      canteenId: canteen.id,
      items: items,
      totalAmount: totalAmount,
      tokenNumber: _generateNextToken(user.name),
      status: 'Pending',
      timestamp: now,
      paymentId: paymentId,
      orderType: orderType,
      deliveryLocation: deliveryLocation,
      fees: fees ?? {'delivery': (orderType == 'delivery' ? 15 : 0), 'platform': 2},
      payment: {'status': 'paid', 'method': paymentId == 'wallet' ? 'wallet' : 'external', 'txId': paymentId},
      statusTimeline: {'Pending': now},
      canteenName: canteen.name,
      canteenImage: canteen.image,
      userName: user.name,
    );

    await _db.collection('Orders').doc(id).set({
      ...order.toMap(),
      'timestamp': FieldValue.serverTimestamp(),
      'statusTimeline': {'Pending': FieldValue.serverTimestamp()},
    });
    
    return id;
  }

  Future<void> updateOrderStatus(String orderId, String status, {String? reason}) async {
    final orderRef = _db.collection('Orders').doc(orderId);
    
    await _db.runTransaction((tx) async {
      final snap = await tx.get(orderRef);
      if (!snap.exists) return;

      Map<String, dynamic> updateData = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
        'statusTimeline.$status': FieldValue.serverTimestamp(),
      };

      if (reason != null) updateData['cancellationReason'] = reason;
      
      tx.update(orderRef, updateData);
    });
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  String _generateNextToken(String userName) {
    final now = DateTime.now();
    final random = Random();
    final namePrefix = userName.length >= 4 
        ? userName.substring(0, 4).toLowerCase()
        : userName.padRight(4, 'x').toLowerCase();
    
    final randomPart = random.nextInt(100).toString().padLeft(2, '0');
    final timePart = "${now.hour}${now.minute}${now.second}";
    return '$namePrefix-$randomPart$timePart';
  }

  Stream<List<OrderModel>> streamOrdersForUser(String userId) {
    return _db.collection('Orders')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => OrderModel.fromMap(d.id, d.data())).toList());
  }
}
