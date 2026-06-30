import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database.dart';
import '../../models/event_type.dart';
import '../../providers/events_provider.dart';
import 'log_event_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.cat});

  final Cat cat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsStreamProvider(cat.id));

    return Scaffold(
      appBar: AppBar(title: Text(cat.name)),
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
