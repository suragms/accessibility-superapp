import 'package:drift/drift.dart';

class EmergencyContacts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get phone => text().withLength(min: 10, max: 15)();
  TextColumn get relationship => text().withLength(min: 1, max: 50)();
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
