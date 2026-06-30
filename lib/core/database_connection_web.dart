import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:sqlite3/wasm.dart';

/// IndexedDbFileSystem buffers writes in memory and only persists them to
/// IndexedDB once flush() is called — without this, a page refresh shortly
/// after a write (e.g. saving a notification threshold) can silently lose
/// it. Flushing after every write makes an awaited write durable by the
/// time its Future completes.
class _FlushOnWriteInterceptor extends QueryInterceptor {
  _FlushOnWriteInterceptor(this._fs);
  final IndexedDbFileSystem _fs;

  @override
  Future<int> runInsert(
      QueryExecutor executor, String statement, List<Object?> args) async {
    final result = await super.runInsert(executor, statement, args);
    await _fs.flush();
    return result;
  }

  @override
  Future<int> runUpdate(
      QueryExecutor executor, String statement, List<Object?> args) async {
    final result = await super.runUpdate(executor, statement, args);
    await _fs.flush();
    return result;
  }

  @override
  Future<int> runDelete(
      QueryExecutor executor, String statement, List<Object?> args) async {
    final result = await super.runDelete(executor, statement, args);
    await _fs.flush();
    return result;
  }

  @override
  Future<void> runCustom(
      QueryExecutor executor, String statement, List<Object?> args) async {
    await super.runCustom(executor, statement, args);
    await _fs.flush();
  }

  @override
  Future<void> runBatched(
      QueryExecutor executor, BatchedStatements statements) async {
    await super.runBatched(executor, statements);
    await _fs.flush();
  }
}

QueryExecutor openConnection(String name) {
  return DatabaseConnection.delayed(Future(() async {
    final sqlite3 = await WasmSqlite3.loadFromUrl(Uri.parse('sqlite3.wasm'));
    final fs = await IndexedDbFileSystem.open(dbName: name);
    sqlite3.registerVirtualFileSystem(fs, makeDefault: true);
    final db =
        WasmDatabase(sqlite3: sqlite3, path: '/$name.db', fileSystem: fs);
    return DatabaseConnection(db.interceptWith(_FlushOnWriteInterceptor(fs)));
  }));
}
