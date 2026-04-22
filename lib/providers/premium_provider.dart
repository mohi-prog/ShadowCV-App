// lib/providers/premium_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadowcv/services/premium_service.dart';

class PremiumState {
  final bool isPremium;
  final int remainingAnalyses;

  const PremiumState({
    required this.isPremium,
    required this.remainingAnalyses,
  });
}

final premiumProvider =
    FutureProvider<PremiumState>((ref) async {
  final isPremium = await PremiumService.isPremium();
  final remaining = await PremiumService.getRemainingAnalyses();

  return PremiumState(
    isPremium: isPremium,
    remainingAnalyses: remaining,
  );
});