import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database.dart';
import '../../models/event_type.dart';
import '../../providers/cats_provider.dart';
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Log an event',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                icon: const Icon(Icons.tune),
                tooltip: 'Customize buttons',
                onPressed: () => _showCustomizeSheet(context, ref, cat),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _QuickLogGrid(cat: cat, hasFeedingSchedule: hasFeedingSchedule),
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

void _showCustomizeSheet(BuildContext context, WidgetRef ref, Cat cat) {
  final current = decodeQuickLogTypes(cat.quickLogTypesJson) ??
      CatEventType.values.toSet();

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetCtx) => _CustomizeSheet(cat: cat, current: current),
  );
}

class _QuickLogGrid extends ConsumerWidget {
  const _QuickLogGrid({required this.cat, required this.hasFeedingSchedule});

  final Cat cat;
  final bool hasFeedingSchedule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Decode preferences; null means "all types" (legacy / no preference set).
    final enabledTypes =
        decodeQuickLogTypes(cat.quickLogTypesJson) ?? CatEventType.values.toSet();

    final visibleTypes = CatEventType.values.where((t) {
      if (hasFeedingSchedule && t == CatEventType.feeding) return false;
      return enabledTypes.contains(t);
    }).toList();

    if (visibleTypes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'No event types enabled. Tap the tune icon to add some.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 0.9,
      children: [
        for (final type in visibleTypes)
          _QuickLogButton(
            eventType: type,
            onTap: () =>
                showLogEventSheet(context, catId: cat.id, eventType: type),
          ),
      ],
    );
  }
}

class _CustomizeSheet extends ConsumerStatefulWidget {
  const _CustomizeSheet({required this.cat, required this.current});

  final Cat cat;
  final Set<CatEventType> current;

  @override
  ConsumerState<_CustomizeSheet> createState() => _CustomizeSheetState();
}

class _CustomizeSheetState extends ConsumerState<_CustomizeSheet> {
  late final Set<CatEventType> _enabled;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _enabled = Set.from(widget.current);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ref.read(catsRepositoryProvider).saveQuickLogPreferences(
          catId: widget.cat.id,
          enabledTypes: _enabled.toList(),
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Customize quick-log buttons',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Choose which event types appear as buttons on the home screen.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final type in CatEventType.values)
                    CheckboxListTile(
                      value: _enabled.contains(type),
                      onChanged: (val) => setState(() {
                        if (val == true) {
                          _enabled.add(type);
                        } else {
                          _enabled.remove(type);
                        }
                      }),
                      secondary: Icon(type.icon),
                      title: Text(type.label),
                      dense: true,
                    ),
                ],
              ),
            ),
          ],
        ),
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
