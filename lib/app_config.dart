// ⚠️ SICHERHEITSHINWEIS:
// API-Keys NIEMALS in einem öffentlichen Git-Repo pushen!
// Für Production → Firebase Cloud Functions nutzen, sodass der Key
// nur serverseitig liegt. Für MVP/Dev ist das hier okay.

class AppConfig {
  // Claude (Anthropic) API Key
  // Beantragen unter: https://console.anthropic.com
  static const String claudeApiKey = 'DEIN_CLAUDE_API_KEY_HIER';
  static const String claudeApiUrl = 'https://api.anthropic.com/v1/messages';
  static const String claudeModel = 'claude-opus-4-6';

  // App Tier Preise (für die UI)
  static const double premiumPrice = 19.99;
  static const double careerPrice = 49.99;

  // Firestore Collection Namen
  static const String usersCollection = 'users';
  static const String analysesCollection = 'analyses';
  static const String cvFilesCollection = 'cv_files';
}
