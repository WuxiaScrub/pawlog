import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'database.dart';
import 'photo_cloud.dart';
import 'supabase_client.dart';

class SyncResult {
  final int itemCount;
  final int photosUploaded;
  const SyncResult(this.itemCount, {this.photosUploaded = 0});
}

class SyncService {
  SyncService(this._db);
  final AppDatabase _db;

  static const _storage = FlutterSecureStorage();
  static const _seedKeyPrefix = 'sync_seeded_';

  bool _processing = false;
  final _waiters = <Completer<SyncResult>>[];

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

  Future<SyncResult> triggerSyncAndWait() {
    final completer = Completer<SyncResult>();
    _waiters.add(completer);
    if (!_processing) {
      unawaited(_processQueue());
    }
    return completer.future;
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
    if (user == null) {
      _completeWaiters(const SyncResult(0));
      return;
    }

    _processing = true;
    var syncedCount = 0;
    var photosUploaded = 0;
    try {
      photosUploaded = await _reuploadLocalPhotos();

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
            _completeWaiters(
              SyncResult(syncedCount, photosUploaded: photosUploaded),
            );
            return;
          }
        }
      }
      _completeWaiters(
        SyncResult(syncedCount, photosUploaded: photosUploaded),
      );
    } finally {
      _processing = false;
    }
  }

  void _completeWaiters(SyncResult result) {
    _statusController.add(result);
    for (final c in _waiters) {
      c.complete(result);
    }
    _waiters.clear();
  }

  /// Re-uploads cat/event photos that are stored as data: URIs instead of
  /// cloud URLs. Returns the number of photos successfully uploaded.
  Future<int> _reuploadLocalPhotos() async {
    var count = 0;

    final cats = await _db.select(_db.cats).get();
    for (final cat in cats) {
      final path = cat.photoPath;
      if (path == null || path.isEmpty || path.startsWith('http')) continue;

      final cloudUrl = await _tryUploadDataUri(path);
      if (cloudUrl == null) continue;

      await (_db.update(_db.cats)..where((t) => t.id.equals(cat.id)))
          .write(CatsCompanion(photoPath: Value(cloudUrl)));
      await enqueue(
        tableName: 'cats',
        recordId: cat.id,
        operation: 'update',
        payload: {
          'id': cat.id,
          'name': cat.name,
          'breed': cat.breed,
          'date_of_birth': cat.dateOfBirth?.toIso8601String(),
          'weight_kg': cat.weightKg,
          'photo_path': cloudUrl,
          'quick_log_types_json': cat.quickLogTypesJson,
          'screening_done': cat.screeningDone,
          'created_at': cat.createdAt.toIso8601String(),
        },
      );
      count++;
    }

    final events = await _db.select(_db.events).get();
    for (final event in events) {
      if (event.metadataJson == null) continue;
      final metadata =
          jsonDecode(event.metadataJson!) as Map<String, dynamic>;
      final photoPath = metadata['photo_path'] as String?;
      if (photoPath == null || photoPath.startsWith('http')) continue;

      final cloudUrl = await _tryUploadDataUri(photoPath);
      if (cloudUrl == null) continue;

      metadata['photo_path'] = cloudUrl;
      final updatedJson = jsonEncode(metadata);
      await (_db.update(_db.events)..where((t) => t.id.equals(event.id)))
          .write(EventsCompanion(metadataJson: Value(updatedJson)));
      await enqueue(
        tableName: 'events',
        recordId: event.id,
        operation: 'update',
        payload: {
          'id': event.id,
          'cat_id': event.catId,
          'event_type': event.eventType,
          'notes': event.notes,
          'metadata_json': updatedJson,
          'logged_at': event.loggedAt.toIso8601String(),
          'created_at': event.createdAt.toIso8601String(),
        },
      );
      count++;
    }

    return count;
  }

  Future<String?> _tryUploadDataUri(String path) async {
    if (!path.startsWith('data:')) return null;
    try {
      final base64Data = path.substring(path.indexOf(',') + 1);
      final bytes = Uint8List.fromList(base64Decode(base64Data));
      final mimeType = path.substring(5, path.indexOf(';'));
      final ext = switch (mimeType) {
        'image/png' => '.png',
        'image/gif' => '.gif',
        'image/webp' => '.webp',
        _ => '.jpg',
      };
      return await uploadPhotoToCloud(bytes, ext);
    } catch (_) {
      return null;
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
