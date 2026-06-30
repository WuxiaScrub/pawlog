import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database.dart';
import '../../models/event_type.dart';
import '../../providers/events_provider.dart';
import 'event_detail_screen.dart';

class LogHistoryScreen extends ConsumerStatefulWidget {
  const LogHistoryScreen({super.key, required this.cat});

  final Cat cat;

  @override
  ConsumerState<LogHistoryScreen> createState() => _LogHistoryScreenState();
}

class _LogHistoryScreenState extends ConsumerState<LogHistoryScreen> {
  CatEventType? _filter;

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsStreamProvider(widget.cat.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log History'),
        actions: [
          PopupMenuButton<CatEventType?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => _filter = value),
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('All events')),
              for (final type in CatEventType.values)
                PopupMenuItem(value: type, child: Text(type.label)),
            ],
          ),
        ],
      ),
      body: eventsAsync.when(
        data: (events) {
          final filtered = _filter == null
              ? events
              : events
                  .where((e) =>
                      CatEventTypeX.fromStorageKey(e.eventType) == _filter)
                  .toList();

          if (filtered.isEmpty) {
            return const Center(child: Text('No events found.'));
          }

          return ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final event = filtered[index];
              final type = CatEventTypeX.fromStorageKey(event.eventType);
              return ListTile(
                leading: Icon(type.icon),
                title: Text(type.label),
                subtitle: event.notes != null && event.notes!.isNotEmpty
                    ? Text(event.notes!, maxLines: 1, overflow: TextOverflow.ellipsis)
                    : null,
                trailing: Text(
                  DateFormat.MMMd().add_jm().format(event.loggedAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EventDetailScreen(event: event),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading history: $e')),
      ),
    );
  }
}
