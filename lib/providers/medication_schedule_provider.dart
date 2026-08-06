import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/database.dart';
import '../core/sync_service.dart';
import 'database_provider.dart';
import 'events_provider.dart';
import 'sync_provider.dart';

const _uuid = Uuid();

final medicationSchedulesStreamProvider =
    StreamProvider.family<List<MedicationSchedule>, String>((ref, catId) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.medicationSchedules)
        ..where((t) => t.catId.equals(catId))
        ..orderBy([
          (t) => OrderingTerm.asc(t.hour),
          (t) => OrderingTerm.asc(t.minute),
        ]))
      .watch();
});

class MedicationDoseStatus {
  const MedicationDoseStatus({required this.schedule, required this.takenAt});
  final MedicationSchedule schedule;
  final DateTime? takenAt;

  bool get isTaken => takenAt != null;
}

final todaysMedicationStatusProvider =
    Provider.family<AsyncValue<List<MedicationDoseStatus>>, String>(
        (ref, catId) {
  final schedulesAsync = ref.watch(medicationSchedulesStreamProvider(catId));
  final eventsAsync = ref.watch(eventsStreamProvider(catId));

  return schedulesAsync.when(
    data: (schedules) {
      if (schedules.isEmpty) return const AsyncValue.data([]);

      if (eventsAsync.isLoading) return const AsyncValue.loading();
      if (eventsAsync.hasError) {
        return AsyncValue.error(eventsAsync.error!, eventsAsync.stackTrace!);
      }

      final events = eventsAsync.value ?? [];
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      final activeSchedules = schedules.where((s) {
        if (!s.enabled) return false;
        if (s.endDate != null && s.endDate!.isBefore(todayStart)) return false;
        if (s.startDate.isAfter(now)) return false;

        if (s.recurrence == 'every_n_days' && s.intervalDays > 1) {
          final daysSinceStart =
              todayStart.difference(DateTime(
                s.startDate.year, s.startDate.month, s.startDate.day,
              )).inDays;
          if (daysSinceStart % s.intervalDays != 0) return false;
        }
        return true;
      }).toList();

      final takenByScheduleId = <String, DateTime>{};
      for (final event in events) {
        if (event.eventType != 'medication') continue;
        if (event.loggedAt.isBefore(todayStart)) continue;
        final meta = event.metadataJson;
        if (meta == null) continue;
        final scheduleId = _extractScheduleId(meta);
        if (scheduleId == null) continue;
        final existing = takenByScheduleId[scheduleId];
        if (existing == null || event.loggedAt.isAfter(existing)) {
          takenByScheduleId[scheduleId] = event.loggedAt;
        }
      }

      return AsyncValue.data([
        for (final schedule in activeSchedules)
          MedicationDoseStatus(
            schedule: schedule,
            takenAt: takenByScheduleId[schedule.id],
          ),
      ]);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

String? _extractScheduleId(String metadataJson) {
  try {
    final map = jsonDecode(metadataJson) as Map<String, dynamic>;
    return map['schedule_id'] as String?;
  } catch (_) {
    return null;
  }
}

class MedicationScheduleRepository {
  MedicationScheduleRepository(this._db, this._sync);
  final AppDatabase _db;
  final SyncService _sync;

  Future<void> addSchedule({
    required String catId,
    required String name,
    String? dosage,
    required int hour,
    required int minute,
    String recurrence = 'daily',
    int intervalDays = 1,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    await _db.into(_db.medicationSchedules).insert(
          MedicationSchedulesCompanion.insert(
            id: id,
            catId: catId,
            name: name,
            dosage: Value(dosage),
            hour: hour,
            minute: minute,
            recurrence: Value(recurrence),
            intervalDays: Value(intervalDays),
            startDate: startDate,
            endDate: Value(endDate),
          ),
        );
    await _sync.enqueue(
      tableName: 'medication_schedules',
      recordId: id,
      operation: 'insert',
      payload: {
        'id': id,
        'cat_id': catId,
        'name': name,
        'dosage': dosage,
        'hour': hour,
        'minute': minute,
        'recurrence': recurrence,
        'interval_days': intervalDays,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'enabled': true,
        'created_at': now.toIso8601String(),
      },
    );
    _sync.triggerSync();
  }

  Future<void> updateSchedule({
    required String id,
    String? name,
    String? dosage,
    int? hour,
    int? minute,
    String? recurrence,
    int? intervalDays,
    DateTime? startDate,
    DateTime? endDate,
    bool? enabled,
  }) async {
    await (_db.update(_db.medicationSchedules)
          ..where((t) => t.id.equals(id)))
        .write(
      MedicationSchedulesCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        dosage: dosage != null ? Value(dosage) : const Value.absent(),
        hour: hour != null ? Value(hour) : const Value.absent(),
        minute: minute != null ? Value(minute) : const Value.absent(),
        recurrence:
            recurrence != null ? Value(recurrence) : const Value.absent(),
        intervalDays:
            intervalDays != null ? Value(intervalDays) : const Value.absent(),
        startDate:
            startDate != null ? Value(startDate) : const Value.absent(),
        endDate: endDate != null ? Value(endDate) : const Value.absent(),
        enabled: enabled != null ? Value(enabled) : const Value.absent(),
      ),
    );
    final record = await (_db.select(_db.medicationSchedules)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    await _sync.enqueue(
      tableName: 'medication_schedules',
      recordId: id,
      operation: 'update',
      payload: {
        'id': record.id,
        'cat_id': record.catId,
        'name': record.name,
        'dosage': record.dosage,
        'hour': record.hour,
        'minute': record.minute,
        'recurrence': record.recurrence,
        'interval_days': record.intervalDays,
        'start_date': record.startDate.toIso8601String(),
        'end_date': record.endDate?.toIso8601String(),
        'enabled': record.enabled,
        'created_at': record.createdAt.toIso8601String(),
      },
    );
    _sync.triggerSync();
  }

  Future<void> deleteSchedule(String id) async {
    await (_db.delete(_db.medicationSchedules)
          ..where((t) => t.id.equals(id)))
        .go();
    await _sync.enqueue(
      tableName: 'medication_schedules',
      recordId: id,
      operation: 'delete',
      payload: {},
    );
    _sync.triggerSync();
  }
}

final medicationScheduleRepositoryProvider =
    Provider<MedicationScheduleRepository>((ref) {
  return MedicationScheduleRepository(
    ref.watch(databaseProvider),
    ref.watch(syncServiceProvider),
  );
});
