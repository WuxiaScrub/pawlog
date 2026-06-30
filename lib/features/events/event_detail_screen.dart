import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database.dart';
import '../../models/event_type.dart';
import '../../providers/events_provider.dart';

class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.event});

  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = CatEventTypeX.fromStorageKey(event.eventType);
    final metadata = event.metadataJson != null
        ? jsonDecode(event.metadataJson!) as Map<String, dynamic>
        : <String, dynamic>{};

    return Scaffold(
      appBar: AppBar(
        title: Text(type.label),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await ref.read(eventsRepositoryProvider).deleteEvent(event.id);
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: Icon(type.icon),
            title: Text(type.label),
            subtitle: Text(
              DateFormat.yMMMd().add_jm().format(event.loggedAt),
            ),
          ),
          if (event.notes != null && event.notes!.isNotEmpty) ...[
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Text(event.notes!),
          ],
          if (metadata.isNotEmpty) ...[
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Details', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            for (final entry in metadata.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('${entry.key.replaceAll('_', ' ')}: ${entry.value}'),
              ),
          ],
        ],
      ),
    );
  }
}
