import 'package:flutter_riverpod/flutter_riverpod.dart';

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
class NotificationService {
  final List<ScheduledNotification> _activeAlarms = [];

  List<ScheduledNotification> get activeAlarms => List.unmodifiable(_activeAlarms);

  /// Registers a scheduled local alarm.
  Future<void> scheduleNotification({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? soundPath,
  }) async {
    // In production iOS/Android native packages, triggers platform notification scheduler channels.
    _activeAlarms.add(
      ScheduledNotification(
        id: id,
        title: title,
        body: body,
        scheduledTime: scheduledTime,
        soundPath: soundPath,
      ),
    );
  }

  /// Cancels a scheduled alert.
  Future<void> cancelNotification(String id) async {
    _activeAlarms.removeWhere((alarm) => alarm.id == id);
  }

  /// Silences all notifications.
  Future<void> cancelAllNotifications() async {
    _activeAlarms.clear();
  }
}

/// Riverpod provider for NotificationService.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
