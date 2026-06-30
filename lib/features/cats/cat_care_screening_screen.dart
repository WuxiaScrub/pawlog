import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/event_type.dart';
import '../../providers/cats_provider.dart';

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
  // Always-visible types — observations, not chores, so they can't be toggled off here.
  static const _alwaysOn = {
    CatEventType.vomit,
    CatEventType.hairball,
    CatEventType.note,
  };

  late final List<_ScreeningQuestion> _questions;
  late final Map<CatEventType, bool> _enabled;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _questions = [
      _ScreeningQuestion(
        question: 'Does ${widget.catName} use a litter box?',
        subtitle: 'Enables litter scooping and full litter change tracking.',
        types: [CatEventType.litterScoop, CatEventType.litterChange],
        defaultEnabled: true,
      ),
      _ScreeningQuestion(
        question: 'Do you want to track water changes?',
        subtitle: 'Log when you refresh the water bowl.',
        types: [CatEventType.waterChange],
        defaultEnabled: true,
      ),
      _ScreeningQuestion(
        question: 'Does ${widget.catName} have scheduled mealtimes?',
        subtitle: 'Sets up a feeding schedule with time slots.',
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

    if (mounted) Navigator.of(context).pop();
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
            'Tell us a little about ${widget.catName}\'s care routine so we can set up the right tracking events for you. You can always change these later in Settings.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Any question can be skipped — just leave it off.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 24),
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
