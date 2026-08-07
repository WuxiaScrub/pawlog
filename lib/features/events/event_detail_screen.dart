import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database.dart';
import '../../core/local_photo.dart';
import '../../models/event_type.dart';
import '../../providers/events_provider.dart';
import 'log_event_sheet.dart';

class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.event});

  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Re-read the event from the live stream so edits made via the sheet
    // (which pops back to this screen rather than replacing it) show up
    // immediately, falling back to the originally-passed snapshot until the
    // stream has emitted.
    final liveEvents = ref.watch(eventsStreamProvider(event.catId)).value;
    var current = event;
    if (liveEvents != null) {
      for (final e in liveEvents) {
        if (e.id == event.id) {
          current = e;
          break;
        }
      }
    }

    final type = CatEventTypeX.fromStorageKey(current.eventType);
    final metadata = current.metadataJson != null
        ? jsonDecode(current.metadataJson!) as Map<String, dynamic>
        : <String, dynamic>{};
    final photoPath = metadata.remove('photo_path') as String?;
    final photo = resolveLocalPhoto(photoPath);

    return Scaffold(
      appBar: AppBar(
        title: Text(type.label),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => showLogEventSheet(
              context,
              catId: current.catId,
              eventType: type,
              existingEvent: current,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete event?'),
                  content: const Text(
                      'This will remove the log entry. You can undo this for a few seconds after deleting.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirmed != true || !context.mounted) return;

              final repo = ref.read(eventsRepositoryProvider);
              final deletedEvent = current;
              final deletedType = type;
              await repo.deleteEvent(deletedEvent.id);
              if (!context.mounted) return;
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${deletedType.label} deleted'),
                  duration: const Duration(seconds: 5),
                  showCloseIcon: true,
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () {
                      final meta = deletedEvent.metadataJson != null
                          ? jsonDecode(deletedEvent.metadataJson!)
                              as Map<String, dynamic>
                          : null;
                      repo.logEvent(
                        catId: deletedEvent.catId,
                        eventType: deletedType,
                        notes: deletedEvent.notes,
                        metadata: meta,
                        loggedAt: deletedEvent.loggedAt,
                      );
                    },
                  ),
                ),
              );
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
              DateFormat.yMMMd().add_jm().format(current.loggedAt),
            ),
          ),
          if (photo != null) ...[
            const Divider(),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image(image: photo, fit: BoxFit.cover),
              ),
            ),
          ],
          if (current.notes != null && current.notes!.isNotEmpty) ...[
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Text(current.notes!),
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
                child: Text(
                  '${entry.key.replaceAll('_', ' ')}: '
                  '${_readableValue(entry.value)}',
                ),
              ),
          ],
        ],
      ),
    );
  }

  /// Renders a metadata value for display. Booleans become the friendly
  /// "Yes"/"No" instead of "true"/"false"; everything else is shown as-is.
  String _readableValue(dynamic value) {
    if (value is bool) return value ? 'Yes' : 'No';
    return value.toString();
  }
}
