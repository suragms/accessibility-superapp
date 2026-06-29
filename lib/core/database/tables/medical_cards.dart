import 'package:drift/drift.dart';

class MedicalCards extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get bloodType => text().withLength(min: 1, max: 5)();
  TextColumn get allergies => text().nullable()();
  TextColumn get medications => text().nullable()();
  TextColumn get emergencyNotes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
