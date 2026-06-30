import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database.dart';
import '../../providers/feeding_provider.dart';

/// Optional setup wizard for a cat's feeding schedule. A cat with no
/// schedule simply uses ad-hoc feeding logging like any other event type.
class FeedingScheduleSetupScreen extends ConsumerStatefulWidget {
  const FeedingScheduleSetupScreen({super.key, required this.cat});

  final Cat cat;

  @override
  ConsumerState<FeedingScheduleSetupScreen> createState() =>
      _FeedingScheduleSetupScreenState();
}

class _SlotDraft {
  _SlotDraft({required this.label, required this.hour, required this.minute});
  String label;
  int hour;
  int minute;
}

List<_SlotDraft> _defaultSlots(int timesPerDay) {
  switch (timesPerDay) {
    case 1:
      return [_SlotDraft(label: 'Feeding', hour: 8, minute: 0)];
    case 2:
      return [
        _SlotDraft(label: 'Morning', hour: 8, minute: 0),
        _SlotDraft(label: 'Evening', hour: 18, minute: 0),
      ];
    case 3:
      return [
        _SlotDraft(label: 'Morning', hour: 8, minute: 0),
        _SlotDraft(label: 'Afternoon', hour: 13, minute: 0),
        _SlotDraft(label: 'Evening', hour: 19, minute: 0),
      ];
    default:
      return [
        for (var i = 0; i < timesPerDay; i++)
          _SlotDraft(
            label: 'Feeding ${i + 1}',
            hour: (8 + i * (12 ~/ timesPerDay)).clamp(0, 23),
            minute: 0,
          ),
      ];
  }
}

class _FeedingScheduleSetupScreenState
    extends ConsumerState<FeedingScheduleSetupScreen> {
  int _timesPerDay = 3;
  late List<_SlotDraft> _slots = _defaultSlots(_timesPerDay);
  bool _hasExistingSchedule = false;
  bool _initialized = false;
  bool _saving = false;

  void _setTimesPerDay(int value) {
    setState(() {
      _timesPerDay = value;
      _slots = _defaultSlots(value);
    });
  }

  Future<void> _pickTime(_SlotDraft slot) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: slot.hour, minute: slot.minute),
    );
    if (picked != null) {
      setState(() {
        slot.hour = picked.hour;
        slot.minute = picked.minute;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ref.read(feedingScheduleRepositoryProvider).saveSchedule(
          catId: widget.cat.id,
          timesPerDay: _timesPerDay,
          slots: [
            for (final s in _slots)
              (label: s.label, hour: s.hour, minute: s.minute),
          ],
        );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _removeSchedule(String scheduleId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove feeding schedule?'),
        content: const Text(
          'Past feeding logs stay in your history. You can set up a new '
          'schedule again anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(feedingScheduleRepositoryProvider)
          .deleteSchedule(scheduleId);
      if (mounted) Navigator.of(context).pop();
    }
  }

  String _formatTime(int hour, int minute) {
    final tod = TimeOfDay(hour: hour, minute: minute);
    return tod.format(context);
  }

  @override
  Widget build(BuildContext context) {
    final scheduleAsync =
        ref.watch(feedingScheduleStreamProvider(widget.cat.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Feeding Schedule')),
      body: scheduleAsync.when(
        data: (schedule) {
          if (schedule != null && !_initialized) {
            _initialized = true;
            _hasExistingSchedule = true;
            _timesPerDay = schedule.timesPerDay;
          }

          if (_hasExistingSchedule && schedule != null) {
            final slotsAsync =
                ref.watch(feedingSlotsStreamProvider(schedule.id));
            return slotsAsync.when(
              data: (slots) => _buildExistingScheduleView(schedule, slots),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            );
          }

          return _buildSetupForm();
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildExistingScheduleView(
    FeedingSchedule schedule,
    List<FeedingSlot> slots,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '${schedule.timesPerDay}x per day',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        for (final slot in slots)
          ListTile(
            leading: const Icon(Icons.restaurant),
            title: Text(slot.label),
            subtitle: Text(_formatTime(slot.hour, slot.minute)),
          ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          icon: const Icon(Icons.edit),
          label: const Text('Edit schedule'),
          onPressed: () => setState(() {
            _hasExistingSchedule = false;
            _slots = [
              for (final s in slots)
                _SlotDraft(label: s.label, hour: s.hour, minute: s.minute),
            ];
          }),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.delete_outline),
          label: const Text('Remove schedule'),
          onPressed: () => _removeSchedule(schedule.id),
        ),
      ],
    );
  }

  Widget _buildSetupForm() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Set up a feeding schedule so everyone caring for your cat can '
          'see which feedings are already done today. This is optional — '
          'you can keep logging feedings without a schedule instead.',
        ),
        const SizedBox(height: 16),
        Text(
          'How many times do you feed per day?',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: _timesPerDay > 1
                  ? () => _setTimesPerDay(_timesPerDay - 1)
                  : null,
            ),
            Text('$_timesPerDay', style: Theme.of(context).textTheme.headlineMedium),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: _timesPerDay < 6
                  ? () => _setTimesPerDay(_timesPerDay + 1)
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 16),
        for (final slot in _slots)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: slot.label,
                      decoration: const InputDecoration(labelText: 'Label'),
                      onChanged: (v) => slot.label = v,
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => _pickTime(slot),
                    child: Text(_formatTime(slot.hour, slot.minute)),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_hasExistingSchedule ? 'Save Changes' : 'Save Schedule'),
        ),
      ],
    );
  }
}
