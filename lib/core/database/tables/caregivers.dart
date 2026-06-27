import 'package:drift/drift.dart';

class Caregivers extends Table {
  TextColumn get id => text()();
  TextColumn get phone => text().withLength(min: 10, max: 15)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get email => text().nullable()();
  TextColumn get status => text()(); // 'PENDING', 'ACTIVE', 'REVOKED'
  DateTimeColumn get linkedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class CaregiverConsents extends Table {
  TextColumn get id => text()();
  TextColumn get caregiverId => text().references(Caregivers, #id)();
  BoolColumn get shareGps => boolean().withDefault(const Constant(false))();
  BoolColumn get shareMeds => boolean().withDefault(const Constant(false))();
  BoolColumn get shareBattery => boolean().withDefault(const Constant(false))();
  BoolColumn get shareSosHistory => boolean().withDefault(const Constant(true))(); // Default true for safety

  @override
  Set<Column> get primaryKey => {id};
}
