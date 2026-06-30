import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database.dart';
import '../../models/event_type.dart';
import '../../providers/notification_settings_provider.dart';
import '../cats/cat_profile_setup_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key, required this.cat});

  final Cat cat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(effectiveSettingsProvider);
    final repo = ref.read(notificationSettingsRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.pets),
            title: Text(cat.name),
            subtitle: const Text('Edit cat profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CatProfileSetupScreen(existingCat: cat),
              ),
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Reminder thresholds',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          for (final type in CatEventType.values)
            _ThresholdTile(
              eventType: type,
              setting: settings[type]!,
              onChanged: (enabled, hours) => repo.upsert(
                eventType: type,
                enabled: enabled,
                thresholdHours: hours,
              ),
            ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'PawLog is not a substitute for veterinary care. If your cat '
              'shows signs of illness or distress, contact your veterinarian.',
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThresholdTile extends StatefulWidget {
  const _ThresholdTile({
    required this.eventType,
    required this.setting,
    required this.onChanged,
  });

  final CatEventType eventType;
  final EffectiveSetting setting;
  final void Function(bool enabled, int thresholdHours) onChanged;

  @override
  State<_ThresholdTile> createState() => _ThresholdTileState();
}

class _ThresholdTileState extends State<_ThresholdTile> {
  late int _hours;

  @override
  void initState() {
    super.initState();
    _hours = widget.setting.thresholdHours == 0
        ? 24
        : widget.setting.thresholdHours;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(widget.eventType.icon),
      title: Text(widget.eventType.label),
      subtitle: widget.setting.enabled
          ? Text('Alert if not logged in $_hours h')
          : const Text('Reminder off'),
      trailing: Switch(
        value: widget.setting.enabled,
        onChanged: (value) => widget.onChanged(value, _hours),
      ),
      onTap: widget.setting.enabled
          ? () async {
              final hours = await _promptHours(context, _hours);
              if (hours != null) {
                setState(() => _hours = hours);
                widget.onChanged(true, hours);
              }
            }
          : null,
    );
  }

  Future<int?> _promptHours(BuildContext context, int current) {
    final controller = TextEditingController(text: current.toString());
    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alert threshold (hours)'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              Navigator.of(context).pop(value);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
