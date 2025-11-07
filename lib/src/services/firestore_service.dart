import 'dart:math';
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

  Future<void> updateUserFCMToken(String uid, String token) async {
    final userDoc = _db.collection('Users').doc(uid);
    final ownerDoc = _db.collection('Owners').doc(uid);
    final adminDoc = _db.collection('Admins').doc(uid);

    final data = {'fcmToken': token};

    if ((await userDoc.get()).exists) {
      await userDoc.update(data);
    } else if ((await ownerDoc.get()).exists) {
      await ownerDoc.update(data);
    } else if ((await adminDoc.get()).exists) {
      await adminDoc.update(data);
    }
  }

  Future<void> addOwner(String uid, String name, String email, String canteenName) async {
    // Create the user document first, so the role can be determined on login
    await createUser(KraveUser(id: uid, name: name, email: email, role: 'pendingOwner'));

    // Then, create the owner application document
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

  // DEFINITIVE FIX: Complete approval logic
  Future<void> approveOwner(String ownerId) async {
    final ownerRef = _db.collection('Owners').doc(ownerId);
    final ownerSnapshot = await ownerRef.get();
    final ownerData = ownerSnapshot.data();

    if (ownerData == null) {
      throw Exception('Owner not found!');
    }

    // 1. Create the new canteen document
    final canteenRef = await _db.collection('Canteens').add({
      'name': ownerData['canteen_name'],
      'ownerId': ownerId,
      'approved': true,
      'opening_time': '9:00 AM', // Default opening time
      'closing_time': '5:00 PM', // Default closing time
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Update the owner's document with the new canteen ID and approved status
    await ownerRef.update({
      'status': 'approved',
      'canteen_id': canteenRef.id,
      'approvedAt': FieldValue.serverTimestamp(),
    });

    // 3. Update the user's role in the Users collection for proper redirection
    await _db.collection('Users').doc(ownerId).update({
      'role': 'approvedOwner'
    });
  }

  // DEFINITIVE FIX: Rejection now triggers the secure Cloud Function
  Future<void> rejectOwner(String ownerId) async {
    // Deleting the owner document will trigger the onOwnerDelete cloud function
    // which will securely delete the user from Firebase Auth.
    await _db.collection('Owners').doc(ownerId).delete();
    // Also delete the associated user document
    await _db.collection('Users').doc(ownerId).delete();
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

  String _generateNextToken(String userName) {
    final now = DateTime.now();
    final random = Random();

    final namePrefix = userName.length >= 4 
        ? userName.substring(0, 4).toLowerCase()
        : userName.padRight(4, 'x').toLowerCase();

    final randomPart = random.nextInt(100).toString().padLeft(2, '0');
    final hourPart = now.hour.toString().padLeft(2, '0');
    final minutePart = now.minute.toString().padLeft(2, '0');
    final secondPart = now.second.toString().padLeft(2, '0');

    return '$namePrefix-$randomPart$hourPart$minutePart$secondPart';
  }

  Future<String> createOrder({
    required String userId,
    required String canteenId,
    required List<Map<String, dynamic>> items,
    required int totalAmount,
    required String paymentId,
  }) async {
    final user = await getUser(userId);
    final userName = user?.name ?? 'user';

    final tokenNumber = _generateNextToken(userName);
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

  Stream<OrderModel> streamOrder(String orderId) {
    return _db.collection('Orders').doc(orderId).snapshots().map((d) => OrderModel.fromMap(d.id, d.data()!));
  }

  Future<OrderModel?> getOrder(String orderId) async {
    final doc = await _db.collection('Orders').doc(orderId).get();
    if (!doc.exists) return null;
    return OrderModel.fromMap(doc.id, doc.data()!);
  }

  Stream<List<OrderModel>> streamOrdersForCanteen(String canteenId) {
    return _db.collection('Orders').where('canteenId', isEqualTo: canteenId).orderBy('timestamp', descending: true).snapshots().map((s) => s.docs.map((d) => OrderModel.fromMap(d.id, d.data())).toList());
  }

  Stream<List<OrderModel>> streamOrdersForUser(String userId) {
    return _db.collection('Orders').where('userId', isEqualTo: userId).orderBy('timestamp', descending: true).snapshots().map((s) => s.docs.map((d) => OrderModel.fromMap(d.id, d.data())).toList());
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _db.collection('Orders').doc(orderId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
