import 'package:drift/drift.dart';

class Users extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100).nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get token => text().nullable()(); // Saved OAuth/JWT session token
  IntColumn get batteryLevel => integer().withDefault(const Constant(100))();
  TextColumn get pinHash => text().nullable()(); // Encrypted application lock PIN
  TextColumn get passwordHash => text().nullable()(); // Offline password verification

  @override
  Set<Column> get primaryKey => {id};
}
