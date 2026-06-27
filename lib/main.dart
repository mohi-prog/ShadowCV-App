import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/rendering.dart';
import 'package:shadowcv/services/premium_service.dart';
import 'firebase/firebase_options.dart';
import 'screens/onboarding.dart';
import 'screens/home_screen.dart';
import 'screens/kennlernphase.dart';
import 'services/google_auth_service.dart';
import 'screens/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/translation_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import 'package:shadowcv/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Muss initialisiert sein, falls du hier auf Firebase/Datenbank zugreifen willst
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Core Services
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    
    // Background Message Handler registrieren
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint("Firebase Init Error: $e");
  }

  final prefs = await SharedPreferences.getInstance();

  // Background Initializations (non-blocking)
  _initServices();

  final skipSplash = prefs.getBool('skip_splash_once') ?? false;
  if (skipSplash) {
    await prefs.remove('skip_splash_once');
  }

  runApp(ProviderScope(child: MyApp(skipSplash: skipSplash)));
}

Future<void> _initServices() async {
  try {
    // Notification Service
    final notificationService = NotificationService();
    await notificationService.init();
    
    // Plant Erinnerungen alle 2 Tage um 12:00 Uhr
    await notificationService.scheduleBiDailyReminders();

    await GoogleAuthService.initialize();
    await AppTranslation.initLanguage();
    await PremiumService.initialize();
    
    debugPaintSizeEnabled = false;
  } catch (e) {
    debugPrint("Service Init Error: $e");
  }
}

class MyApp extends StatelessWidget {
  final bool skipSplash;
  MyApp({super.key, this.skipSplash = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ShadowCV',

      builder: (context, child) {
        final media = MediaQuery.of(context);

        return MediaQuery(
          data: media.copyWith(
            // verhindert Layout-Overflows bei extremen Schriftgrößen
            textScaler: media.textScaler.clamp(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.15,
            ),
          ),
          child: child!,
        );
      },

      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.deepPurpleAccent,
        useMaterial3: true,
        fontFamily: 'Boldo',
      ),
      home: skipSplash
          ? const AuthWrapper()
          : const SplashScreen(nextScreen: AuthWrapper()),
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;

        // 1. Nicht eingeloggt -> Onboarding
        if (user == null) {
          debugPrint("AuthWrapper: User is null -> Onboarding");
          return const ShadowCVOnboarding();
        }

        final uid = user.uid;
        debugPrint("AuthWrapper: User is logged in: $uid");

        // 2. Firestore Future initialisieren, wenn nötig
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
            // Warten auf Firestore
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Colors.black,
                body: Center(
                  child: CircularProgressIndicator(
                    color: Colors.deepPurpleAccent,
                  ),
                ),
              );
            }

            // Check: Existiert Dokument?
            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              debugPrint("AuthWrapper: Firestore doc missing -> Kennlernphase");
              return const Kennlernphase();
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
            final name = userData['name'];

            // Check: Ist Name leer?
            if ((name ?? '').toString().isEmpty) {
              debugPrint("AuthWrapper: Name empty -> Kennlernphase");
              return const Kennlernphase();
            }

            // Alles gut -> Home
            debugPrint("AuthWrapper: All good -> HomeScreen");
            return const HomeScreen();
          },
        );
      },
    );
  }
}
