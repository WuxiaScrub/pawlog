import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/database.dart';
import '../../core/supabase_client.dart';
import '../../models/event_type.dart';
import '../../providers/auth_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/notification_settings_provider.dart';
import '../../providers/sync_provider.dart';
import '../../providers/voice_provider.dart';
import '../auth/auth_screen.dart';
import '../cats/cat_profile_setup_screen.dart';
import '../feeding/feeding_schedule_setup_screen.dart';

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
          const _AccountSection(),
          const Divider(),
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
          ListTile(
            leading: const Icon(Icons.restaurant),
            title: const Text('Feeding schedule'),
            subtitle: const Text('Optional — track feedings by time slot'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => FeedingScheduleSetupScreen(cat: cat),
              ),
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Voice logging',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          _ApiKeyTile(),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Reminder thresholds',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          for (final type in CatEventType.values.where((t) => t.isSchedulable))
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

class _AccountSection extends ConsumerStatefulWidget {
  const _AccountSection();

  @override
  ConsumerState<_AccountSection> createState() => _AccountSectionState();
}

class _AccountSectionState extends ConsumerState<_AccountSection> {
  bool _syncing = false;

  Future<void> _syncNow() async {
    setState(() => _syncing = true);
    try {
      final result =
          await ref.read(syncServiceProvider).triggerSyncAndWait();
      if (!mounted) return;
      final parts = <String>[];
      if (result.photosUploaded > 0) {
        parts.add('${result.photosUploaded} '
            '${result.photosUploaded == 1 ? 'photo' : 'photos'}');
      }
      final dbItems = result.itemCount;
      if (dbItems > 0) {
        parts.add('$dbItems ${dbItems == 1 ? 'item' : 'items'}');
      }
      final message = parts.isEmpty
          ? 'Everything is up to date'
          : 'Synced ${parts.join(' and ')} to cloud';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return ListTile(
        leading: const Icon(Icons.cloud_off),
        title: const Text('Sign in'),
        subtitle: const Text('Back up and sync your data'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
        ),
      );
    }

    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.cloud_done),
          title: Text(user.email ?? 'Signed in'),
          subtitle: const Text('Data syncing enabled'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: _syncing ? null : _syncNow,
                icon: _syncing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync, size: 18),
                label: Text(_syncing ? 'Syncing...' : 'Sync now'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Sign out?'),
                      content: const Text(
                        'Your data stays on this device. '
                        'New changes won\'t sync until you sign back in.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Sign out'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
                      try {
                        // disconnect(), not signOut(): Google's iOS SDK signs
                        // in through a web-auth sheet backed by Safari's
                        // cookie store, and signOut() clears only our local
                        // token cache. With the cookie still live, the next
                        // sign-in silently reuses the same account instead of
                        // showing the picker. disconnect() revokes the grant
                        // server-side, so Google always re-prompts.
                        await GoogleSignIn().disconnect();
                      } catch (_) {}
                    }
                    final db = ref.read(databaseProvider);
                    await db.clearAllUserData();
                    await supabase.auth.signOut();
                  }
                },
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThresholdTile extends StatelessWidget {
  const _ThresholdTile({
    required this.eventType,
    required this.setting,
    required this.onChanged,
  });

  final CatEventType eventType;
  final EffectiveSetting setting;
  final void Function(bool enabled, int thresholdHours) onChanged;

  int get _hours => setting.thresholdHours == 0 ? 24 : setting.thresholdHours;

  bool get _useDays => _hours > 48;

  String get _thresholdLabel {
    if (_useDays) {
      final days = (_hours / 24).round();
      return 'Alert if not logged in $days ${days == 1 ? 'day' : 'days'}';
    }
    return 'Alert if not logged in $_hours h';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(eventType.icon),
      title: Text(eventType.label),
      subtitle: setting.enabled
          ? Text(_thresholdLabel)
          : const Text('Reminder off'),
      trailing: Switch(
        value: setting.enabled,
        onChanged: (value) => onChanged(value, _hours),
      ),
      onTap: setting.enabled
          ? () async {
              final hours = await _promptThreshold(context, _hours);
              if (hours != null) {
                onChanged(true, hours);
              }
            }
          : null,
    );
  }

  Future<int?> _promptThreshold(BuildContext context, int currentHours) {
    final useDays = currentHours > 48;
    final initialValue =
        useDays ? (currentHours / 24).round() : currentHours;
    final controller =
        TextEditingController(text: initialValue.toString());
    return showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Alert threshold (${useDays ? 'days' : 'hours'})'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              if (value == null) {
                Navigator.of(ctx).pop();
                return;
              }
              final hours = useDays ? value * 24 : value;
              Navigator.of(ctx).pop(hours);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _ApiKeyTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keyAsync = ref.watch(apiKeyProvider);
    final hasKey =
        keyAsync.whenOrNull(data: (k) => k != null && k.isNotEmpty) ?? false;

    return ListTile(
      leading: const Icon(Icons.key),
      title: const Text('Claude API Key'),
      subtitle: Text(hasKey ? 'Configured' : 'Required for voice logging'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showKeyDialog(context, ref, hasKey),
    );
  }

  void _showKeyDialog(BuildContext context, WidgetRef ref, bool hasKey) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Claude API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              obscureText: true,
              decoration: InputDecoration(
                hintText: hasKey ? 'Enter new key to replace' : 'sk-ant-...',
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            if (hasKey)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'A key is already saved. Enter a new one to replace it.',
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
              ),
          ],
        ),
        actions: [
          if (hasKey)
            TextButton(
              onPressed: () async {
                await deleteApiKey();
                ref.invalidate(apiKeyProvider);
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: Text(
                'Remove',
                style: TextStyle(color: Theme.of(ctx).colorScheme.error),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final key = controller.text.trim();
              if (key.isEmpty) return;
              await saveApiKey(key);
              ref.invalidate(apiKeyProvider);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
