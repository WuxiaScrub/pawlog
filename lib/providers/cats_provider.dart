import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/database.dart';
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

  Future<void> addCat({
    required String name,
    String? breed,
    DateTime? dateOfBirth,
    double? weightKg,
  }) {
    return _db.into(_db.cats).insert(
          CatsCompanion.insert(
            id: _uuid.v4(),
            name: name,
            breed: Value(breed),
            dateOfBirth: Value(dateOfBirth),
            weightKg: Value(weightKg),
          ),
        );
  }

  Future<void> updateCat(Cat cat) {
    return _db.update(_db.cats).replace(cat);
  }
}

final catsRepositoryProvider = Provider<CatsRepository>((ref) {
  return CatsRepository(ref.watch(databaseProvider));
});
