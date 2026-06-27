import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/calendar_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/repositories/medication_repository.dart';
import '../../domain/models/medication.dart';

class MedicationState {
  final List<MedicationModel> medications;
  final bool isLoading;
  final bool offlineSyncNeeded;

  const MedicationState({
    required this.medications,
    required this.isLoading,
    required this.offlineSyncNeeded,
  });

  MedicationState copyWith({
    List<MedicationModel>? medications,
    bool? isLoading,
    bool? offlineSyncNeeded,
  }) {
    return MedicationState(
      medications: medications ?? this.medications,
      isLoading: isLoading ?? this.isLoading,
      offlineSyncNeeded: offlineSyncNeeded ?? this.offlineSyncNeeded,
    );
  }
}

/// Controller driving active medication schedules, alarms scheduling,
/// calendar synchronicities, and offline logs updates.
class MedicationController extends StateNotifier<MedicationState> {
  final MedicationRepository medicationRepository;
  final NotificationService notificationService;
  final CalendarService calendarService;

  MedicationController({
    required this.medicationRepository,
    required this.notificationService,
    required this.calendarService,
  }) : super(const MedicationState(
          medications: [],
          isLoading: false,
          offlineSyncNeeded: false,
        ));

  /// Reads active medications.
  Future<void> fetchActiveMedications(String userId) async {
    state = state.copyWith(isLoading: true);
    try {
      final list = await medicationRepository.getActiveMedications(userId);
      state = state.copyWith(medications: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Saves a new medicine. Configures notification alarms and device calendars.
  Future<void> addMedication(
    MedicationModel medication, {
    bool integrateCalendar = false,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      // 1. Write Drift SQLite cache
      await medicationRepository.addMedication(medication);

      // 2. Schedule repeating notification alarm
      final alarmTime = DateTime.now().add(const Duration(hours: 1)); // Mock schedule window
      await notificationService.scheduleNotification(
        id: medication.id,
        title: 'Medication Alert: ${medication.name}',
        body: 'Time to take dosage: ${medication.dosage}. Notes: ${medication.doctorNotes ?? ""}',
        scheduledTime: alarmTime,
        soundPath: medication.voiceReminderPath,
      );

      // 3. Integrate calendar if designated
      if (integrateCalendar) {
        await calendarService.addEvent(
          title: 'Take Medication: ${medication.name}',
          description: 'Dosage: ${medication.dosage}. Notes: ${medication.doctorNotes ?? ""}',
          startTime: alarmTime,
        );
      }

      final list = await medicationRepository.getActiveMedications(medication.userId);
      state = state.copyWith(medications: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Submits taking records. Logs status taken/snoozed/missed.
  Future<void> logCompliance({
    required String medicationId,
    required DateTime scheduledTime,
    required String status,
    bool isOnline = true,
  }) async {
    final logId = const Uuid().v4();
    final takenTime = status == 'TAKEN' ? DateTime.now() : null;

    try {
      // 1. Record Drift SQLite history log
      await medicationRepository.logMedicationStatus(
        logId: logId,
        medicationId: medicationId,
        scheduledTime: scheduledTime,
        takenTime: takenTime,
        status: status,
        isSynced: isOnline,
      );

      // 2. If offline, flag sync updates needed
      if (!isOnline) {
        state = state.copyWith(offlineSyncNeeded: true);
      }
    } catch (e) {
      // Fail silently
    }
  }

  /// Erases schedule and cancels scheduled alarms.
  Future<void> deleteMedication(String id, String userId) async {
    try {
      await medicationRepository.deleteMedication(id);
      await notificationService.cancelNotification(id);
      await fetchActiveMedications(userId);
    } catch (e) {
      // Fail silently
    }
  }
}

/// Riverpod provider for MedicationController.
final medicationControllerProvider =
    StateNotifierProvider<MedicationController, MedicationState>((ref) {
  final repo = ref.watch(medicationRepositoryProvider);
  final notification = ref.watch(notificationServiceProvider);
  final calendar = ref.watch(calendarServiceProvider);
  return MedicationController(
    medicationRepository: repo,
    notificationService: notification,
    calendarService: calendar,
  );
});
