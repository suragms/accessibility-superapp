import 'package:drift/drift.dart';

class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get endpoint => text()();
  TextColumn get httpMethod => text()(); // 'POST', 'PUT', 'DELETE', etc.
  TextColumn get payloadJson => text()(); // Serialized body of the request
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
}
