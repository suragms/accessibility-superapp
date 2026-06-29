import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:accessibility_super_app/core/database/app_database.dart';
import 'package:accessibility_super_app/core/services/hardware_service.dart';
import 'package:accessibility_super_app/features/caregiver/data/repositories/caregiver_repository.dart';
import 'package:accessibility_super_app/features/caregiver/domain/models/caregiver_profile.dart';
import 'package:accessibility_super_app/features/caregiver/presentation/controllers/caregiver_controller.dart';

/// Mock Database queries to decouple SQLite execution.
class MockCaregiverRepository implements CaregiverRepository {
  final List<CaregiverProfile> profileMocks = [
    const CaregiverProfile(
      caregiverId: 'cg-77',
      name: 'Jane Doe',
      phone: '9876543210',
      status: 'ACTIVE',
      shareGps: true,
      shareMeds: false,
      shareBattery: true,
      shareSosHistory: true,
    ),
  ];

  @override
  AppDatabase get db => throw UnimplementedError();

  @override
  Future<List<CaregiverProfile>> getCaregiverProfiles() async {
    return profileMocks;
  }

  @override
  Future<void> inviteCaregiver(Caregiver caregiver, CaregiverConsent consent) async {
    profileMocks.add(
      CaregiverProfile(
        caregiverId: caregiver.id,
        name: caregiver.name,
        phone: caregiver.phone,
        status: caregiver.status,
        shareGps: consent.shareGps,
        shareMeds: consent.shareMeds,
        shareBattery: consent.shareBattery,
        shareSosHistory: consent.shareSosHistory,
      ),
    );
  }

  @override
  Future<void> updatePrivacyConsent({
    required String caregiverId,
    required bool shareGps,
    required bool shareMeds,
    required bool shareBattery,
    required bool shareSosHistory,
  }) async {
    final index = profileMocks.indexWhere((p) => p.caregiverId == caregiverId);
    if (index != -1) {
      final old = profileMocks[index];
      profileMocks[index] = CaregiverProfile(
        caregiverId: old.caregiverId,
        name: old.name,
        phone: old.phone,
        status: old.status,
        shareGps: shareGps,
        shareMeds: shareMeds,
        shareBattery: shareBattery,
        shareSosHistory: shareSosHistory,
      );
    }
  }

  @override
  Future<void> deleteCaregiver(String caregiverId) async {
    profileMocks.removeWhere((p) => p.caregiverId == caregiverId);
  }
}

void main() {
  group('CaregiverModule Unit Tests', () {
    test('Verify CaregiverProfile entity copies overrides', () {
      const profile = CaregiverProfile(
        caregiverId: 'cg-01',
        name: 'Jane',
        phone: '123',
        status: 'ACTIVE',
        shareGps: false,
        shareMeds: false,
        shareBattery: false,
        shareSosHistory: false,
      );

      final updated = profile.copyWith(shareGps: true, shareBattery: true);
      expect(updated.shareGps, isTrue);
      expect(updated.shareBattery, isTrue);
      expect(updated.shareMeds, isFalse); // Unchanged
    });

    test('Verify CaregiverController invite pipeline', () async {
      final mockRepo = MockCaregiverRepository();
      final hardware = HardwareService();

      final container = ProviderContainer(
        overrides: [
          caregiverRepositoryProvider.overrideWithValue(mockRepo),
          hardwareServiceProvider.overrideWithValue(hardware),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(caregiverControllerProvider.notifier);
      await controller.loadCaregivers();

      expect(container.read(caregiverControllerProvider).caregivers, hasLength(1));

      // Invite a caregiver
      await controller.inviteCaregiver(name: 'Caregiver Bob', phone: '9999988888');

      // Assert caregiver is added and defaults shareGps to false (privacy-first)
      final list = container.read(caregiverControllerProvider).caregivers;
      expect(list, hasLength(2));
      
      final bob = list.firstWhere((p) => p.name == 'Caregiver Bob');
      expect(bob.status, equals('PENDING'));
      expect(bob.shareGps, isFalse);
    });

    test('Verify privacy consents permissions updates', () async {
      final mockRepo = MockCaregiverRepository();
      final hardware = HardwareService();

      final container = ProviderContainer(
        overrides: [
          caregiverRepositoryProvider.overrideWithValue(mockRepo),
          hardwareServiceProvider.overrideWithValue(hardware),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(caregiverControllerProvider.notifier);
      await controller.loadCaregivers();

      // Verify initial consents of Jane
      var list = container.read(caregiverControllerProvider).caregivers;
      expect(list.first.shareMeds, isFalse);

      // Allow medication logs access
      await controller.updatePermissions(
        caregiverId: 'cg-77',
        shareGps: true,
        shareMeds: true,
        shareBattery: true,
        shareSosHistory: true,
      );

      // Assert modifications
      list = container.read(caregiverControllerProvider).caregivers;
      expect(list.first.shareMeds, isTrue);
    });
  });
}
