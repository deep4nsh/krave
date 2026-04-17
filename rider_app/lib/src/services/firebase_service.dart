import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:krave/src/models/rider_model.dart';
import 'package:krave/src/models/order_model.dart';
import 'package:krave/src/constants/app_constants.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── Auth ───────────────────────────────────────────────────────────────────

  Future<void> sendOTP({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) codeSent,
    required Function(FirebaseAuthException e) verificationFailed,
    required Function(PhoneAuthCredential credential) verificationCompleted,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<RiderModel> verifyOTP(String verificationId, String smsCode) async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await _signInWithCredential(credential);
  }

  Future<RiderModel> _signInWithCredential(AuthCredential credential) async {
    try {
      final cred = await _auth.signInWithCredential(credential);
      final uid = cred.user!.uid;
      final phone = cred.user!.phoneNumber ?? '';

      final doc = await _db.collection(FirestoreCollections.riders).doc(uid).get();
      if (doc.exists) {
        return RiderModel.fromMap(uid, doc.data()!);
      } else {
        final newRider = RiderModel(
          id: uid,
          name: '',
          email: '',
          phone: phone,
          createdAt: DateTime.now(),
          status: RiderStatus.onboarding,
          onboardingStep: 1,
        );
        await _db.collection(FirestoreCollections.riders).doc(uid).set(newRider.toMap());
        return newRider;
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() => _auth.signOut();

  // ─── Rider Core ────────────────────────────────────────────────────────────

  Future<RiderModel?> getRider(String uid) async {
    try {
      final doc = await _db.collection(FirestoreCollections.riders).doc(uid).get();
      if (!doc.exists) return null;
      return RiderModel.fromMap(uid, doc.data()!);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateRiderLocation(String uid, double lat, double lng) async {
    try {
      await _db.collection(FirestoreCollections.riders).doc(uid).update({
        'currentLocation': {
          'latitude': lat,
          'longitude': lng,
          'updatedAt': FieldValue.serverTimestamp(),
        }
      });
    } catch (e) {
      // Background task, log and fail silently
    }
  }

  Future<void> updateBasicProfile(String uid, String name, String city, String vehicleType, String email) async {
    try {
      await _db.collection(FirestoreCollections.riders).doc(uid).update({
        'name': name,
        'city': city,
        'vehicleType': vehicleType,
        'email': email,
        'onboardingStep': 2,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateOnboardingStep(String uid, int step) async {
    try {
      await _db.collection(FirestoreCollections.riders).doc(uid).update({
        'onboardingStep': step,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateActiveStatus(String uid, bool isActive) async {
    try {
      await _db.collection(FirestoreCollections.riders).doc(uid).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // ─── KYC & Documents ──────────────────────────────────────────────────────

  Future<String> uploadKycDocument(String uid, String docType, File file, Function(double) onProgress) async {
    final ref = _storage.ref().child('kyc_documents/$uid/$docType.jpg');
    final uploadTask = ref.putFile(file);

    uploadTask.snapshotEvents.listen((event) {
      double progress = event.bytesTransferred / event.totalBytes;
      onProgress(progress);
    });

    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();

    await _db.collection(FirestoreCollections.riders).doc(uid).set({
      'kycDetails': {
        docType: {
          'url': downloadUrl,
          'status': 'Uploaded',
          'uploadedAt': FieldValue.serverTimestamp(),
        }
      }
    }, SetOptions(merge: true));

    return downloadUrl;
  }

  // ─── Orders ─────────────────────────────────────────────────────────────────

  Stream<List<OrderModel>> streamActiveOrders() {
    return _db
        .collection(FirestoreCollections.orders)
        .where('orderType', isEqualTo: 'delivery')
        .where('status', whereIn: OrderStatus.active) // Uses synced 'active' list
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => OrderModel.fromMap(d.id, d.data()))
            .toList());
  }

  Stream<List<OrderModel>> streamAllOrders() {
    return _db
        .collection(FirestoreCollections.orders)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => OrderModel.fromMap(d.id, d.data()))
            .toList());
  }

  Future<void> updateOrderStatus(String orderId, String status, String riderId) async {
    try {
      await _db.collection(FirestoreCollections.orders).doc(orderId).update({
        'status': status,
        'riderId': riderId,
        'updatedAt': FieldValue.serverTimestamp(),
        'statusTimeline.$status': FieldValue.serverTimestamp(), // Update professional timeline
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<String> getCanteenName(String canteenId) async {
    try {
      final doc = await _db.collection(FirestoreCollections.canteens).doc(canteenId).get();
      return doc.data()?['name'] as String? ?? 'Canteen';
    } catch (_) {
      return 'Canteen';
    }
  }
}
