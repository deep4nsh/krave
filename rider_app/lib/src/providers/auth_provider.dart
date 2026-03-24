import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/rider_model.dart';
import '../services/firebase_service.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final FirebaseService _svc;

  AuthProvider(this._svc) {
    _svc.authStateChanges.listen(_onAuthChanged);
  }

  AuthState _state = AuthState.initial;
  RiderModel? _rider;
  String? _error;

  AuthState get state => _state;
  RiderModel? get rider => _rider;
  String? get error => _error;
  bool get isAuthenticated => _state == AuthState.authenticated;

  Future<void> _onAuthChanged(User? user) async {
    if (user == null) {
      _rider = null;
      _state = AuthState.unauthenticated;
    } else {
      _rider = await _svc.getRider(user.uid);
      _state = _rider != null ? AuthState.authenticated : AuthState.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    _state = AuthState.loading;
    _error = null;
    notifyListeners();
    try {
      _rider = await _svc.signIn(email, password);
      _state = AuthState.authenticated;
    } catch (e) {
      _state = AuthState.error;
      _error = e.toString().replaceAll('Exception: ', '');
    }
    notifyListeners();
  }

  Future<void> signOut() async {
    await _svc.signOut();
    _rider = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  Future<void> toggleActive(bool value) async {
    if (_rider == null) return;
    await _svc.updateActiveStatus(_rider!.id, value);
    _rider = _rider!.copyWith(isActive: value);
    notifyListeners();
  }
}
