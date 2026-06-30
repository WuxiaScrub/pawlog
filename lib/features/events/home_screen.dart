import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database.dart';
import '../../models/event_type.dart';
import '../../providers/events_provider.dart';
import '../../providers/feeding_provider.dart';
import '../cats/cat_avatar.dart';
import 'log_event_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.cat});

  final Cat cat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsStreamProvider(cat.id));
    final scheduleAsync = ref.watch(feedingScheduleStreamProvider(cat.id));
    final hasFeedingSchedule = scheduleAsync.value != null;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CatAvatar(photoPath: cat.photoPath, radius: 16),
            const SizedBox(width: 12),
            Text(cat.name),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Voice logging is coming in a future update — use the buttons below for now.'),
            ),
          );
        },
        tooltip: 'Voice log (coming soon)',
        child: const Icon(Icons.mic),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (hasFeedingSchedule) ...[
            _TodaysFeedingsCard(catId: cat.id),
            const SizedBox(height: 24),
          ],
          Text('Log an event', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.9,
            children: [
              for (final type in CatEventType.values)
                if (!(hasFeedingSchedule && type == CatEventType.feeding))
                  _QuickLogButton(
                    eventType: type,
                    onTap: () => showLogEventSheet(
                      context,
                      catId: cat.id,
                      eventType: type,
                    ),
                  ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Recent activity',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          eventsAsync.when(
            data: (events) {
              if (events.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('No events logged yet.'),
                );
              }
              final recent = events.take(5);
              return Column(
                children: [
                  for (final event in recent)
                    ListTile(
                      leading: Icon(
                          CatEventTypeX.fromStorageKey(event.eventType).icon),
                      title: Text(
                          CatEventTypeX.fromStorageKey(event.eventType).label),
                      subtitle: event.notes != null ? Text(event.notes!) : null,
                      trailing: Text(
                        DateFormat.MMMd().add_jm().format(event.loggedAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error loading events: $e'),
          ),
        ],
      ),
    );
  }
}

class _QuickLogButton extends StatelessWidget {
  const _QuickLogButton({required this.eventType, required this.onTap});

  final CatEventType eventType;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(eventType.icon, size: 28),
              const SizedBox(height: 6),
              Text(
                eventType.label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodaysFeedingsCard extends ConsumerWidget {
  const _TodaysFeedingsCard({required this.catId});

  final String catId;

  Future<void> _markFed(WidgetRef ref, FeedingSlotStatus status) {
    return ref.read(eventsRepositoryProvider).logEvent(
      catId: catId,
      eventType: CatEventType.feeding,
      metadata: {
        'slot_id': status.slot.id,
        'slot_label': status.slot.label,
        'schedule_id': status.slot.scheduleId,
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(todaysFeedingStatusProvider(catId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today's Feedings",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            statusAsync.when(
              data: (statuses) {
                if (statuses.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No feeding slots set up.'),
                  );
                }
                return Column(
                  children: [
                    for (final status in statuses)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          status.isFed
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: status.isFed ? Colors.green : null,
                        ),
                        title: Text(status.slot.label),
                        subtitle: Text(
                          status.isFed
                              ? 'Fed at ${DateFormat.jm().format(status.fedAt!)}'
                              : '${status.slot.hour.toString().padLeft(2, '0')}:${status.slot.minute.toString().padLeft(2, '0')}',
                        ),
                        trailing: status.isFed
                            ? null
                            : FilledButton(
                                onPressed: () => _markFed(ref, status),
                                child: const Text('Mark fed'),
                              ),
                      ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              ),
              error: (e, _) => Text('Error loading feedings: $e'),
            ),
          ],
        ),
      ),
    );
  }
}
