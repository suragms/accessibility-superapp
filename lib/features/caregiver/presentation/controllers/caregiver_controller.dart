import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/services/hardware_service.dart';
import '../../data/repositories/caregiver_repository.dart';
import '../../domain/models/caregiver_profile.dart';

class CaregiverState {
  final List<CaregiverProfile> caregivers;
  final List<CaregiverActivityEvent> timelineEvents;
  final bool isLoading;
  final String? errorMessage;

  const CaregiverState({
    required this.caregivers,
    required this.timelineEvents,
    required this.isLoading,
    this.errorMessage,
  });

  CaregiverState copyWith({
    List<CaregiverProfile>? caregivers,
    List<CaregiverActivityEvent>? timelineEvents,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CaregiverState(
      caregivers: caregivers ?? this.caregivers,
      timelineEvents: timelineEvents ?? this.timelineEvents,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, // Reset if null
    );
  }
}

/// State notifier driving caregiver connection states, consents restrictions, and activity histories.
class CaregiverController extends StateNotifier<CaregiverState> {
  final CaregiverRepository caregiverRepository;
  final HardwareService hardwareService;

  CaregiverController({
    required this.caregiverRepository,
    required this.hardwareService,
  }) : super(const CaregiverState(
          caregivers: [],
          timelineEvents: [],
          isLoading: false,
        )) {
    loadCaregivers();
    loadTimeline();
  }

  /// Reads connected profiles.
  Future<void> loadCaregivers() async {
    state = state.copyWith(isLoading: true);
    try {
      final list = await caregiverRepository.getCaregiverProfiles();
      state = state.copyWith(caregivers: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Sends caregiver connection requests (stores PENDING caregiver node + defaults consents).
  Future<void> inviteCaregiver({
    required String name,
    required String phone,
    String? email,
  }) async {
    state = state.copyWith(isLoading: true);
    final caregiverId = const Uuid().v4();
    final consentId = const Uuid().v4();

    final caregiver = Caregiver(
      id: caregiverId,
      name: name,
      phone: phone,
      email: email,
      status: 'PENDING',
      linkedAt: DateTime.now(),
    );

    final consent = CaregiverConsent(
      id: consentId,
      caregiverId: caregiverId,
      shareGps: false,
      shareMeds: false,
      shareBattery: false,
      shareSosHistory: true, // Default to true for emergency backup
    );

    try {
      await caregiverRepository.inviteCaregiver(caregiver, consent);
      await loadCaregivers();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Modifies granular data access settings.
  Future<void> updatePermissions({
    required String caregiverId,
    required bool shareGps,
    required bool shareMeds,
    required bool shareBattery,
    required bool shareSosHistory,
  }) async {
    try {
      await caregiverRepository.updatePrivacyConsent(
        caregiverId: caregiverId,
        shareGps: shareGps,
        shareMeds: shareMeds,
        shareBattery: shareBattery,
        shareSosHistory: shareSosHistory,
      );
      await loadCaregivers();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Permission update failed: ${e.toString()}');
    }
  }

  /// Erases caregiver linkages.
  Future<void> deleteCaregiver(String caregiverId) async {
    try {
      await caregiverRepository.deleteCaregiver(caregiverId);
      await loadCaregivers();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete caregiver: ${e.toString()}');
    }
  }

  /// Compiles a chronological timeline of recent critical logs.
  Future<void> loadTimeline() async {
    final now = DateTime.now();
    // Simulate reading SQLite logs filtered by privacy consents.
    // In production, pulls rows from database query merges.
    final events = [
      CaregiverActivityEvent(
        id: 't-01',
        timestamp: now.subtract(const Duration(minutes: 30)),
        title: 'Medication Dosed',
        description: 'Aspirin (1 Pill) marked as TAKEN by user.',
        type: 'MEDICATION',
      ),
      CaregiverActivityEvent(
        id: 't-02',
        timestamp: now.subtract(const Duration(hours: 3)),
        title: 'Battery Alert',
        description: 'Device battery level reported low: 18%.',
        type: 'BATTERY',
      ),
      CaregiverActivityEvent(
        id: 't-03',
        timestamp: now.subtract(const Duration(days: 1)),
        title: 'SOS Alert Triggered',
        description: 'Emergency SOS initiated via physical Shake detection gesture.',
        type: 'SOS',
      ),
    ];
    state = state.copyWith(timelineEvents: events);
  }
}

/// Riverpod provider for CaregiverController.
final caregiverControllerProvider =
    StateNotifierProvider<CaregiverController, CaregiverState>((ref) {
  final repo = ref.watch(caregiverRepositoryProvider);
  final hardware = ref.watch(hardwareServiceProvider);
  return CaregiverController(
    caregiverRepository: repo,
    hardwareService: hardware,
  );
});
