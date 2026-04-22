import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  static final _googleSignIn = GoogleSignIn.instance;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (!_initialized) {
      await _googleSignIn.initialize();
      _initialized = true;
    }
  }

  static Future<User?> handleGoogleSignIn() async {
    try {
      // Authentifizieren
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      // idToken direkt aus authentication holen
      final idToken = googleUser.authentication.idToken;

      // Firebase Credential erstellen
      final credential = GoogleAuthProvider.credential(idToken: idToken);

      // Firebase Login
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      print("✅ Signed in: ${userCredential.user?.email}");
      return userCredential.user;
    } catch (e) {
      print("❌ Google Login Fehler: $e");
      return null;
    }
  }
}
