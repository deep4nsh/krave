import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';

class UserProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  KraveUser? _user;
  bool _isLoading = true;
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  KraveUser? get user => _user;
  bool get isLoading => _isLoading;
  double get balance => _user?.walletBalance ?? 0.0;

  void init(String uid) {
    _isLoading = true;
    notifyListeners();

    _userSubscription?.cancel();
    _userSubscription = _db.collection('Users').doc(uid).snapshots().listen((doc) {
      if (doc.exists) {
        _user = KraveUser.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  Future<void> refreshUser() async {
    // Subscription handles real-time updates now, but we keep this for manual sanity checks
    if (_user == null) return;
    final doc = await _db.collection('Users').doc(_user!.id).get();
    if (doc.exists) {
      _user = KraveUser.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      notifyListeners();
    }
  }

  // Mock Top-up Logic for Testing
  Future<void> topUpWallet(double amount) async {
    if (_user == null) return;
    
    // In a real app, this would happen after a Razorpay payment response
    await _db.collection('Users').doc(_user!.id).update({
      'walletBalance': FieldValue.increment(amount),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    // The stream listener will automatically update the UI
  }
}
