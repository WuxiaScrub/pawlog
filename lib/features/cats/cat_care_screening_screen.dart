import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/event_type.dart';
import '../../providers/cats_provider.dart';
import '../../providers/events_provider.dart';
import '../../providers/notification_settings_provider.dart';

/// Screening questions shown once after a new cat profile is created.
/// The user's answers determine which event types appear as quick-log
/// buttons on the home screen by default.
class CatCareScreeningScreen extends ConsumerStatefulWidget {
  const CatCareScreeningScreen({
    super.key,
    required this.catId,
    required this.catName,
  });

  final String catId;
  final String catName;

  @override
  ConsumerState<CatCareScreeningScreen> createState() =>
      _CatCareScreeningScreenState();
}

class _ScreeningQuestion {
  const _ScreeningQuestion({
    required this.question,
    required this.subtitle,
    required this.types,
    required this.defaultEnabled,
  });

  final String question;
  final String subtitle;
  final List<CatEventType> types;
  final bool defaultEnabled;
}

class _CatCareScreeningScreenState
    extends ConsumerState<CatCareScreeningScreen> {
  // Always-visible types — assumed for virtually all cats, or are observations
  // that can't be scheduled. Users can still remove them via the customize
  // button on the home screen if needed.
  static const _alwaysOn = {
    CatEventType.litterScoop,
    CatEventType.litterChange,
    CatEventType.waterChange,
    CatEventType.vomit,
    CatEventType.hairball,
    CatEventType.note,
  };

  late final List<_ScreeningQuestion> _questions;
  late final Map<CatEventType, bool> _enabled;
  final Map<CatEventType, DateTime?> _lastDone = {
    for (final t in seedBaselineAtRegistration) t: null,
  };
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _questions = [
      _ScreeningQuestion(
        question: 'Does ${widget.catName} eat on a set schedule?',
        subtitle:
            'Set up named time slots (e.g. Morning, Evening) so you can mark each meal done. Leave off for free-feeding cats.',
        types: [CatEventType.feeding],
        defaultEnabled: false,
      ),
      _ScreeningQuestion(
        question: 'Is ${widget.catName} on any medication?',
        subtitle: 'Log medication doses and treatments.',
        types: [CatEventType.medication],
        defaultEnabled: false,
      ),
      _ScreeningQuestion(
        question: 'Do you give deworming or flea/tick treatments?',
        subtitle: 'Log product name and whether it\'s a first-time treatment.',
        types: [CatEventType.deworming, CatEventType.fleaTreatment],
        defaultEnabled: true,
      ),
      _ScreeningQuestion(
        question: 'Do you want to track playtime?',
        subtitle: 'Log play sessions and duration.',
        types: [CatEventType.playtime],
        defaultEnabled: false,
      ),
    ];

    _enabled = {
      for (final q in _questions)
        for (final t in q.types) t: q.defaultEnabled,
    };
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    final enabledTypes = [
      ..._alwaysOn,
      for (final entry in _enabled.entries)
        if (entry.value) entry.key,
    ];

    await ref.read(catsRepositoryProvider).saveQuickLogPreferences(
          catId: widget.catId,
          enabledTypes: enabledTypes,
        );

    // Seed a "last done" baseline for the long-cadence chores so reminders
    // can start counting immediately instead of staying silent forever
    // until a first real log. litterChange is always tracked; deworming
    // and fleaTreatment only get seeded if the user said they apply.
    final eventsRepo = ref.read(eventsRepositoryProvider);
    for (final type in seedBaselineAtRegistration) {
      final applies =
          type == CatEventType.litterChange || _enabled[type] == true;
      if (!applies) continue;
      await eventsRepo.logEvent(
        catId: widget.catId,
        eventType: type,
        notes: 'Added automatically when ${widget.catName} was set up',
        loggedAt: _lastDone[type] ?? DateTime.now(),
      );
    }
    // No Navigator.pop() — this screen is rendered directly by _Root, which
    // will replace it with MainShell the moment screeningDone flips to true.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customize Tracking'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'A few quick questions to tailor ${widget.catName}\'s tracking. Litter, water, and health observations are already set up — this is just for the extras.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Skip anything that doesn\'t apply — you can always adjust later.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 24),
          Text(
            'Already been caring for ${widget.catName}? Tell us when you last did these so reminders start counting from the right day instead of today.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 8),
          _LastDoneField(
            label: 'Litter last fully changed',
            value: _lastDone[CatEventType.litterChange],
            onChanged: (d) =>
                setState(() => _lastDone[CatEventType.litterChange] = d),
          ),
          const Divider(height: 1),
          const SizedBox(height: 16),
          for (final q in _questions) ...[
            _ScreeningTile(
              question: q.question,
              subtitle: q.subtitle,
              types: q.types,
              enabled: q.types.every((t) => _enabled[t] == true),
              onChanged: (val) => setState(() {
                for (final t in q.types) {
                  _enabled[t] = val;
                }
              }),
            ),
            if (q.types.every((t) => _enabled[t] == true))
              for (final t in q.types)
                if (seedBaselineAtRegistration.contains(t))
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: _LastDoneField(
                      label: 'Last ${t.label.toLowerCase()}',
                      value: _lastDone[t],
                      onChanged: (d) => setState(() => _lastDone[t] = d),
                    ),
                  ),
            const Divider(height: 1),
          ],
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Done — start logging'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('Skip for now'),
          ),
        ],
      ),
    );
  }
}

class _ScreeningTile extends StatelessWidget {
  const _ScreeningTile({
    required this.question,
    required this.subtitle,
    required this.types,
    required this.enabled,
    required this.onChanged,
  });

  final String question;
  final String subtitle;
  final List<CatEventType> types;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: enabled,
      onChanged: onChanged,
      title: Text(question),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            children: [
              for (final t in types)
                Chip(
                  avatar: Icon(t.icon, size: 14),
                  label: Text(t.label),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ],
      ),
      isThreeLine: true,
    );
  }
}

/// Optional date picker used to backfill a "last done" baseline for a
/// chore the user was already keeping up with before adding this cat.
/// Leaving it unset falls back to the cat's registration time.
class _LastDoneField extends StatelessWidget {
  const _LastDoneField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: DateTime(2015),
      lastDate: now,
    );
    // Date-only picker; pin to noon so the resulting event doesn't display
    // as a slightly odd midnight timestamp in the log history.
    if (picked != null) {
      onChanged(DateTime(picked.year, picked.month, picked.day, 12));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: const Icon(Icons.event_outlined, size: 20),
      title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
      subtitle: Text(
        value != null
            ? DateFormat.yMMMd().format(value!)
            : 'Not sure — start counting from today',
      ),
      trailing: value != null
          ? IconButton(
              icon: const Icon(Icons.clear, size: 18),
              onPressed: () => onChanged(null),
              tooltip: 'Clear',
            )
          : null,
      onTap: () => _pick(context),
    );
  }
}
