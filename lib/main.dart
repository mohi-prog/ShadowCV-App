import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'onboarding.dart';
import 'home_screen.dart';
import 'kennlernphase.dart';
import 'google_auth_service.dart';
import 'splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await GoogleAuthService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  Future<DocumentSnapshot>? _userFuture;
  String? _lastUid;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;

        // 1️⃣ Auth-Status prüfen
        if (snapshot.connectionState == ConnectionState.waiting &&
            !_initialized) {
          return const SplashScreen(nextScreen: ShadowCVOnboarding());
        }

        // 2️⃣ Nicht eingeloggt
        if (user == null) {
          _initialized = true;
          return const ShadowCVOnboarding();
        }

        final uid = user.uid;
        _initialized = true;

        // 3️⃣ Firestore-Daten laden
        if (_userFuture == null || _lastUid != uid) {
          _lastUid = uid;
          _userFuture = FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get();
        }

        return FutureBuilder<DocumentSnapshot>(
          future: _userFuture,
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              // Nur beim ersten Laden den Splash zeigen
              return const HomeScreen();
            }

            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              return const Kennlernphase();
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>;

            if ((userData['name'] ?? '').toString().isEmpty) {
              return const Kennlernphase();
            }

            return const HomeScreen();
          },
        );
      },
    );
  }
}
