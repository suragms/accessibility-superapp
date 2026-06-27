import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import 'package:accessibility_super_app/core/database/app_database.dart';
import 'package:accessibility_super_app/core/services/hardware_service.dart';
import 'package:accessibility_super_app/core/services/location_service.dart';
import 'package:accessibility_super_app/core/services/shake_service.dart';
import 'package:accessibility_super_app/core/services/tts_service.dart';
import 'package:accessibility_super_app/features/sos/data/repositories/sos_repository.dart';
import 'package:accessibility_super_app/features/sos/presentation/controllers/sos_controller.dart';

/// Mock GPS Locator
class MockLocationService extends LocationService {
  @override
  Future<Position> getCurrentPosition() async {
    return Position(
      latitude: 12.9716,
      longitude: 77.5946,
      timestamp: DateTime.now(),
      accuracy: 1.0,
      altitude: 900.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    );
  }
}

/// Mock Hardware dialers
class MockHardwareService extends HardwareService {
  final List<Map<String, String>> sentSmsLogs = [];
  final List<String> callsDialed = [];

  @override
  Future<double> getBatteryLevel() async {
    return 75.0;
  }

  @override
  Future<bool> sendSms({required String phone, required String message}) async {
    sentSmsLogs.add({'phone': phone, 'message': message});
    return true;
  }

  @override
  Future<bool> makeCall({required String phone}) async {
    callsDialed.add(phone);
    return true;
  }
}

/// Mock Database queries
class MockSosRepository implements SosRepository {
  final List<EmergencyContact> contactMocks = [
    const EmergencyContact(id: 'c-01', name: 'John Doe', phone: '9876543210', relationship: 'Spouse', isPrimary: true),
    const EmergencyContact(id: 'c-02', name: 'Dr. Smith', phone: '9999988888', relationship: 'Physician', isPrimary: false),
  ];
  MedicalCard? cardMock = const MedicalCard(id: 'default-medical-card-id', bloodType: 'AB-');

  @override
  AppDatabase get db => throw UnimplementedError();

  @override
  Future<List<EmergencyContact>> getContacts() async {
    return contactMocks;
  }

  @override
  Future<MedicalCard?> getMedicalCard(String cardId) async {
    return cardMock;
  }

  @override
  Future<void> saveContact(EmergencyContact contact) async {
    contactMocks.add(contact);
  }

  @override
  Future<void> deleteContact(String id) async {
    contactMocks.removeWhere((c) => c.id == id);
  }

  @override
  Future<void> saveMedicalCard(MedicalCard card) async {
    cardMock = card;
  }
}

/// Mock Shake service trigger
class MockShakeService extends ShakeService {
  late void Function() shakenTrigger;

  @override
  void startListening({
    required void Function() onPhoneShaken,
    double threshold = 2.7,
  }) {
    shakenTrigger = onPhoneShaken;
  }
}

/// Mock Vocalizer speaker
class MockTtsService implements TtsService {
  final List<String> spokenLines = [];

  @override
  Future<void> speak(String text) async {
    spokenLines.add(text);
  }

  @override
  Future<void> stop() async {
    spokenLines.clear();
  }

  @override
  Future<void> setLanguage(String languageCode) async {}

  @override
  Future<void> setSpeechRate(double rate) async {}
}

void main() {
  group('Emergency SOS Module Unit Tests', () {
    test('Verify initial configurations load successfully', () async {
      final mockRepo = MockSosRepository();
      final location = MockLocationService();
      final hardware = MockHardwareService();
      final shake = MockShakeService();
      final tts = MockTtsService();

      final container = ProviderContainer(
        overrides: [
          sosRepositoryProvider.overrideWithValue(mockRepo),
          locationServiceProvider.overrideWithValue(location),
          hardwareServiceProvider.overrideWithValue(hardware),
          shakeServiceProvider.overrideWithValue(shake),
          ttsServiceProvider.overrideWithValue(tts),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(sosControllerProvider.notifier);
      await controller.loadDetails();

      final state = container.read(sosControllerProvider);

      expect(state.contacts, hasLength(2));
      expect(state.medicalCard?.bloodType, equals('AB-'));
      expect(state.batteryLevel, equals(75.0));
      expect(state.isSosTriggered, isFalse);
    });

    test('Verify SOS trigger dispatches SMS, calls primary, and speaks audio notifications', () async {
      final mockRepo = MockSosRepository();
      final location = MockLocationService();
      final hardware = MockHardwareService();
      final shake = MockShakeService();
      final tts = MockTtsService();

      final container = ProviderContainer(
        overrides: [
          sosRepositoryProvider.overrideWithValue(mockRepo),
          locationServiceProvider.overrideWithValue(location),
          hardwareServiceProvider.overrideWithValue(hardware),
          shakeServiceProvider.overrideWithValue(shake),
          ttsServiceProvider.overrideWithValue(tts),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(sosControllerProvider.notifier);
      await controller.loadDetails();

      // Trigger Emergency rescue cycle
      await controller.triggerEmergencySos();

      final state = container.read(sosControllerProvider);

      // Verify locations and states
      expect(state.isSosTriggered, isTrue);
      expect(state.lastKnownLocation, contains('12.9716'));

      // Verify SMS dispatched to all registered contacts
      expect(hardware.sentSmsLogs, hasLength(2));
      expect(hardware.sentSmsLogs.first['message'], contains('12.9716'));

      // Verify primary contact was dialed
      expect(hardware.callsDialed, hasLength(1));
      expect(hardware.callsDialed.first, equals('9876543210'));

      // Verify spoken rescue alert announcement was voiced
      expect(tts.spokenLines, hasLength(1));
      expect(tts.spokenLines.first, contains('Caregivers are being contacted'));
    });

    test('Verify physical accelerometer shake gesture triggers emergency sequences', () async {
      final mockRepo = MockSosRepository();
      final location = MockLocationService();
      final hardware = MockHardwareService();
      final shake = MockShakeService();
      final tts = MockTtsService();

      final container = ProviderContainer(
        overrides: [
          sosRepositoryProvider.overrideWithValue(mockRepo),
          locationServiceProvider.overrideWithValue(location),
          hardwareServiceProvider.overrideWithValue(hardware),
          shakeServiceProvider.overrideWithValue(shake),
          ttsServiceProvider.overrideWithValue(tts),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(sosControllerProvider.notifier);
      await controller.loadDetails();

      // Mimics phone shaken gesture
      shake.shakenTrigger();
      await Future.delayed(const Duration(milliseconds: 10));

      final state = container.read(sosControllerProvider);
      expect(state.isSosTriggered, isTrue);
      expect(hardware.sentSmsLogs, hasLength(2));
    });
  });
}
