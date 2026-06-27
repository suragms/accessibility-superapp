import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/services/hardware_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/shake_service.dart';
import '../../../../core/services/tts_service.dart';
import '../../data/repositories/sos_repository.dart';

class SosState {
  final List<EmergencyContact> contacts;
  final MedicalCard? medicalCard;
  final bool isSosTriggered;
  final String? lastKnownLocation;
  final double batteryLevel;
  final String? statusMessage;

  const SosState({
    required this.contacts,
    this.medicalCard,
    required this.isSosTriggered,
    this.lastKnownLocation,
    required this.batteryLevel,
    this.statusMessage,
  });

  SosState copyWith({
    List<EmergencyContact>? contacts,
    MedicalCard? medicalCard,
    bool? isSosTriggered,
    String? lastKnownLocation,
    double? batteryLevel,
    String? statusMessage,
  }) {
    return SosState(
      contacts: contacts ?? this.contacts,
      medicalCard: medicalCard ?? this.medicalCard,
      isSosTriggered: isSosTriggered ?? this.isSosTriggered,
      lastKnownLocation: lastKnownLocation ?? this.lastKnownLocation,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      statusMessage: statusMessage, // Reset if null
    );
  }
}

/// State notifier orchestrating emergency signals, hardware trackers, and voice warnings.
class SosController extends StateNotifier<SosState> {
  final SosRepository sosRepository;
  final LocationService locationService;
  final HardwareService hardwareService;
  final ShakeService shakeService;
  final TtsService ttsService;

  SosController({
    required this.sosRepository,
    required this.locationService,
    required this.hardwareService,
    required this.shakeService,
    required this.ttsService,
  }) : super(const SosState(
          contacts: [],
          isSosTriggered: false,
          batteryLevel: 100.0,
        )) {
    loadDetails();
    registerShakeDetection();
  }

  /// Loads stored contacts, health parameters, and battery levels.
  Future<void> loadDetails() async {
    final contactsList = await sosRepository.getContacts();
    final card = await sosRepository.getMedicalCard('default-medical-card-id');
    final battery = await hardwareService.getBatteryLevel();

    state = state.copyWith(
      contacts: contactsList,
      medicalCard: card,
      batteryLevel: battery,
    );
  }

  /// Sets up hardware accelerometer gesture listeners.
  void registerShakeDetection() {
    shakeService.startListening(
      onPhoneShaken: () {
        triggerEmergencySos();
      },
    );
  }

  /// Triggers full Emergency rescue sequences (calls, SMS, vocalization, GPS trackers).
  Future<void> triggerEmergencySos({bool isVoiceTrigger = false}) async {
    state = state.copyWith(isSosTriggered: true, statusMessage: 'SOS Alert Triggered!');

    // 1. Resolve GPS coordinates
    String coordinates = 'Location unavailable';
    try {
      final pos = await locationService.getCurrentPosition();
      coordinates = 'Lat: ${pos.latitude.toStringAsFixed(4)}, Lon: ${pos.longitude.toStringAsFixed(4)}';
      state = state.copyWith(lastKnownLocation: coordinates);
    } catch (e) {
      // Fallback
    }

    // 2. Announce loud voice notifications
    await ttsService.speak('Emergency SOS activated. Caregivers are being contacted with your live location.');

    // 3. Dispatch SMS alerts to emergency contacts
    final alertMsg = 'EMERGENCY SOS ALERT! User requires assistance. Battery: ${state.batteryLevel}%. Location: $coordinates';
    for (final contact in state.contacts) {
      await hardwareService.sendSms(phone: contact.phone, message: alertMsg);
    }

    // 4. Dial primary contact
    final primary = state.contacts.firstWhere(
      (c) => c.isPrimary,
      orElse: () => state.contacts.isNotEmpty ? state.contacts.first : const EmergencyContact(id: '', name: '', phone: '', relationship: '', isPrimary: false),
    );

    if (primary.phone.isNotEmpty) {
      await hardwareService.makeCall(phone: primary.phone);
    }
  }

  /// Deactivates active emergency status alerts.
  void cancelEmergencySos() {
    state = state.copyWith(isSosTriggered: false, statusMessage: null);
    ttsService.stop();
  }

  /// Appends contacts database entries.
  Future<void> addContact({
    required String name,
    required String phone,
    required String relationship,
    bool isPrimary = false,
  }) async {
    final contact = EmergencyContact(
      id: const Uuid().v4(),
      name: name,
      phone: phone,
      relationship: relationship,
      isPrimary: isPrimary,
    );
    await sosRepository.saveContact(contact);
    await loadDetails();
  }

  /// Removes contacts database entries.
  Future<void> deleteContact(String id) async {
    await sosRepository.deleteContact(id);
    await loadDetails();
  }

  /// Updates profile details.
  Future<void> saveMedicalCard({
    required String bloodType,
    String? allergies,
    String? medications,
    String? notes,
  }) async {
    final card = MedicalCard(
      id: 'default-medical-card-id',
      bloodType: bloodType,
      allergies: allergies,
      medications: medications,
      emergencyNotes: notes,
    );
    await sosRepository.saveMedicalCard(card);
    await loadDetails();
  }

  @override
  void dispose() {
    shakeService.stopListening();
    super.dispose();
  }
}

/// Riverpod provider for SosController.
final sosControllerProvider =
    StateNotifierProvider<SosController, SosState>((ref) {
  final repo = ref.watch(sosRepositoryProvider);
  final location = ref.watch(locationServiceProvider);
  final hardware = ref.watch(hardwareServiceProvider);
  final shake = ref.watch(shakeServiceProvider);
  final tts = ref.watch(ttsServiceProvider);
  return SosController(
    sosRepository: repo,
    locationService: location,
    hardwareService: hardware,
    shakeService: shake,
    ttsService: tts,
  );
});
