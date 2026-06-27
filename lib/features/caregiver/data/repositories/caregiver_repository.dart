import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/models/caregiver_profile.dart';

/// Database repository executing Drift joins and privacy queries.
class CaregiverRepository {
  final AppDatabase db;

  CaregiverRepository({required this.db});

  /// Inserts a caregiver invitation and registers default privacy parameters.
  Future<void> inviteCaregiver(Caregiver caregiver, CaregiverConsent consent) async {
    await db.transaction(() async {
      await db.into(db.caregivers).insert(caregiver);
      await db.into(db.caregiverConsents).insert(consent);
    });
  }

  /// Removes caregiver links.
  Future<void> deleteCaregiver(String caregiverId) async {
    await db.transaction(() async {
      await (db.delete(db.caregiverConsents)..where((t) => t.caregiverId.equals(caregiverId))).go();
      await (db.delete(db.caregivers)..where((t) => t.id.equals(caregiverId))).go();
    });
  }

  /// Reads connected caregivers joined with their privacy settings.
  Future<List<CaregiverProfile>> getCaregiverProfiles() async {
    final query = db.select(db.caregivers).join([
      leftOuterJoin(
        db.caregiverConsents,
        db.caregiverConsents.caregiverId.equalsExp(db.caregivers.id),
      ),
    ]);

    final rows = await query.get();

    return rows.map((row) {
      final caregiver = row.readTable(db.caregivers);
      final consent = row.readTableOrNull(db.caregiverConsents);

      return CaregiverProfile(
        caregiverId: caregiver.id,
        name: caregiver.name,
        phone: caregiver.phone,
        email: caregiver.email,
        status: caregiver.status,
        shareGps: consent?.shareGps ?? false,
        shareMeds: consent?.shareMeds ?? false,
        shareBattery: consent?.shareBattery ?? false,
        shareSosHistory: consent?.shareSosHistory ?? true,
      );
    }).toList();
  }

  /// Updates caregiver permission controls.
  Future<void> updatePrivacyConsent({
    required String caregiverId,
    required bool shareGps,
    required bool shareMeds,
    required bool shareBattery,
    required bool shareSosHistory,
  }) async {
    await (db.update(db.caregiverConsents)..where((t) => t.caregiverId.equals(caregiverId)))
        .write(
      CaregiverConsentsCompanion(
        shareGps: Value(shareGps),
        shareMeds: Value(shareMeds),
        shareBattery: Value(shareBattery),
        shareSosHistory: Value(shareSosHistory),
      ),
    );
  }
}

/// Riverpod provider for CaregiverRepository.
final caregiverRepositoryProvider = Provider<CaregiverRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return CaregiverRepository(db: db);
});
