import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cv_analysis.dart';
import 'app_config.dart';

class UserService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  // ─── Aktuellen User holen ─────────────────────────────────────────────────
  static User? get currentUser => _auth.currentUser;

  // ─── User-Tier aus Firestore lesen ────────────────────────────────────────
  // Gibt UserTier.free zurück wenn kein Dokument existiert (sicherer Fallback)
  static Future<UserTier> getUserTier() async {
    try {
      final user = currentUser;
      if (user == null) return UserTier.free;

      final doc = await _firestore
          .collection(AppConfig.usersCollection)
          .doc(user.uid)
          .get();

      if (!doc.exists) return UserTier.free;

      final tierStr = doc.data()?['tier'] as String?;
      switch (tierStr) {
        case 'premium':
          return UserTier.premium;
        case 'career':
          return UserTier.career;
        default:
          return UserTier.free;
      }
    } catch (e) {
      // Bei Fehler immer auf free fallen → kein unerwarteter Premium-Zugang
      print('UserService.getUserTier Fehler: $e');
      return UserTier.free;
    }
  }

  // ─── Anzahl der Analysen heute (für Free-Tier Limit) ─────────────────────
  // Free User dürfen max. 3 Analysen pro Tag machen
  static Future<int> getAnalysesCountToday() async {
    try {
      final user = currentUser;
      if (user == null) return 0;

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final query = await _firestore
          .collection(AppConfig.analysesCollection)
          .where('userId', isEqualTo: user.uid)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .count()
          .get();

      return query.count ?? 0;
    } catch (e) {
      print('UserService.getAnalysesCountToday Fehler: $e');
      return 0;
    }
  }

  // ─── Prüfen ob User noch eine Analyse machen darf ────────────────────────
  static Future<bool> canPerformAnalysis() async {
    final tier = await getUserTier();
    if (tier.hasUnlimitedAnalyses) return true;

    // Free: max 3 pro Tag
    final count = await getAnalysesCountToday();
    return count < 3;
  }

  // ─── CV-Analyse in Firestore speichern ────────────────────────────────────
  static Future<String> saveAnalysis(CVAnalysis analysis) async {
    try {
      final doc = await _firestore
          .collection(AppConfig.analysesCollection)
          .add(analysis.toFirestore());
      return doc.id;
    } catch (e) {
      throw Exception('Fehler beim Speichern der Analyse: $e');
    }
  }

  // ─── Alle Analysen des aktuellen Users laden (für History) ───────────────
  static Future<List<CVAnalysis>> getUserAnalyses() async {
    try {
      final user = currentUser;
      if (user == null) return [];

      final query = await _firestore
          .collection(AppConfig.analysesCollection)
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) => CVAnalysis.fromFirestore(doc)).toList();
    } catch (e) {
      print('UserService.getUserAnalyses Fehler: $e');
      return [];
    }
  }

  // ─── Tier upgraden (wird von Zahlung ausgelöst) ───────────────────────────
  static Future<void> upgradeTier(UserTier newTier) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('Nicht eingeloggt');

      await _firestore
          .collection(AppConfig.usersCollection)
          .doc(user.uid)
          .update({
            'tier': newTier.displayName.toLowerCase(),
            'tierUpgradedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Fehler beim Tier-Upgrade: $e');
    }
  }
}
