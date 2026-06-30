import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:sqlite3/wasm.dart';

QueryExecutor openConnection(String name) {
  return DatabaseConnection.delayed(Future(() async {
    final sqlite3 = await WasmSqlite3.loadFromUrl(Uri.parse('sqlite3.wasm'));
    final fs = await IndexedDbFileSystem.open(dbName: name);
    sqlite3.registerVirtualFileSystem(fs, makeDefault: true);
    return DatabaseConnection(
      WasmDatabase(sqlite3: sqlite3, path: '/$name.db', fileSystem: fs),
    );
  }));
}
