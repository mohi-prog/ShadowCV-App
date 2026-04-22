import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class PremiumService {
  static const String _monthlyId = 'shadowcv_premium_monthly';
  static const String _lifetimeId = 'shadowcv_premium_lifetime';
  static const int freeAnalysisLimit = 3;

  static const Set<String> _productIds = {_monthlyId, _lifetimeId};

  static final InAppPurchase _iap = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _subscription;

  static List<ProductDetails> products = [];
  static bool isAvailable = false;

  // Cache um Firestore-Reads zu sparen
  static bool? _cachedPremiumStatus;
  static DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  // ==================== DEV MODE ====================

  static bool _devModeEnabled = false;
  static bool get devModeEnabled => _devModeEnabled;

  static Future<void> enableDevMode() async {
    _devModeEnabled = true;
    _cachedPremiumStatus = true;
    await _savePremiumToFirestore('dev_lifetime');
    debugPrint('🔓 DEV: Premium aktiviert');
  }

  static Future<void> disableDevMode() async {
    _devModeEnabled = false;
    _cachedPremiumStatus = false;
    await _removePremiumFromFirestore();
    debugPrint('🔒 DEV: Premium deaktiviert');
  }

  // ==================== PREMIUM STATUS ====================

  static Future<bool> isPremium() async {
    if (_devModeEnabled) return true;

    // Cache Check
    if (_cachedPremiumStatus != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      return _cachedPremiumStatus!;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) return _cache(false);
      final data = doc.data() as Map<String, dynamic>;
      final tier = data['tier'] ?? 'free';
      final premiumUntil = data['premiumUntil'] as Timestamp?;

      if (tier == 'lifetime') return _cache(true);

      if (tier == 'monthly' && premiumUntil != null) {
        return _cache(premiumUntil.toDate().isAfter(DateTime.now()));
      }

      return _cache(false);
    } catch (e) {
      debugPrint('Premium check error: $e');
      return false;
    }
  }

  static bool _cache(bool value) {
    _cachedPremiumStatus = value;
    _cacheTime = DateTime.now();
    return value;
  }

  static void clearCache() {
    _cachedPremiumStatus = null;
    _cacheTime = null;
  }

  // ==================== FEATURE GATES ====================

  static Future<bool> canAnalyze() async {
    if (await isPremium()) return true;
    final count = await getAnalysisCount();
    return count < freeAnalysisLimit;
  }

  static Future<bool> canUseChat() async => isPremium();
  static Future<bool> canUseRewrite() async => isPremium();
  static Future<bool> canExportPDF() async => isPremium();

  static Future<bool> canUseMode(String mode) async {
    if (await isPremium()) return true;
    // Free: nur General Review
    return mode == 'generalReview';
  }

  static Future<int> getRemainingAnalyses() async {
    if (await isPremium()) return -1; // unlimited
    final count = await getAnalysisCount();
    return (freeAnalysisLimit - count).clamp(0, freeAnalysisLimit);
  }

  // ==================== ANALYSIS COUNT ====================

 static Future<int> getAnalysisCount() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return 0;

  try {
    // Echte Anzahl aus der cvs Subcollection zählen
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cvs')
        .get();

    final realCount = snapshot.docs.length;

    // Counter in Firestore synchronisieren (damit canAnalyze() korrekt arbeitet)
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({'analysisCount': realCount}, SetOptions(merge: true));

    return realCount;
  } catch (e) {
    debugPrint('getAnalysisCount error: $e');
    // Fallback auf gespeicherten Counter
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!doc.exists) return 0;
      return (doc.data() as Map<String, dynamic>)['analysisCount'] ?? 0;
    } catch (_) {
      return 0;
    }
  }
}
  static Future<void> incrementAnalysisCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(
      {'analysisCount': FieldValue.increment(1)},
      SetOptions(merge: true),
    );
  }

  // ==================== IAP ====================

  static Future<void> initialize() async {
    try {
      isAvailable = await _iap.isAvailable();
      if (!isAvailable) {
        debugPrint('⚠️ IAP nicht verfügbar (Emulator / kein Store)');
        return;
      }

      final response = await _iap.queryProductDetails(_productIds);
      products = response.productDetails;

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('⚠️ Produkte nicht gefunden: ${response.notFoundIDs}');
      }

      _subscription?.cancel();
      _subscription = _iap.purchaseStream.listen(
        _onPurchaseUpdate,
        onError: (e) => debugPrint('IAP Stream Error: $e'),
      );
    } catch (e) {
      debugPrint('IAP Init Error: $e');
      isAvailable = false;
    }
  }

  static void _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          await _savePremiumToFirestore(purchase.productID);
          clearCache();
          debugPrint('✅ Kauf bestätigt: ${purchase.productID}');
          break;
        case PurchaseStatus.error:
          debugPrint('❌ Kauf Fehler: ${purchase.error?.message}');
          break;
        case PurchaseStatus.pending:
          debugPrint('⏳ Kauf ausstehend...');
          break;
        case PurchaseStatus.canceled:
          debugPrint('🚫 Kauf abgebrochen');
          break;
      }
    }
  }

  // ==================== FIRESTORE ====================

  static Future<void> _savePremiumToFirestore(String productId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final isLifetime =
        productId.contains('lifetime') || productId == 'dev_lifetime';

    final Map<String, dynamic> data = {
      'tier': isLifetime ? 'lifetime' : 'monthly',
      'premiumProductId': productId,
      'premiumActivatedAt': FieldValue.serverTimestamp(),
    };

    if (!isLifetime) {
      data['premiumUntil'] = Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 30)),
      );
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(data, SetOptions(merge: true));

    clearCache();
  }

  static Future<void> _removePremiumFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({
      'tier': 'free',
      'premiumProductId': FieldValue.delete(),
      'premiumUntil': FieldValue.delete(),
      'premiumActivatedAt': FieldValue.delete(),
    }, SetOptions(merge: true));

    clearCache();
  }

  // ==================== PURCHASE ACTIONS ====================

  static Future<void> buyMonthly() async {
    if (!isAvailable || products.isEmpty) {
      throw Exception('Store nicht verfügbar');
    }
    final product = products.firstWhere(
      (p) => p.id == _monthlyId,
      orElse: () => throw Exception('Produkt nicht gefunden: $_monthlyId'),
    );
    await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
  }

  static Future<void> buyLifetime() async {
    if (!isAvailable || products.isEmpty) {
      throw Exception('Store nicht verfügbar');
    }
    final product = products.firstWhere(
      (p) => p.id == _lifetimeId,
      orElse: () => throw Exception('Produkt nicht gefunden: $_lifetimeId'),
    );
    await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
  }

  static Future<void> restorePurchases() async {
    if (!isAvailable) {
      debugPrint('⚠️ Restore nicht möglich – Store nicht verfügbar');
      return;
    }
    await _iap.restorePurchases();
  }

  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
    clearCache();
  }
}