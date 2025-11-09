import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirestoreService _fs = FirestoreService(); // Instantiate firestore service

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<UserCredential> registerWithEmail(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> loginWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    
    // After successful login, get and save the FCM token.
    if (credential.user != null) {
      final token = await _fcm.getToken();
      if (token != null) {
        await _fs.updateUserFCMToken(credential.user!.uid, token);
      }
    }
    
    return credential;
  }

  Future<void> logout() async {
    // Optional: Delete the token on logout if you want to stop notifications
    // if (currentUser != null) {
    //   await _fs.updateUserFCMToken(currentUser!.uid, null);
    // }
    await _auth.signOut();
  }
}
