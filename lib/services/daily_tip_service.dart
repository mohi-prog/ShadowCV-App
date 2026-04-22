import 'package:shared_preferences/shared_preferences.dart';

class DailyTipService {
  
  static int getTodayIndex(int totalTips) {
    return DateTime.now()
            .difference(DateTime(DateTime.now().year, 1, 1))
            .inDays %
        totalTips;
  }

  static Future<bool> isTipDismissedToday() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? dismissedDate = prefs.getString('tip_dismissed_date');
    final String today = DateTime.now().toString().substring(0, 10);
    return dismissedDate == today;
  }

  static Future<void> dismissTipForToday() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String today = DateTime.now().toString().substring(0, 10);
    await prefs.setString('tip_dismissed_date', today);
  }
}