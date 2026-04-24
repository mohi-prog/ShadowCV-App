// ⚠️ SICHERHEITSHINWEIS:
// API-Keys NIEMALS in einem öffentlichen Git-Repo pushen!
// Die echten Keys liegen in lib/secrets.dart (gitignored).
// Für Setup: lib/secrets.example.dart → lib/secrets.dart kopieren und Keys eintragen.

import 'package:shadowcv/secrets.dart';

class AppConfig {
  // ── Groq (OpenAI-compatible) API ──
  static const String groqApiKey = Secrets.groqApiKey;
  static const String groqApiUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String groqModelFast = 'llama-3.1-8b-instant';
  static const String groqModelPower = 'llama-3.3-70b-versatile';
  static const String groqModelVision =
      'meta-llama/llama-4-scout-17b-16e-instruct';

  // ── Claude (Anthropic) API ──
  static const String claudeApiKey = 'DEN_CLAUDE_API_KEY_HIER';
  static const String claudeApiUrl = 'https://api.anthropic.com/v1/messages';
  static const String claudeModel = 'claude-opus-4-6';

  // ── App Tier Preise (für die UI) ──
  static const double premiumPrice = 19.99;
  static const double careerPrice = 49.99;

  // ── Firestore Collection Namen ──
  static const String usersCollection = 'users';
  static const String analysesCollection = 'analyses';
  static const String cvFilesCollection = 'cv_files';
}
