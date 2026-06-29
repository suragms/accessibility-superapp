import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:accessibility_super_app/core/database/app_database.dart';
import 'package:accessibility_super_app/core/services/calendar_service.dart';
import 'package:accessibility_super_app/core/services/notification_service.dart';
import 'package:accessibility_super_app/features/medication/data/repositories/medication_repository.dart';
import 'package:accessibility_super_app/features/medication/domain/models/medication.dart';
import 'package:accessibility_super_app/features/medication/presentation/controllers/medication_controller.dart';

/// Manual Mock DB Repository to completely decouple SQLite filesystem checks from unit tests.
class MockMedicationRepository extends MedicationRepository {
  final List<MedicationModel> activeMeds = [];
  final List<Map<String, dynamic>> logs = [];

  MockMedicationRepository() : super(db: AppDatabase());

  @override
  Future<void> addMedication(MedicationModel medication) async {
    activeMeds.add(medication);
  }

  @override
  Future<void> deleteMedication(String id) async {
    activeMeds.removeWhere((m) => m.id == id);
  }

  @override
  Future<List<MedicationModel>> getActiveMedications(String userId) async {
    return activeMeds;
  }

  @override
  Future<void> logMedicationStatus({
    required String logId,
    required String medicationId,
    required DateTime scheduledTime,
    DateTime? takenTime,
    required String status,
    bool isSynced = false,
  }) async {
    logs.add({
      'logId': logId,
      'medicationId': medicationId,
      'status': status,
      'isSynced': isSynced,
    });
  }
}

/// Mock NotificationService to verify scheduling and cancellation calls.
class MockNotificationService extends NotificationService {
  final List<Map<String, dynamic>> scheduledNotifications = [];
  final List<String> cancelledNotifications = [];
  bool cancelAllCalled = false;

  MockNotificationService() : super();

  @override
  Future<void> scheduleNotification({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? soundPath,
  }) async {
    scheduledNotifications.add({
      'id': id,
      'title': title,
      'body': body,
      'scheduledTime': scheduledTime,
      'soundPath': soundPath,
    });
  }

  @override
  Future<void> cancelNotification(String id) async {
    cancelledNotifications.add(id);
  }

  @override
  Future<void> cancelAllNotifications() async {
    cancelAllCalled = true;
  }
}

void main() {
  group('MedicationModule Logic Tests', () {
    test('Verify MedicationModel JSON conversions', () {
      final model = MedicationModel(
        id: 'aspirin-01',
        userId: 'user-77',
        name: 'Aspirin',
        dosage: '1 Pill',
        cronSchedule: 'Daily',
        doctorNotes: 'Take after breakfast',
        createdAt: DateTime.parse('2026-06-27T10:00:00Z'),
      );

      final jsonMap = model.toJson();
      final decoded = MedicationModel.fromJson(jsonMap);

      expect(decoded.id, equals('aspirin-01'));
      expect(decoded.name, equals('Aspirin'));
      expect(decoded.doctorNotes, equals('Take after breakfast'));
    });

    test('Verify MedicationController CRUD and Notification scheduling flow', () async {
      final mockRepo = MockMedicationRepository();
      final mockNotificationService = MockNotificationService();
      final calendarService = CalendarService();

      final container = ProviderContainer(
        overrides: [
          medicationRepositoryProvider.overrideWithValue(mockRepo),
          notificationServiceProvider.overrideWithValue(mockNotificationService),
          calendarServiceProvider.overrideWithValue(calendarService),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(medicationControllerProvider.notifier);

      final med = MedicationModel(
        id: 'med-id-01',
        userId: 'user-77',
        name: 'Aspirin',
        dosage: '1 Tablet',
        cronSchedule: 'Daily',
        createdAt: DateTime.now(),
      );

      // Add medication with calendar sync enabled
      await controller.addMedication(med, integrateCalendar: true);

      // Assert repository cache matches
      expect(mockRepo.activeMeds, hasLength(1));
      expect(mockRepo.activeMeds.first.name, equals('Aspirin'));

      // Assert notification scheduling was called with correct parameters
      expect(mockNotificationService.scheduledNotifications, hasLength(1));
      expect(mockNotificationService.scheduledNotifications.first['id'], equals('med-id-01'));
      expect(mockNotificationService.scheduledNotifications.first['title'], contains('Aspirin'));
      expect(mockNotificationService.scheduledNotifications.first['body'], contains('1 Tablet'));

      // Assert calendar event is created
      expect(calendarService.events, hasLength(1));
      expect(calendarService.events.first.title, contains('Aspirin'));
    });

    test('Verify deleting a medication cancels its notification', () async {
      final mockRepo = MockMedicationRepository();
      final mockNotificationService = MockNotificationService();
      final calendarService = CalendarService();

      // Pre-populate with a medication
      mockRepo.activeMeds.add(MedicationModel(
        id: 'med-id-02',
        userId: 'user-77',
        name: 'Ibuprofen',
        dosage: '2 Tablets',
        cronSchedule: 'Twice daily',
        createdAt: DateTime.now(),
      ));

      final container = ProviderContainer(
        overrides: [
          medicationRepositoryProvider.overrideWithValue(mockRepo),
          notificationServiceProvider.overrideWithValue(mockNotificationService),
          calendarServiceProvider.overrideWithValue(calendarService),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(medicationControllerProvider.notifier);

      // Delete the medication
      await controller.deleteMedication('med-id-02', 'user-77');

      // Assert medication was removed from repository
      expect(mockRepo.activeMeds, isEmpty);

      // Assert notification was cancelled
      expect(mockNotificationService.cancelledNotifications, hasLength(1));
      expect(mockNotificationService.cancelledNotifications.first, equals('med-id-02'));
    });

    test('Verify compliance offline log syncing flow', () async {
      final mockRepo = MockMedicationRepository();
      final container = ProviderContainer(
        overrides: [
          medicationRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(medicationControllerProvider.notifier);

      // Log compliance in offline state
      await controller.logCompliance(
        medicationId: 'med-id-01',
        scheduledTime: DateTime.now(),
        status: 'TAKEN',
        isOnline: false,
      );

      // Assert local DB captures compliance status
      expect(mockRepo.logs, hasLength(1));
      expect(mockRepo.logs.first['status'], equals('TAKEN'));
      expect(mockRepo.logs.first['isSynced'], isFalse);

      // Assert controller sets offline sync warning flags
      expect(container.read(medicationControllerProvider).offlineSyncNeeded, isTrue);
    });
  });
}
