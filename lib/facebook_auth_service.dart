import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class FacebookAuthService {
  static Future<User?> handleFacebookSignIn() async {
    try {
      print("🔵 Starting Facebook Sign-In...");

      // Facebook Login
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.success) {
        // Access Token holen
        final AccessToken accessToken = result.accessToken!;

        // Firebase Credential erstellen
        final OAuthCredential credential = FacebookAuthProvider.credential(
          accessToken.tokenString,
        );

        // Firebase Login
        final userCredential = await FirebaseAuth.instance.signInWithCredential(
          credential,
        );

        print("✅ Signed in: ${userCredential.user?.email}");
        return userCredential.user;
      } else if (result.status == LoginStatus.cancelled) {
        print("❌ User cancelled Facebook login");
        return null;
      } else {
        print("❌ Facebook login failed: ${result.message}");
        return null;
      }
    } catch (e) {
      print("❌ Facebook Login Fehler: $e");
      return null;
    }
  }
}
