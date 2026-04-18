import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

enum SessionStatus {
  initial,
  unauthenticated,
  authenticating,
  fetchingProfile,
  authenticated,
  pendingOwner,
  admin,
  error
}

class UserProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirestoreService _fs = FirestoreService();
  
  KraveUser? _user;
  SessionStatus _status = SessionStatus.initial;
  String? _errorMessage;
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  KraveUser? get user => _user;
  SessionStatus get status => _status;
  String? get errorMessage => _errorMessage;
  double get balance => _user?.walletBalance ?? 0.0;
  bool get isLoading => _status == SessionStatus.fetchingProfile || _status == SessionStatus.authenticating;

  void setUnauthenticated() {
    _user = null;
    _status = SessionStatus.unauthenticated;
    _userSubscription?.cancel();
    notifyListeners();
  }

  Future<void> initializeSession(String uid) async {
    _status = SessionStatus.fetchingProfile;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Determine Role First (using optimized paths)
      final role = await _fs.getUserRole(uid);
      
      if (role == 'admin') {
        _status = SessionStatus.admin;
      } else if (role == 'pendingOwner') {
        _status = SessionStatus.pendingOwner;
      } else if (role == 'approvedOwner') {
        _status = SessionStatus.authenticated;
      } else if (role == 'user') {
        _status = SessionStatus.authenticated;
      } else {
        _status = SessionStatus.unauthenticated;
      }

      // 2. Setup Real-time Listener if it's a User or Owner
      if (_status == SessionStatus.authenticated || _status == SessionStatus.pendingOwner) {
        _startUserListener(uid);
      }
      
      notifyListeners();
    } catch (e) {
      _status = SessionStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void _startUserListener(String uid) {
    _userSubscription?.cancel();
    _userSubscription = _db.collection('Users').doc(uid).snapshots().listen(
      (doc) {
        if (doc.exists) {
          _user = KraveUser.fromMap(doc.id, doc.data() as Map<String, dynamic>);
        }
        notifyListeners();
      },
      onError: (e) {
        _status = SessionStatus.error;
        _errorMessage = e.toString();
        notifyListeners();
      }
    );
  }

  void setUser(KraveUser user) {
    _user = user;
    _status = SessionStatus.authenticated;
    notifyListeners();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  Future<void> topUpWallet(double amount) async {
    if (_user == null) return;
    await _db.collection('Users').doc(_user!.id).update({
      'walletBalance': FieldValue.increment(amount),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
