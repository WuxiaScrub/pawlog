import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/database.dart';
import '../core/sync_service.dart';
import '../models/event_type.dart';
import 'database_provider.dart';
import 'sync_provider.dart';

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
  EventsRepository(this._db, this._sync);
  final AppDatabase _db;
  final SyncService _sync;

  Future<String> logEvent({
    required String catId,
    required CatEventType eventType,
    String? notes,
    Map<String, dynamic>? metadata,
    DateTime? loggedAt,
  }) async {
    final id = _uuid.v4();
    final effectiveLoggedAt = loggedAt ?? DateTime.now();
    final now = DateTime.now();
    await _db.into(_db.events).insert(
          EventsCompanion.insert(
            id: id,
            catId: catId,
            eventType: eventType.storageKey,
            notes: Value(notes),
            metadataJson:
                Value(metadata != null ? jsonEncode(metadata) : null),
            loggedAt:
                loggedAt != null ? Value(loggedAt) : const Value.absent(),
          ),
        );
    await _sync.enqueue(
      tableName: 'events',
      recordId: id,
      operation: 'insert',
      payload: {
        'id': id,
        'cat_id': catId,
        'event_type': eventType.storageKey,
        'notes': notes,
        'metadata_json': metadata != null ? jsonEncode(metadata) : null,
        'logged_at': effectiveLoggedAt.toIso8601String(),
        'created_at': now.toIso8601String(),
      },
    );
    _sync.triggerSync();
    return id;
  }

  Future<void> updateEvent({
    required String id,
    String? notes,
    Map<String, dynamic>? metadata,
    DateTime? loggedAt,
  }) async {
    await (_db.update(_db.events)..where((t) => t.id.equals(id))).write(
          EventsCompanion(
            notes: Value(notes),
            metadataJson:
                Value(metadata != null ? jsonEncode(metadata) : null),
            loggedAt:
                loggedAt != null ? Value(loggedAt) : const Value.absent(),
          ),
        );
    final event = await (_db.select(_db.events)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    await _sync.enqueue(
      tableName: 'events',
      recordId: id,
      operation: 'update',
      payload: {
        'id': event.id,
        'cat_id': event.catId,
        'event_type': event.eventType,
        'notes': event.notes,
        'metadata_json': event.metadataJson,
        'logged_at': event.loggedAt.toIso8601String(),
        'created_at': event.createdAt.toIso8601String(),
      },
    );
    _sync.triggerSync();
  }

  Future<void> deleteEvent(String id) async {
    await (_db.delete(_db.events)..where((t) => t.id.equals(id))).go();
    await _sync.enqueue(
      tableName: 'events',
      recordId: id,
      operation: 'delete',
      payload: {},
    );
    _sync.triggerSync();
  }
}

final eventsRepositoryProvider = Provider<EventsRepository>((ref) {
  return EventsRepository(
    ref.watch(databaseProvider),
    ref.watch(syncServiceProvider),
  );
});
