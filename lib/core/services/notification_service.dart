import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

/// Representation of a scheduled local alarm notification.
class ScheduledNotification {
  final String id;
  final String title;
  final String body;
  final DateTime scheduledTime;
  final String? soundPath;

  const ScheduledNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledTime,
    this.soundPath,
  });
}

/// Platform notifications wrapper executing local schedules and repeat alerts.
/// Uses flutter_local_notifications for real OS-level notifications while
/// maintaining an in-memory cache for UI display of upcoming reminders.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;
  final List<ScheduledNotification> _activeAlarms = [];

  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  List<ScheduledNotification> get activeAlarms => List.unmodifiable(_activeAlarms);

  /// Initializes the notification plugin for both Android and iOS.
  /// Must be called once at app startup (typically in main.dart).
  static Future<void> initialize(FlutterLocalNotificationsPlugin plugin) async {
    tz.initializeTimeZones();

    // Android initialization
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization – request permissions
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await plugin.initialize(initSettings);

    // Create the medication reminder notification channel on Android
    if (Platform.isAndroid) {
      final androidPlugin =
          plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'medication_reminders',
            'Medication Reminders',
            description: 'Reminders to take your scheduled medications',
            importance: Importance.high,
            enableVibration: true,
            enableLights: true,
          ),
        );
      }
    }
  }

  /// Registers a scheduled local alarm using the OS notification scheduler.
  Future<void> scheduleNotification({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? soundPath,
  }) async {
    // Add to in-memory cache for UI display
    _activeAlarms.add(
      ScheduledNotification(
        id: id,
        title: title,
        body: body,
        scheduledTime: scheduledTime,
        soundPath: soundPath,
      ),
    );

    // Schedule the real OS-level notification
    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    // Parse the notification ID from the string (use hash for uniqueness)
    final notificationId = id.hashCode;

    const androidDetails = AndroidNotificationDetails(
      'medication_reminders',
      'Medication Reminders',
      channelDescription: 'Reminders to take your scheduled medications',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      enableLights: true,
      icon: '@mipmap/ic_launcher',
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

    await _plugin.zonedSchedule(
      notificationId,
      title,
      body,
      tzScheduledTime,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null, // One-shot notification
    );
  }

  /// Cancels a scheduled alert.
  Future<void> cancelNotification(String id) async {
    _activeAlarms.removeWhere((alarm) => alarm.id == id);

    // Cancel the real OS notification
    final notificationId = id.hashCode;
    await _plugin.cancel(notificationId);
  }

  /// Silences all notifications.
  Future<void> cancelAllNotifications() async {
    _activeAlarms.clear();

    // Cancel all real OS notifications
    await _plugin.cancelAll();
  }
}

/// Riverpod provider for NotificationService.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
