import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/database.dart';
import '../models/event_type.dart';
import 'database_provider.dart';
import 'events_provider.dart';

const _uuid = Uuid();

/// Null when the cat has no feeding schedule set up — feeding setup is
/// optional and falls back to ad-hoc logging via the quick-log grid.
final feedingScheduleStreamProvider =
    StreamProvider.family<FeedingSchedule?, String>((ref, catId) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.feedingSchedules)
        ..where((t) => t.catId.equals(catId) & t.enabled.equals(true)))
      .watchSingleOrNull();
});

final feedingSlotsStreamProvider =
    StreamProvider.family<List<FeedingSlot>, String>((ref, scheduleId) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.feedingSlots)
        ..where((t) => t.scheduleId.equals(scheduleId))
        ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
      .watch();
});

class FeedingSlotStatus {
  const FeedingSlotStatus({required this.slot, required this.fedAt});
  final FeedingSlot slot;

  /// When this slot was checked off today, or null if still pending.
  /// Surfaced from the shared Events log, so any household member who logs
  /// a feeding for this slot makes it show as done for everyone reading the
  /// same database.
  final DateTime? fedAt;

  bool get isFed => fedAt != null;
}

/// Combines today's feeding slots with the Events log to derive which slots
/// have already been fed today, keyed off `metadata.slot_id` rather than a
/// separate "fed" flag — so the existing event history/delete UI doubles as
/// the undo mechanism for an accidental check-off.
final todaysFeedingStatusProvider =
    Provider.family<AsyncValue<List<FeedingSlotStatus>>, String>((ref, catId) {
  final scheduleAsync = ref.watch(feedingScheduleStreamProvider(catId));

  return scheduleAsync.when(
    data: (schedule) {
      if (schedule == null) return const AsyncValue.data([]);

      final slotsAsync = ref.watch(feedingSlotsStreamProvider(schedule.id));
      final eventsAsync = ref.watch(eventsStreamProvider(catId));

      if (slotsAsync.isLoading || eventsAsync.isLoading) {
        return const AsyncValue.loading();
      }
      if (slotsAsync.hasError) {
        return AsyncValue.error(slotsAsync.error!, slotsAsync.stackTrace!);
      }
      if (eventsAsync.hasError) {
        return AsyncValue.error(eventsAsync.error!, eventsAsync.stackTrace!);
      }

      final slots = slotsAsync.value ?? [];
      final events = eventsAsync.value ?? [];
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      final fedAtBySlotId = <String, DateTime>{};
      for (final event in events) {
        if (CatEventTypeX.fromStorageKey(event.eventType) !=
            CatEventType.feeding) {
          continue;
        }
        if (event.loggedAt.isBefore(todayStart)) continue;
        final metadataJson = event.metadataJson;
        if (metadataJson == null) continue;
        final metadata = jsonDecode(metadataJson) as Map<String, dynamic>;
        final slotId = metadata['slot_id'] as String?;
        if (slotId == null) continue;
        final existing = fedAtBySlotId[slotId];
        if (existing == null || event.loggedAt.isAfter(existing)) {
          fedAtBySlotId[slotId] = event.loggedAt;
        }
      }

      return AsyncValue.data([
        for (final slot in slots)
          FeedingSlotStatus(slot: slot, fedAt: fedAtBySlotId[slot.id]),
      ]);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

class FeedingScheduleRepository {
  FeedingScheduleRepository(this._db);
  final AppDatabase _db;

  /// Replaces any existing schedule for the cat with a fresh one made up of
  /// [slots], in a single transaction so readers never see a partial state.
  Future<void> saveSchedule({
    required String catId,
    required int timesPerDay,
    required List<({String label, int hour, int minute})> slots,
  }) {
    return _db.transaction(() async {
      final existing = await (_db.select(_db.feedingSchedules)
            ..where((t) => t.catId.equals(catId)))
          .getSingleOrNull();

      if (existing != null) {
        await (_db.delete(_db.feedingSlots)
              ..where((t) => t.scheduleId.equals(existing.id)))
            .go();
        await (_db.delete(_db.feedingSchedules)
              ..where((t) => t.id.equals(existing.id)))
            .go();
      }

      final scheduleId = _uuid.v4();
      await _db.into(_db.feedingSchedules).insert(
            FeedingSchedulesCompanion.insert(
              id: scheduleId,
              catId: catId,
              timesPerDay: timesPerDay,
            ),
          );

      for (var i = 0; i < slots.length; i++) {
        final slot = slots[i];
        await _db.into(_db.feedingSlots).insert(
              FeedingSlotsCompanion.insert(
                id: _uuid.v4(),
                scheduleId: scheduleId,
                catId: catId,
                label: slot.label,
                hour: slot.hour,
                minute: slot.minute,
                sortOrder: i,
              ),
            );
      }
    });
  }

  Future<void> deleteSchedule(String scheduleId) {
    return _db.transaction(() async {
      await (_db.delete(_db.feedingSlots)
            ..where((t) => t.scheduleId.equals(scheduleId)))
          .go();
      await (_db.delete(_db.feedingSchedules)
            ..where((t) => t.id.equals(scheduleId)))
          .go();
    });
  }
}

final feedingScheduleRepositoryProvider =
    Provider<FeedingScheduleRepository>((ref) {
  return FeedingScheduleRepository(ref.watch(databaseProvider));
});
