import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:krave/src/models/rider_model.dart';
import '../services/firebase_service.dart';

enum AuthState { initial, loading, otpSent, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final FirebaseService _svc;

  AuthProvider(this._svc) {
    _svc.authStateChanges.listen(_onAuthChanged);
  }

  AuthState _state = AuthState.initial;
  RiderModel? _rider;
  User? _user;
  String? _error;
  String? _verificationId;

  AuthState get state => _state;
  RiderModel? get rider => _rider;
  String? get error => _error;
  bool get isAuthenticated => _state == AuthState.authenticated;

  Future<void> _onAuthChanged(User? user) async {
    _user = user;
    if (user == null) {
      _rider = null;
      _state = AuthState.unauthenticated;
    } else {
      _rider = await _svc.getRider(user.uid);
      _state = _rider != null ? AuthState.authenticated : AuthState.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> sendOTP(String phoneNumber) async {
    _state = AuthState.loading;
    _error = null;
    notifyListeners();

    try {
      await _svc.sendOTP(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-resolution on Android
          try {
            _rider = await _svc.signInWithCredential(credential);
            _state = AuthState.authenticated;
            notifyListeners();
          } catch (e) {
            _state = AuthState.error;
            _error = e.toString();
            notifyListeners();
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          _state = AuthState.error;
          _error = e.message ?? 'Verification failed';
          notifyListeners();
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _state = AuthState.otpSent;
          notifyListeners();
        },
      );
    } catch (e) {
      _state = AuthState.error;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> verifyOTP(String smsCode) async {
    if (_verificationId == null) return;
    _state = AuthState.loading;
    _error = null;
    notifyListeners();

    try {
      _rider = await _svc.verifyOTP(_verificationId!, smsCode);
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

  Future<void> updateBasicProfile(String name, String city, String vehicleType, String email) async {
    if (_rider == null) return;
    _state = AuthState.loading;
    notifyListeners();
    try {
      await _svc.updateBasicProfile(_rider!.id, name, city, vehicleType, email);
      _rider = _rider!.copyWith(
        name: name,
        city: city,
        vehicleType: vehicleType,
        email: email,
        onboardingStep: 2,
      );
      _state = AuthState.authenticated;
    } catch (e) {
      _state = AuthState.error;
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<void> uploadKycDocument(String docType, File file, Function(double) onProgress) async {
    if (_rider == null) return;
    try {
      final url = await _svc.uploadKycDocument(_rider!.id, docType, file, onProgress);
      // update local rider model to reflect the change immediately
      final newKyc = Map<String, dynamic>.from(_rider!.kycDetails);
      newKyc[docType] = {
        'url': url,
        'status': 'Uploaded',
      };
      _rider = _rider!.copyWith(kycDetails: newKyc);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> submitKycForVerification() async {
    if (_rider == null) return;
    _state = AuthState.loading;
    notifyListeners();
    try {
      await _svc.submitKycForVerification(_rider!.id);
      _rider = _rider!.copyWith(onboardingStep: 3);
      _state = AuthState.authenticated;
    } catch (e) {
      _state = AuthState.error;
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<void> reloadRiderData() async {
    if (_user == null) return;
    try {
      _rider = await _svc.getRider(_user!.uid);
      notifyListeners();
    } catch (e) {
      debugPrint('Error reloading rider data: $e');
    }
  }

  Future<void> toggleActive(bool value) async {
    if (_rider == null) return;
    await _svc.updateActiveStatus(_rider!.id, value);
    _rider = _rider!.copyWith(isActive: value);
    notifyListeners();
  }
}
