import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'package:accessibility_super_app/core/database/app_database.dart';
import 'package:accessibility_super_app/core/providers/current_user_provider.dart';
import 'package:accessibility_super_app/core/services/hardware_service.dart';
import 'package:accessibility_super_app/core/services/location_service.dart';
import 'package:accessibility_super_app/core/services/shake_service.dart';
import 'package:accessibility_super_app/core/services/tts_service.dart';
import 'package:accessibility_super_app/features/sos/data/repositories/sos_repository.dart';
import 'package:accessibility_super_app/features/sos/presentation/controllers/sos_controller.dart';

/// Mock UrlLauncher platform — intercepts launchUrl calls so we can assert
/// that HardwareService builds the correct `sms:` and `tel:` URIs without
/// touching real platform code.
class MockUrlLauncherPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  final List<String> launchedUrls = [];
  bool _response = true;

  void setResponse(bool response) => _response = response;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => _response;

  @override
  Future<bool> launch(
    String url, {
    required bool useSafariVC,
    required bool useWebView,
    required bool enableJavaScript,
    required bool enableDomStorage,
    required bool universalLinksOnly,
    required Map<String, String> headers,
    String? webOnlyWindowName,
  }) async {
    launchedUrls.add(url);
    return _response;
  }

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launchedUrls.add(url);
    return _response;
  }

  @override
  Future<void> closeWebView() async {}

  @override
  Future<bool> supportsMode(PreferredLaunchMode mode) async => _response;

  @override
  Future<bool> supportsCloseForMode(PreferredLaunchMode mode) async => false;
}

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

/// Mock Hardware dialers — used for controller-level integration tests.
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
  MedicalCard? cardMock = const MedicalCard(id: 'default-medical-card-id', userId: 'test-user', bloodType: 'AB-');

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
  late MockUrlLauncherPlatform mockLauncher;

  setUp(() {
    mockLauncher = MockUrlLauncherPlatform();
    UrlLauncherPlatform.instance = mockLauncher;
  });

  group('HardwareService url_launcher integration', () {
    test('sendSms launches correct sms: URI with URL-encoded body', () async {
      final service = HardwareService();
      final result = await service.sendSms(
        phone: '9876543210',
        message: 'EMERGENCY SOS ALERT! Help needed.',
      );

      expect(result, isTrue);
      expect(mockLauncher.launchedUrls, hasLength(1));

      final launchedUri = Uri.parse(mockLauncher.launchedUrls.first);
      expect(launchedUri.scheme, 'sms');
      expect(launchedUri.path, '9876543210');
      expect(launchedUri.queryParameters['body'], 'EMERGENCY SOS ALERT! Help needed.');
    });

    test('sendSms URL-encodes special characters in message body', () async {
      final service = HardwareService();
      final result = await service.sendSms(
        phone: '5551234567',
        message: 'Lat: 12.9716, Lon: 77.5946 & Battery: 88%',
      );

      expect(result, isTrue);
      final launchedUri = Uri.parse(mockLauncher.launchedUrls.first);
      expect(launchedUri.queryParameters['body'], 'Lat: 12.9716, Lon: 77.5946 & Battery: 88%');
    });

    test('sendSms returns false when launchUrl throws', () async {
      mockLauncher.setResponse(false);
      final service = HardwareService();
      final result = await service.sendSms(
        phone: '123',
        message: 'test',
      );

      expect(result, isFalse);
    });

    test('makeCall launches correct tel: URI', () async {
      final service = HardwareService();
      final result = await service.makeCall(phone: '9876543210');

      expect(result, isTrue);
      expect(mockLauncher.launchedUrls, hasLength(1));
      expect(mockLauncher.launchedUrls.first, 'tel:9876543210');
    });

    test('makeCall returns false when launchUrl throws', () async {
      mockLauncher.setResponse(false);
      final service = HardwareService();
      final result = await service.makeCall(phone: '123');

      expect(result, isFalse);
    });
  });

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
          currentUserIdProvider.overrideWithValue('test-user-id'),
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
          currentUserIdProvider.overrideWithValue('test-user-id'),
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
      expect(tts.spokenLines.first, contains('Opening Messages app'));

      // Verify status message reflects final state
      expect(state.statusMessage, contains('Please confirm sending each message'));
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
          currentUserIdProvider.overrideWithValue('test-user-id'),
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
