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
  CatEventType.waterChange: 48,
  CatEventType.vomit: 0,
  CatEventType.hairball: 0,
  CatEventType.deworming: 0,
  CatEventType.fleaTreatment: 0,
  CatEventType.note: 0,
};

const Set<CatEventType> defaultEnabledTypes = {
  CatEventType.litterScoop,
  CatEventType.litterChange,
  CatEventType.waterChange,
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
  }) async {
    final existing = await (_db.select(_db.notificationSettings)
          ..where((t) => t.eventType.equals(eventType.storageKey)))
        .getSingleOrNull();

    if (existing == null) {
      await _db.into(_db.notificationSettings).insert(
            NotificationSettingsCompanion.insert(
              id: _uuid.v4(),
              eventType: eventType.storageKey,
              thresholdHours: thresholdHours,
              enabled: Value(enabled),
            ),
          );
    } else {
      await _db.update(_db.notificationSettings).replace(
            existing.copyWith(
              thresholdHours: thresholdHours,
              enabled: enabled,
            ),
          );
    }
  }
}

final notificationSettingsRepositoryProvider =
    Provider<NotificationSettingsRepository>((ref) {
  return NotificationSettingsRepository(ref.watch(databaseProvider));
});
