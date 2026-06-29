import 'dart:async';
import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// Opens a drift database on the web using WebAssembly-based SQLite.
///
/// Requires `sqlite3.wasm` and `drift_worker.js` in the `web/` directory.
/// These files are version-matched to the drift and sqlite3 dependencies.
QueryExecutor openConnection() {
  return DatabaseConnection.delayed(
    Future(() async {
      final result = await WasmDatabase.open(
        databaseName: 'app_database',
        sqlite3Uri: Uri.parse('sqlite3.wasm'),
        driftWorkerUri: Uri.parse('drift_worker.js'),
      );

      return result.resolvedExecutor;
    }),
  );
}
