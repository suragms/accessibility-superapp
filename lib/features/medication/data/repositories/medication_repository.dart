import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/models/medication.dart';

/// Database repository executing CRUD and history logging using the Native Drift client.
class MedicationRepository {
  final AppDatabase db;

  MedicationRepository({required this.db});

  /// Inserts a new medicine profile.
  Future<void> addMedication(MedicationModel medication) async {
    await db.into(db.medications).insert(
          MedicationsCompanion.insert(
            id: medication.id,
            userId: medication.userId,
            name: medication.name,
            dosage: medication.dosage,
            cronSchedule: medication.cronSchedule,
            isActive: Value(medication.isActive),
            doctorNotes: Value(medication.doctorNotes),
            voiceReminderPath: Value(medication.voiceReminderPath),
            createdAt: Value(medication.createdAt),
          ),
        );
  }

  /// Silences/deactivates a medication schedule.
  Future<void> deleteMedication(String id) async {
    await (db.update(db.medications)..where((t) => t.id.equals(id)))
        .write(const MedicationsCompanion(isActive: Value(false)));
  }

  /// Appends or updates log compliance history statuses.
  Future<void> logMedicationStatus({
    required String logId,
    required String medicationId,
    required DateTime scheduledTime,
    DateTime? takenTime,
    required String status,
    bool isSynced = false,
  }) async {
    await db.into(db.medicationLogs).insertOnConflictUpdate(
          MedicationLogsCompanion.insert(
            id: logId,
            medicationId: medicationId,
            scheduledTime: scheduledTime,
            takenTime: Value(takenTime),
            status: status,
            isSynced: Value(isSynced),
          ),
        );
  }

  /// Reads active medications.
  Future<List<MedicationModel>> getActiveMedications(String userId) async {
    final query = db.select(db.medications)
      ..where((t) => t.userId.equals(userId) & t.isActive.equals(true));
    final rows = await query.get();

    return rows.map((row) {
      return MedicationModel(
        id: row.id,
        userId: row.userId,
        name: row.name,
        dosage: row.dosage,
        cronSchedule: row.cronSchedule,
        isActive: row.isActive,
        doctorNotes: row.doctorNotes,
        voiceReminderPath: row.voiceReminderPath,
        createdAt: row.createdAt,
      );
    }).toList();
  }

  /// Reads execution compliance logs history for a given medicine.
  Future<List<MedicationLog>> getHistoryLogs(String medicationId) async {
    final query = db.select(db.medicationLogs)
      ..where((t) => t.medicationId.equals(medicationId))
      ..orderBy([(t) => OrderingTerm.desc(t.scheduledTime)]);
    return query.get();
  }
}

/// Riverpod provider for MedicationRepository.
final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return MedicationRepository(db: db);
});
