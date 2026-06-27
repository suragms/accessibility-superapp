import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'connection/connection_stub.dart'
    if (dart.library.io) 'connection/native.dart'
    if (dart.library.html) 'connection/web.dart' as conn;

import 'tables/users.dart';
import 'tables/medications.dart';
import 'tables/caregivers.dart';
import 'tables/sync_queue.dart';
import 'tables/emergency_contacts.dart';
import 'tables/medical_cards.dart';

part 'app_database.g.dart';

/// Database instance running with Native SQLite for local performance.
/// Designed for offline-first caching of safety-critical data.
@DriftDatabase(tables: [
  Users,
  Medications,
  MedicationLogs,
  Caregivers,
  CaregiverConsents,
  SyncQueue,
  EmergencyContacts,
  MedicalCards,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? conn.openConnection());

  @override
  int get schemaVersion => 1;

  // Transaction support for offline sync commits
  Future<void> syncOfflineLogs(List<MedicationLog> logs) async {
    await transaction(() async {
      for (final log in logs) {
        await (update(medicationLogs)..where((t) => t.id.equals(log.id)))
            .write(const MedicationLogsCompanion(isSynced: Value(true)));
      }
    });
  }
}



// Riverpod provider for the central database.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});
