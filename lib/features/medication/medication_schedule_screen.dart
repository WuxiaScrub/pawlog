import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database.dart';
import '../../core/time_picker_dialog.dart';
import '../../providers/medication_schedule_provider.dart';

class MedicationScheduleScreen extends ConsumerWidget {
  const MedicationScheduleScreen({super.key, required this.cat});

  final Cat cat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedulesAsync =
        ref.watch(medicationSchedulesStreamProvider(cat.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Medication Schedules')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(context, ref, cat.id),
        child: const Icon(Icons.add),
      ),
      body: schedulesAsync.when(
        data: (schedules) {
          if (schedules.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No medications scheduled.\nTap + to add one.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.builder(
            itemCount: schedules.length,
            itemBuilder: (context, index) {
              final schedule = schedules[index];
              return _MedicationTile(
                schedule: schedule,
                catId: cat.id,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _MedicationTile extends ConsumerWidget {
  const _MedicationTile({required this.schedule, required this.catId});

  final MedicationSchedule schedule;
  final String catId;

  String get _timeLabel {
    final h = schedule.hour;
    final m = schedule.minute;
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h % 12 == 0 ? 12 : h % 12;
    return '$hour12:${m.toString().padLeft(2, '0')} $period';
  }

  String get _recurrenceLabel {
    if (schedule.recurrence == 'every_n_days' && schedule.intervalDays > 1) {
      return 'Every ${schedule.intervalDays} days';
    }
    return 'Daily';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(medicationScheduleRepositoryProvider);

    return ListTile(
      leading: const Icon(Icons.medication),
      title: Text(schedule.name),
      subtitle: Text(
        '$_timeLabel  ·  $_recurrenceLabel'
        '${schedule.dosage != null ? '  ·  ${schedule.dosage}' : ''}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: schedule.enabled,
            onChanged: (val) =>
                repo.updateSchedule(id: schedule.id, enabled: val),
          ),
          PopupMenuButton<String>(
            onSelected: (action) {
              if (action == 'edit') {
                _showAddEditDialog(context, ref, catId, existing: schedule);
              } else if (action == 'delete') {
                _confirmDelete(context, ref);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete medication?'),
        content: Text('Remove "${schedule.name}" from the schedule?'),
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
    if (confirmed == true) {
      ref
          .read(medicationScheduleRepositoryProvider)
          .deleteSchedule(schedule.id);
    }
  }
}

Future<void> _showAddEditDialog(
  BuildContext context,
  WidgetRef ref,
  String catId, {
  MedicationSchedule? existing,
}) async {
  final result = await showDialog<_MedFormResult>(
    context: context,
    builder: (_) => _MedicationFormDialog(existing: existing),
  );
  if (result == null) return;

  final repo = ref.read(medicationScheduleRepositoryProvider);
  if (existing != null) {
    await repo.updateSchedule(
      id: existing.id,
      name: result.name,
      dosage: result.dosage,
      hour: result.hour,
      minute: result.minute,
      recurrence: result.recurrence,
      intervalDays: result.intervalDays,
    );
  } else {
    await repo.addSchedule(
      catId: catId,
      name: result.name,
      dosage: result.dosage,
      hour: result.hour,
      minute: result.minute,
      recurrence: result.recurrence,
      intervalDays: result.intervalDays,
      startDate: DateTime.now(),
    );
  }
}

class _MedFormResult {
  const _MedFormResult({
    required this.name,
    this.dosage,
    required this.hour,
    required this.minute,
    required this.recurrence,
    required this.intervalDays,
  });
  final String name;
  final String? dosage;
  final int hour;
  final int minute;
  final String recurrence;
  final int intervalDays;
}

class _MedicationFormDialog extends StatefulWidget {
  const _MedicationFormDialog({this.existing});
  final MedicationSchedule? existing;

  @override
  State<_MedicationFormDialog> createState() => _MedicationFormDialogState();
}

class _MedicationFormDialogState extends State<_MedicationFormDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _dosageCtrl;
  late final TextEditingController _intervalCtrl;
  late int _hour;
  late int _minute;
  late String _recurrence;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _dosageCtrl = TextEditingController(text: widget.existing?.dosage ?? '');
    _intervalCtrl = TextEditingController(
      text: (widget.existing?.intervalDays ?? 2).toString(),
    );
    _hour = widget.existing?.hour ?? 8;
    _minute = widget.existing?.minute ?? 0;
    _recurrence = widget.existing?.recurrence ?? 'daily';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    _intervalCtrl.dispose();
    super.dispose();
  }

  String get _timeLabel {
    final period = _hour >= 12 ? 'PM' : 'AM';
    final h12 = _hour % 12 == 0 ? 12 : _hour % 12;
    return '$h12:${_minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Medication' : 'Add Medication'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Medication name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dosageCtrl,
              decoration: const InputDecoration(
                labelText: 'Dosage (optional)',
                hintText: 'e.g. 1 tablet, 5ml',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Time'),
              trailing: TextButton(
                onPressed: () async {
                  final picked = await showTimeDropdownPicker(
                    context,
                    initialTime: TimeOfDay(hour: _hour, minute: _minute),
                  );
                  if (picked != null) {
                    setState(() {
                      _hour = picked.hour;
                      _minute = picked.minute;
                    });
                  }
                },
                child: Text(_timeLabel),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _recurrence,
              decoration: const InputDecoration(
                labelText: 'Frequency',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'daily', child: Text('Daily')),
                DropdownMenuItem(
                  value: 'every_n_days',
                  child: Text('Every N days'),
                ),
              ],
              onChanged: (v) => setState(() => _recurrence = v!),
            ),
            if (_recurrence == 'every_n_days') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _intervalCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Interval (days)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameCtrl.text.trim();
            if (name.isEmpty) return;
            final dosage = _dosageCtrl.text.trim();
            final interval = int.tryParse(_intervalCtrl.text.trim()) ?? 2;
            Navigator.of(context).pop(_MedFormResult(
              name: name,
              dosage: dosage.isEmpty ? null : dosage,
              hour: _hour,
              minute: _minute,
              recurrence: _recurrence,
              intervalDays: _recurrence == 'every_n_days' ? interval : 1,
            ));
          },
          child: Text(isEdit ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
