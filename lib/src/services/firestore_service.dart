import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/canteen_model.dart';
import '../models/menu_item_model.dart';
import '../models/order_model.dart';
import 'package:uuid/uuid.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  Future<void> createUser(KraveUser user) async {
    await _db.collection('Users').doc(user.id).set(user.toMap());
  }

  Future<KraveUser?> getUser(String uid) async {
    final doc = await _db.collection('Users').doc(uid).get();
    if (!doc.exists) return null;
    return KraveUser.fromMap(doc.id, doc.data()!);
  }

  Future<String> getUserRole(String uid) async {
    final adminDoc = await _db.collection('Admins').doc(uid).get();
    if (adminDoc.exists) return 'admin';

    final ownerDoc = await _db.collection('Owners').doc(uid).get();
    if (ownerDoc.exists) {
      final status = ownerDoc.data()?['status'] ?? 'pending';
      return status == 'approved' ? 'approvedOwner' : 'pendingOwner';
    }

    final userDoc = await _db.collection('Users').doc(uid).get();
    if (userDoc.exists) return 'user';

    return 'none';
  }

  Future<void> addOwner(String uid, String name, String email, String canteenName) async {
    await _db.collection('Owners').doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'canteen_name': canteenName,
      'status': 'pending',
      'canteen_id': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>?> getOwnerDoc(String uid) async {
    final doc = await _db.collection('Owners').doc(uid).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  Stream<QuerySnapshot> streamPendingOwners() {
    return _db.collection('Owners').where('status', isEqualTo: 'pending').snapshots();
  }

  Future<void> approveOwner(String uid) async {
    await _db.collection('Owners').doc(uid).update({
      'status': 'approved',
      'approvedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectOwner(String uid) async {
    await _db.collection('Owners').doc(uid).update({
      'status': 'rejected',
      'rejectedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> isAdmin(String uid) async {
    final doc = await _db.collection('Admins').doc(uid).get();
    return doc.exists;
  }

  @Deprecated('Use isAdmin(uid) or Firebase Auth custom claims.')
  Future<bool> verifyAdminCredentials(String email, String? password) async {
    final snapshot = await _db.collection('Admins').where('email', isEqualTo: email).limit(1).get();
    return snapshot.docs.isNotEmpty;
  }

  Stream<List<Canteen>> streamApprovedCanteens() {
    return _db.collection('Canteens').where('approved', isEqualTo: true).snapshots().map((snap) => snap.docs.map((d) => Canteen.fromMap(d.id, d.data())).toList());
  }

  Future<void> updateCanteenTimings(String canteenId, String openTime, String closeTime) async {
    await _db.collection('Canteens').doc(canteenId).update({
      'opening_time': openTime,
      'closing_time': closeTime,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<MenuItemModel>> streamMenuItems(String canteenId) {
    return _db.collection('Canteens').doc(canteenId).collection('MenuItems').snapshots().map((snapshot) {
      final items = snapshot.docs.map((doc) {
        try {
          return MenuItemModel.fromMap(doc.id, doc.data());
        } catch (e, stackTrace) {
          debugPrint("!!!!!! FAILED TO PARSE MENU ITEM !!!!!! Document ID: ${doc.id}, Data: ${doc.data()}, Error: $e, StackTrace: $stackTrace");
          return null;
        }
      }).whereType<MenuItemModel>().toList();
      return items;
    });
  }

  Future<void> addMenuItem(String canteenId, Map<String, dynamic> itemData) async {
    await _db.collection('Canteens').doc(canteenId).collection('MenuItems').add({
      ...itemData,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateMenuItem(String canteenId, String itemId, Map<String, dynamic> data) async {
    await _db.collection('Canteens').doc(canteenId).collection('MenuItems').doc(itemId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteMenuItem(String canteenId, String itemId) async {
    await _db.collection('Canteens').doc(canteenId).collection('MenuItems').doc(itemId).delete();
  }

  Stream<QuerySnapshot> streamInventory(String canteenId) {
    return _db.collection('Canteens').doc(canteenId).collection('Inventory').snapshots();
  }

  Future<void> addInventoryItem(String canteenId, Map<String, dynamic> itemData) async {
    await _db.collection('Canteens').doc(canteenId).collection('Inventory').add({
      ...itemData,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateInventoryItem(String canteenId, String itemId, Map<String, dynamic> data) async {
    await _db.collection('Canteens').doc(canteenId).collection('Inventory').doc(itemId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteInventoryItem(String canteenId, String itemId) async {
    await _db.collection('Canteens').doc(canteenId).collection('Inventory').doc(itemId).delete();
  }

  Future<String> createOrder({
    required String userId,
    required String canteenId,
    required List<Map<String, dynamic>> items,
    required int totalAmount,
    required String paymentId,
  }) async {
    final tokenNumber = await _generateTokenForCanteen(canteenId);
    final id = _uuid.v4();
    final data = {
      'userId': userId,
      'canteenId': canteenId,
      'items': items,
      'totalAmount': totalAmount,
      'tokenNumber': tokenNumber,
      'status': 'Pending',
      'paymentId': paymentId,
      'timestamp': FieldValue.serverTimestamp(),
    };
    await _db.collection('Orders').doc(id).set(data);
    return id;
  }

  Future<String> _generateTokenForCanteen(String canteenId) async {
    final todayStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final snapshots = await _db.collection('Orders').where('canteenId', isEqualTo: canteenId).where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart)).get();
    final token = snapshots.docs.length + 1;
    return token.toString();
  }

  Stream<OrderModel> streamOrder(String orderId) {
    return _db.collection('Orders').doc(orderId).snapshots().map((d) => OrderModel.fromMap(d.id, d.data()!));
  }

  // ADDED: New method to get a single order
  Future<OrderModel?> getOrder(String orderId) async {
    final doc = await _db.collection('Orders').doc(orderId).get();
    if (!doc.exists) return null;
    return OrderModel.fromMap(doc.id, doc.data()!);
  }

  Stream<List<OrderModel>> streamOrdersForCanteen(String canteenId) {
    return _db.collection('Orders').where('canteenId', isEqualTo: canteenId).orderBy('timestamp', descending: true).snapshots().map((s) => s.docs.map((d) => OrderModel.fromMap(d.id, d.data())).toList());
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _db.collection('Orders').doc(orderId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
