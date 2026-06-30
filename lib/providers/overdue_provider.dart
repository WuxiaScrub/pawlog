import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/event_type.dart';
import 'events_provider.dart';
import 'notification_settings_provider.dart';

class OverdueItem {
  const OverdueItem({
    required this.eventType,
    required this.lastLoggedAt,
    required this.thresholdHours,
  });

  final CatEventType eventType;
  final DateTime lastLoggedAt;
  final int thresholdHours;
}

/// Event types whose reminder threshold has been exceeded for the given
/// cat. Event types with no logged history yet are never included — a
/// baseline must be established with a first log before reminders begin.
final overdueItemsProvider =
    Provider.family<List<OverdueItem>, String>((ref, catId) {
  final events = ref.watch(eventsStreamProvider(catId)).value ?? [];
  final settings = ref.watch(effectiveSettingsProvider);
  final now = DateTime.now();

  final lastLoggedByType = <CatEventType, DateTime>{};
  for (final event in events) {
    final type = CatEventTypeX.fromStorageKey(event.eventType);
    final current = lastLoggedByType[type];
    if (current == null || event.loggedAt.isAfter(current)) {
      lastLoggedByType[type] = event.loggedAt;
    }
  }

  final overdue = <OverdueItem>[];
  for (final entry in settings.entries) {
    final type = entry.key;
    final setting = entry.value;
    if (!setting.enabled || setting.thresholdHours <= 0) continue;

    // An event type with no logged history yet has nothing to be overdue
    // against — only alert once a first event establishes a baseline.
    final lastLogged = lastLoggedByType[type];
    if (lastLogged == null) continue;

    final isOverdue =
        now.difference(lastLogged).inHours >= setting.thresholdHours;

    if (isOverdue) {
      overdue.add(OverdueItem(
        eventType: type,
        lastLoggedAt: lastLogged,
        thresholdHours: setting.thresholdHours,
      ));
    }
  }

  return overdue;
});
