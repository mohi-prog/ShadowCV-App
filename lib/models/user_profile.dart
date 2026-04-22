// lib/data/models/user_profile.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum UserTier { free, premium, career }

extension UserTierExtension on UserTier {
  String get displayName {
    switch (this) {
      case UserTier.free:
        return 'Free';
      case UserTier.premium:
        return 'Premium';
      case UserTier.career:
        return 'Career';
    }
  }

  bool get canUseAIChat => this != UserTier.free;
  bool get canOptimizeCV => this != UserTier.free;
  bool get canUseCoverLetter => this == UserTier.career;
  bool get hasUnlimitedAnalyses => this != UserTier.free;
}

class UserProfile {
  final String id;
  final String email;
  final String? name;
  final String? jobTitle;
  final UserTier tier;
  final int analysisCount; // NEU: Anzahl der durchgeführten Analysen

  UserProfile({
    required this.id,
    required this.email,
    this.name,
    this.jobTitle,
    this.tier = UserTier.free,
    this.analysisCount = 0, // Standardwert 0
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    UserTier parsedTier = UserTier.free;
    final tierStr = data['tier'] as String?;
    if (tierStr == 'premium') {
      parsedTier = UserTier.premium;
    } else if (tierStr == 'career') {
      parsedTier = UserTier.career;
    }

    return UserProfile(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'],
      jobTitle: data['jobTitle'],
      tier: parsedTier,
      analysisCount: data['analysisCount'] ?? 0, // NEU: Aus Firestore lesen
    );
  }

  bool get isProfileComplete => name != null && name!.isNotEmpty;
}
