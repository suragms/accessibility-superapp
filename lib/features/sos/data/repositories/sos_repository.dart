import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';

/// Database repository managing Emergency Contacts registry and Medical Card profiles.
class SosRepository {
  final AppDatabase db;

  SosRepository({required this.db});

  /// Inserts or updates emergency contact records.
  Future<void> saveContact(EmergencyContact contact) async {
    await db.into(db.emergencyContacts).insertOnConflictUpdate(contact);
  }

  /// Removes contacts profiles.
  Future<void> deleteContact(String id) async {
    await (db.delete(db.emergencyContacts)..where((t) => t.id.equals(id))).go();
  }

  /// Reads registered contacts.
  Future<List<EmergencyContact>> getContacts() async {
    return db.select(db.emergencyContacts).get();
  }

  /// Inserts or updates medical health logs for a specific user.
  Future<void> saveMedicalCard(MedicalCard card) async {
    await db.into(db.medicalCards).insertOnConflictUpdate(card);
  }

  /// Reads medical records for a specific user.
  /// Returns the most recent medical card for the given [userId].
  Future<MedicalCard?> getMedicalCard(String userId) async {
    final query = db.select(db.medicalCards)
      ..where((t) => t.userId.equals(userId));
    return query.getSingleOrNull();
  }
}

/// Riverpod provider for SosRepository.
final sosRepositoryProvider = Provider<SosRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return SosRepository(db: db);
});
