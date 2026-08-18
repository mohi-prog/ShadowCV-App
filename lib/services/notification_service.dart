import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  bool _initialized = false;

  static const String _dailyReminderKey = 'last_reminder_date';
  static const String _reminderChannelId = 'shadowcv_reminders';
  static const String _mainChannelId = 'shadowcv_main_channel';

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    tz.initializeTimeZones();

    // Android Notification Channels
    const androidSettings =
        AndroidInitializationSettings('notification_icon');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Android 13+ Benachrichtigungs-Berechtigung
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    // Firebase Messaging Token anfordern
    await _requestFCMToken();

    // FCM Token Refresh Listener
    _firebaseMessaging.onTokenRefresh.listen(_onTokenRefresh);
  }

  Future<void> _requestFCMToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
      }
    } catch (e) {
      debugPrint('FCM Token Error: $e');
    }
  }

  void _onTokenRefresh(String token) {
    debugPrint('FCM Token refreshed: $token');
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Plant Erinnerungen alle 2 Tage um 12:00 Uhr
  Future<void> scheduleBiDailyReminders() async {
    // Prüfen ob heute schon eine Erinnerung geplant wurde
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_dailyReminderKey);
    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (lastDate == today) return;

    // Nur den bestehenden Reminder canceln (ID 0)
    await _localNotifications.cancel(0);

    // Nächste Erinnerung in 2 Tagen um 12:00
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      12,
    );

    // Wenn heute schon nach 12:00, dann morgen
    if (now.hour >= 12) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Alle 2 Tage wiederholen
    scheduledDate = scheduledDate.add(const Duration(days: 1));

    const androidDetails = AndroidNotificationDetails(
      _reminderChannelId,
      'CV Reminders',
      channelDescription: 'Reminders to update and improve your CV',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      channelShowBadge: false,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.zonedSchedule(
      0, // ID
      'CV Check-in 📋',
      'Time to give your CV a quick review! Small improvements make a big difference.',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'reminder',
    );

    await prefs.setString(_dailyReminderKey, today);
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _mainChannelId,
      'ShadowCV',
      channelDescription: 'Main notification channel for ShadowCV',
      importance: Importance.high,
      priority: Priority.high,
      channelShowBadge: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().microsecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }
}
