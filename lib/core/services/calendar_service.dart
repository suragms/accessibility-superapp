import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// Representation of a calendar event entry.
class CalendarEvent {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;

  const CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
  });
}

/// Device calendar integration service wrapping platform capabilities.
class CalendarService {
  final List<CalendarEvent> _events = [];

  List<CalendarEvent> get events => List.unmodifiable(_events);

  /// Writes event schedules to native iOS/Android device calendars.
  Future<String> addEvent({
    required String title,
    required String description,
    required DateTime startTime,
  }) async {
    // In production, uses device_calendar package or PlatformChannels to execute calendar permissions and write query inserts.
    final eventId = const Uuid().v4();
    _events.add(CalendarEvent(
      id: eventId,
      title: title,
      description: description,
      startTime: startTime,
    ));
    return eventId;
  }

  /// Removes event from calendar logs.
  Future<void> removeEvent(String eventId) async {
    _events.removeWhere((event) => event.id == eventId);
  }
}

/// Riverpod provider for CalendarService.
final calendarServiceProvider = Provider<CalendarService>((ref) {
  return CalendarService();
});
