import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/database.dart';
import '../models/event_type.dart';
import 'database_provider.dart';

const _uuid = Uuid();

final catsStreamProvider = StreamProvider<List<Cat>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.cats)
        ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
      .watch();
});

/// V1 free tier supports exactly one cat, so the rest of the app treats the
/// first created cat as "the" active cat.
final activeCatProvider = Provider<Cat?>((ref) {
  final cats = ref.watch(catsStreamProvider).value;
  if (cats == null || cats.isEmpty) return null;
  return cats.first;
});

class CatsRepository {
  CatsRepository(this._db);
  final AppDatabase _db;

  Future<String> addCat({
    required String name,
    String? breed,
    DateTime? dateOfBirth,
    double? weightKg,
    String? photoPath,
  }) async {
    final id = _uuid.v4();
    await _db.into(_db.cats).insert(
          CatsCompanion.insert(
            id: id,
            name: name,
            breed: Value(breed),
            dateOfBirth: Value(dateOfBirth),
            weightKg: Value(weightKg),
            photoPath: Value(photoPath),
          ),
        );
    return id;
  }

  Future<void> updateCat(Cat cat) {
    return _db.update(_db.cats).replace(cat);
  }

  Future<void> saveQuickLogPreferences({
    required String catId,
    required List<CatEventType> enabledTypes,
  }) {
    final json = jsonEncode(enabledTypes.map((t) => t.storageKey).toList());
    return (_db.update(_db.cats)..where((t) => t.id.equals(catId))).write(
      CatsCompanion(
        quickLogTypesJson: Value(json),
        screeningDone: const Value(true),
      ),
    );
  }
}

/// Decodes a cat's quickLogTypesJson into a set of enabled event types.
/// Returns null when the json is null (meaning "show all").
Set<CatEventType>? decodeQuickLogTypes(String? json) {
  if (json == null) return null;
  final keys = (jsonDecode(json) as List).cast<String>();
  return keys.map(CatEventTypeX.fromStorageKey).toSet();
}

final catsRepositoryProvider = Provider<CatsRepository>((ref) {
  return CatsRepository(ref.watch(databaseProvider));
});
