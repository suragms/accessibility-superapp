import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:uuid/uuid.dart';

import 'package:accessibility_super_app/core/database/app_database.dart';

void main() {
  group('Database Stress & Performance Tests', () {
    late AppDatabase database;

    setUp(() {
      // Initialize an in-memory sqlite connection for lightning fast tests
      database = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    test('Verify performance of rapid CRUD inserts batch transaction loop', () async {
      // Insert user row for foreign key integrity
      await database.into(database.users).insert(
        const User(id: 'stress-user', batteryLevel: 100),
      );

      final stopwatch = Stopwatch()..start();

      const insertsCount = 500;
      final uuid = const Uuid();

      // Execute bulk writes inside a Drift batch operation to maximize performance
      await database.batch((batch) {
        for (int i = 0; i < insertsCount; i++) {
          batch.insert(
            database.medications,
            MedicationsCompanion.insert(
              id: uuid.v4(),
              userId: 'stress-user',
              name: 'Stress Test Med $i',
              dosage: '1 Pill',
              cronSchedule: 'DAILY',
            ),
          );
        }
      });

      stopwatch.stop();
      final elapsedMs = stopwatch.elapsedMilliseconds;

      // ignore: avoid_print
      print('Database Batch Insert Performance: Completed $insertsCount inserts in $elapsedMs ms');

      // Assert that 500 records batch write takes less than 300ms in memory
      expect(elapsedMs, lessThan(300));

      // Assert total rows count in the database matches expectation
      final list = await database.select(database.medications).get();
      expect(list, hasLength(insertsCount));
    });
  });
}
