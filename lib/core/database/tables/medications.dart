import 'package:drift/drift.dart';
import 'users.dart';

class Medications extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(Users, #id)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get dosage => text().withLength(min: 1, max: 100)();
  TextColumn get cronSchedule => text()(); // Cron expression for scheduling (e.g. daily, twice daily)
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get doctorNotes => text().nullable()();
  TextColumn get voiceReminderPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class MedicationLogs extends Table {
  TextColumn get id => text()();
  TextColumn get medicationId => text().references(Medications, #id)();
  DateTimeColumn get scheduledTime => dateTime()();
  DateTimeColumn get takenTime => dateTime().nullable()();
  TextColumn get status => text()(); // 'TAKEN', 'MISSED', 'SNOOZED'
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
