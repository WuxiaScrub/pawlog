import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'database.dart';
import 'supabase_client.dart';

class SyncResult {
  final int itemCount;
  const SyncResult(this.itemCount);
}

class SyncService {
  SyncService(this._db);
  final AppDatabase _db;

  static const _storage = FlutterSecureStorage();
  static const _seedKeyPrefix = 'sync_seeded_';

  bool _processing = false;

  final _statusController = StreamController<SyncResult>.broadcast();
  Stream<SyncResult> get statusStream => _statusController.stream;

  Future<void> enqueue({
    required String tableName,
    required String recordId,
    required String operation,
    required Map<String, dynamic> payload,
  }) {
    return _db.into(_db.syncQueue).insert(
          SyncQueueCompanion.insert(
            targetTable: tableName,
            recordId: recordId,
            operation: operation,
            payload: jsonEncode(payload),
          ),
        );
  }

  void triggerSync() {
    if (_processing) return;
    unawaited(_processQueue());
  }

  Future<int> pendingCount() async {
    final result = await _db
        .customSelect('SELECT COUNT(*) AS c FROM sync_queue')
        .getSingle();
    return result.read<int>('c');
  }

  Future<void> _processQueue() async {
    if (_processing) return;

    final user = supabase.auth.currentUser;
    if (user == null) return;

    _processing = true;
    var syncedCount = 0;
    try {
      while (true) {
        final items = await (_db.select(_db.syncQueue)
              ..orderBy([(t) => OrderingTerm.asc(t.id)])
              ..limit(20))
            .get();

        if (items.isEmpty) break;

        for (final item in items) {
          try {
            await _pushItem(item, user.id);
            await (_db.delete(_db.syncQueue)
                  ..where((t) => t.id.equals(item.id)))
                .go();
            syncedCount++;
          } catch (_) {
            if (syncedCount > 0) {
              _statusController.add(SyncResult(syncedCount));
            }
            return;
          }
        }
      }
      if (syncedCount > 0) {
        _statusController.add(SyncResult(syncedCount));
      }
    } finally {
      _processing = false;
    }
  }

  Future<void> _pushItem(SyncQueueItem item, String userId) async {
    final payload = jsonDecode(item.payload) as Map<String, dynamic>;
    payload['user_id'] = userId;

    switch (item.operation) {
      case 'insert' || 'update':
        await supabase.from(item.targetTable).upsert(payload);
      case 'delete':
        await supabase
            .from(item.targetTable)
            .delete()
            .eq('id', item.recordId);
    }
  }

  Future<void> seedIfNeeded(String userId) async {
    final key = '$_seedKeyPrefix$userId';
    final seeded = await _storage.read(key: key);
    if (seeded == 'true') return;

    final cats = await _db.select(_db.cats).get();
    for (final cat in cats) {
      await enqueue(
        tableName: 'cats',
        recordId: cat.id,
        operation: 'insert',
        payload: {
          'id': cat.id,
          'name': cat.name,
          'breed': cat.breed,
          'date_of_birth': cat.dateOfBirth?.toIso8601String(),
          'weight_kg': cat.weightKg,
          'photo_path': cat.photoPath,
          'quick_log_types_json': cat.quickLogTypesJson,
          'screening_done': cat.screeningDone,
          'created_at': cat.createdAt.toIso8601String(),
        },
      );
    }

    final events = await _db.select(_db.events).get();
    for (final event in events) {
      await enqueue(
        tableName: 'events',
        recordId: event.id,
        operation: 'insert',
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
    }

    final settings = await _db.select(_db.notificationSettings).get();
    for (final s in settings) {
      await enqueue(
        tableName: 'notification_settings',
        recordId: s.id,
        operation: 'insert',
        payload: {
          'id': s.id,
          'event_type': s.eventType,
          'threshold_hours': s.thresholdHours,
          'enabled': s.enabled,
        },
      );
    }

    final schedules = await _db.select(_db.feedingSchedules).get();
    for (final s in schedules) {
      await enqueue(
        tableName: 'feeding_schedules',
        recordId: s.id,
        operation: 'insert',
        payload: {
          'id': s.id,
          'cat_id': s.catId,
          'times_per_day': s.timesPerDay,
          'enabled': s.enabled,
          'created_at': s.createdAt.toIso8601String(),
        },
      );
    }

    final slots = await _db.select(_db.feedingSlots).get();
    for (final s in slots) {
      await enqueue(
        tableName: 'feeding_slots',
        recordId: s.id,
        operation: 'insert',
        payload: {
          'id': s.id,
          'schedule_id': s.scheduleId,
          'cat_id': s.catId,
          'label': s.label,
          'hour': s.hour,
          'minute': s.minute,
          'sort_order': s.sortOrder,
        },
      );
    }

    await _storage.write(key: key, value: 'true');
    triggerSync();
  }
}
