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
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          // Fresh install – create all tables
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // v1 -> v2: add passwordHash column for offline email/password auth
            await m.addColumn(users, users.passwordHash);
          }
          if (from < 3) {
            // v2 -> v3: add userId column to MedicalCards for per-user scoping
            await m.addColumn(medicalCards, medicalCards.userId);
          }
        },
      );

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
