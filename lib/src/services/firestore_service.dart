// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/canteen_model.dart';
import '../models/menu_item_model.dart';
import '../models/order_model.dart';
import 'package:uuid/uuid.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // USERS
  Future<void> createUser(KraveUser user) async {
    await _db.collection('Users').doc(user.id).set(user.toMap());
  }

  Future<KraveUser?> getUser(String uid) async {
    final doc = await _db.collection('Users').doc(uid).get();
    if (!doc.exists) return null;
    return KraveUser.fromMap(doc.id, doc.data()!);
  }

  // CANTEENS
  Stream<List<Canteen>> streamApprovedCanteens() {
    return _db.collection('Canteens').where('approved', isEqualTo: true).snapshots().map((snap) =>
        snap.docs.map((d) => Canteen.fromMap(d.id, d.data())).toList());
  }

  // MENU
  Stream<List<MenuItemModel>> streamMenuItems(String canteenId) {
    return _db
        .collection('Canteens')
        .doc(canteenId)
        .collection('MenuItems')
        .where('available', isEqualTo: true)
        .snapshots()
        .map((s) => s.docs.map((d) => MenuItemModel.fromMap(d.id, d.data())).toList());
  }

  // ORDERS
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
    // simple token: count today's orders for the canteen +1
    final todayStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final snapshots = await _db
        .collection('Orders')
        .where('canteenId', isEqualTo: canteenId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .get();
    final token = snapshots.docs.length + 1;
    return token.toString();
  }

  Stream<OrderModel> streamOrder(String orderId) {
    return _db.collection('Orders').doc(orderId).snapshots().map((d) => OrderModel.fromMap(d.id, d.data()!));
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _db.collection('Orders').doc(orderId).update({'status': status});
  }

  // For owner orders
  Stream<List<OrderModel>> streamOrdersForCanteen(String canteenId) {
    return _db
        .collection('Orders')
        .where('canteenId', isEqualTo: canteenId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => OrderModel.fromMap(d.id, d.data())).toList());
  }
  Future<void> addOwner(String uid, String name, String email) async {
    await _db.collection('Owners').doc(uid).set({
      'name': name,
      'email': email,
      'approved': false,
    });
  }

  // Check if owner is approved
  Future<bool> isOwnerApproved(String uid) async {
    final doc = await _db.collection('Owners').doc(uid).get();
    if (!doc.exists) return false;
    return doc.data()?['approved'] == true;
  }

  // Stream all pending owners (for admin panel)
  Stream<QuerySnapshot> streamPendingOwners() {
    return _db.collection('Owners').where('approved', isEqualTo: false).snapshots();
  }

  // Approve owner
  Future<void> approveOwner(String uid) async {
    await _db.collection('Owners').doc(uid).update({'approved': true});
  }

  // Reject owner
  Future<void> rejectOwner(String uid) async {
    await _db.collection('Owners').doc(uid).delete();
  }
  // Check if admin credentials are valid
  Future<bool> verifyAdminCredentials(String email, String password) async {
    final snapshot = await _db
        .collection('Admins')
        .where('email', isEqualTo: email)
        .where('password', isEqualTo: password)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }
  Future<Map<String, dynamic>?> getOwnerDoc(String uid) async {
    final doc = await _db.collection('Owners').doc(uid).get();
    if (!doc.exists) return null;
    return doc.data();
  }

}
