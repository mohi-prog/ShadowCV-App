import 'package:shared_preferences/shared_preferences.dart';

/// Speichern, dass Onboarding fertig ist
Future<void> setOnboardingSeen() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('onboardingSeen', true);
}

/// Prüfen, ob Onboarding schon gesehen wurde
Future<bool> isOnboardingSeen() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboardingSeen') ?? false;
}
