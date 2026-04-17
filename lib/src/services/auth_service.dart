import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreService _fs = FirestoreService();

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<UserCredential> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google Sign-in cancelled');

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // Create a new credential
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Once signed in, return the UserCredential
    final userCredential = await _auth.signInWithCredential(credential);
    
    // ENSURE SKELETON RECORD EXISTS (For first-time Google Sign-in)
    if (userCredential.user != null) {
      final doc = await _fs.getUser(userCredential.user!.uid);
      if (doc == null) {
        // Create full skeleton using our Professional-Grade KraveUser model
        final newUser = KraveUser(
          id: userCredential.user!.uid,
          name: userCredential.user!.displayName ?? 'Unnamed User',
          email: userCredential.user!.email ?? '',
          role: 'user', // Default to user
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          walletBalance: 0.0,
        );
        await _fs.createUser(newUser);
      }

      // Sync FCM Token
      final token = await _fcm.getToken();
      if (token != null) {
        await _fs.updateUserFCMToken(userCredential.user!.uid, token);
      }
    }

    return userCredential;
  }

  Future<UserCredential> registerWithEmail(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> loginWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    
    if (credential.user != null) {
      final token = await _fcm.getToken();
      if (token != null) {
        await _fs.updateUserFCMToken(credential.user!.uid, token);
      }
    }
    
    return credential;
  }

  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
