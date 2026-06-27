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
      final notificationService = NotificationService();
      final calendarService = CalendarService();

      final container = ProviderContainer(
        overrides: [
          medicationRepositoryProvider.overrideWithValue(mockRepo),
          notificationServiceProvider.overrideWithValue(notificationService),
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

      // Assert local notification alert is scheduled
      expect(notificationService.activeAlarms, hasLength(1));
      expect(notificationService.activeAlarms.first.id, equals('med-id-01'));

      // Assert calendar event is created
      expect(calendarService.events, hasLength(1));
      expect(calendarService.events.first.title, contains('Aspirin'));
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
