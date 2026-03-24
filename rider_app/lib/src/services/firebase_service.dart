import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rider_model.dart';
import '../models/order_model.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── Auth ───────────────────────────────────────────────────────────────────

  Future<RiderModel?> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(), password: password.trim());
    final uid = cred.user!.uid;

    // Verify user is a rider
    final doc = await _db.collection('Riders').doc(uid).get();
    if (!doc.exists) {
      await _auth.signOut();
      throw Exception('No rider account found for this email.');
    }
    return RiderModel.fromMap(uid, doc.data()!);
  }

  Future<void> signOut() => _auth.signOut();

  // ─── Rider ──────────────────────────────────────────────────────────────────

  Future<RiderModel?> getRider(String uid) async {
    final doc = await _db.collection('Riders').doc(uid).get();
    if (!doc.exists) return null;
    return RiderModel.fromMap(uid, doc.data()!);
  }

  Future<void> updateActiveStatus(String uid, bool isActive) async {
    await _db.collection('Riders').doc(uid).update({'isActive': isActive});
  }

  Future<void> updateFCMToken(String uid, String token) async {
    await _db.collection('Riders').doc(uid).update({'fcmToken': token});
  }

  // ─── Orders ─────────────────────────────────────────────────────────────────

  /// Live feed of active orders (Pending + Preparing + Ready for Pickup)
  Stream<List<OrderModel>> streamActiveOrders() {
    return _db
        .collection('Orders')
        .where('status', whereIn: ['Pending', 'Preparing', 'Ready for Pickup'])
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => OrderModel.fromMap(d.id, d.data()))
            .toList());
  }

  /// All orders for history (most recent first)
  Stream<List<OrderModel>> streamAllOrders() {
    return _db
        .collection('Orders')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => OrderModel.fromMap(d.id, d.data()))
            .toList());
  }

  /// Fetch canteen name by ID
  Future<String> getCanteenName(String canteenId) async {
    try {
      final doc = await _db.collection('Canteens').doc(canteenId).get();
      return doc.data()?['name'] as String? ?? 'Canteen';
    } catch (_) {
      return 'Canteen';
    }
  }

  /// Update order status
  Future<void> updateOrderStatus(String orderId, String status, String riderId) async {
    await _db.collection('Orders').doc(orderId).update({
      'status': status,
      'riderId': riderId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
