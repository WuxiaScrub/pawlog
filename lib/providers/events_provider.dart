import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/database.dart';
import '../models/event_type.dart';
import 'database_provider.dart';

const _uuid = Uuid();

final eventsStreamProvider =
    StreamProvider.family<List<Event>, String>((ref, catId) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.events)
        ..where((t) => t.catId.equals(catId))
        ..orderBy([(t) => OrderingTerm.desc(t.loggedAt)]))
      .watch();
});

class EventsRepository {
  EventsRepository(this._db);
  final AppDatabase _db;

  Future<void> logEvent({
    required String catId,
    required CatEventType eventType,
    String? notes,
    Map<String, dynamic>? metadata,
    DateTime? loggedAt,
  }) {
    return _db.into(_db.events).insert(
          EventsCompanion.insert(
            id: _uuid.v4(),
            catId: catId,
            eventType: eventType.storageKey,
            notes: Value(notes),
            metadataJson:
                Value(metadata != null ? jsonEncode(metadata) : null),
            loggedAt: loggedAt != null ? Value(loggedAt) : const Value.absent(),
          ),
        );
  }

  Future<void> updateEvent({
    required String id,
    String? notes,
    Map<String, dynamic>? metadata,
    DateTime? loggedAt,
  }) {
    return (_db.update(_db.events)..where((t) => t.id.equals(id))).write(
          EventsCompanion(
            notes: Value(notes),
            metadataJson: Value(metadata != null ? jsonEncode(metadata) : null),
            loggedAt: loggedAt != null ? Value(loggedAt) : const Value.absent(),
          ),
        );
  }

  Future<void> deleteEvent(String id) {
    return (_db.delete(_db.events)..where((t) => t.id.equals(id))).go();
  }
}

final eventsRepositoryProvider = Provider<EventsRepository>((ref) {
  return EventsRepository(ref.watch(databaseProvider));
});
