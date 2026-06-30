import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/database.dart';
import '../models/event_type.dart';
import 'database_provider.dart';

const _uuid = Uuid();

/// Default reminder thresholds, in hours. Only the recurring chores default
/// to enabled; one-off/medical events are off until the user opts in.
const Map<CatEventType, int> defaultThresholdHours = {
  CatEventType.litterScoop: 24,
  CatEventType.litterChange: 168,
  CatEventType.waterChange: 24,
  CatEventType.vomit: 0,
  CatEventType.hairball: 0,
  CatEventType.deworming: 720,
  CatEventType.fleaTreatment: 720,
  CatEventType.medication: 0,
  CatEventType.feeding: 0,
  CatEventType.playtime: 0,
  CatEventType.note: 0,
  CatEventType.weight: 0,
};

const Set<CatEventType> defaultEnabledTypes = {
  CatEventType.litterScoop,
  CatEventType.litterChange,
  CatEventType.waterChange,
  CatEventType.deworming,
  CatEventType.fleaTreatment,
};

class EffectiveSetting {
  const EffectiveSetting({required this.thresholdHours, required this.enabled});
  final int thresholdHours;
  final bool enabled;
}

final notificationSettingsStreamProvider =
    StreamProvider<List<NotificationSetting>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.notificationSettings).watch();
});

/// Merges stored settings with sane defaults so every event type always has
/// an effective threshold/enabled value, even before the user visits Settings.
final effectiveSettingsProvider =
    Provider<Map<CatEventType, EffectiveSetting>>((ref) {
  final stored = ref.watch(notificationSettingsStreamProvider).value ?? [];
  final storedByType = {
    for (final s in stored) CatEventTypeX.fromStorageKey(s.eventType): s,
  };

  return {
    for (final type in CatEventType.values)
      type: storedByType.containsKey(type)
          ? EffectiveSetting(
              thresholdHours: storedByType[type]!.thresholdHours,
              enabled: storedByType[type]!.enabled,
            )
          : EffectiveSetting(
              thresholdHours: defaultThresholdHours[type] ?? 0,
              enabled: defaultEnabledTypes.contains(type),
            ),
  };
});

class NotificationSettingsRepository {
  NotificationSettingsRepository(this._db);
  final AppDatabase _db;

  Future<void> upsert({
    required CatEventType eventType,
    required int thresholdHours,
    required bool enabled,
  }) {
    // A single atomic "INSERT ... ON CONFLICT DO UPDATE", relying on the
    // unique index on event_type, so two near-simultaneous edits (e.g.
    // toggling the enable switch and saving the threshold dialog right
    // after) can't race a separate read-then-write and leave a stale
    // threshold to resurface — the database itself serializes the conflict.
    return _db.into(_db.notificationSettings).insert(
          NotificationSettingsCompanion.insert(
            id: _uuid.v4(),
            eventType: eventType.storageKey,
            thresholdHours: thresholdHours,
            enabled: Value(enabled),
          ),
          onConflict: DoUpdate(
            (_) => NotificationSettingsCompanion(
              thresholdHours: Value(thresholdHours),
              enabled: Value(enabled),
            ),
            target: [_db.notificationSettings.eventType],
          ),
        );
  }
}

final notificationSettingsRepositoryProvider =
    Provider<NotificationSettingsRepository>((ref) {
  return NotificationSettingsRepository(ref.watch(databaseProvider));
});
