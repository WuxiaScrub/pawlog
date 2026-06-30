import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/event_type.dart';
import '../providers/overdue_provider.dart';

/// Thin wrapper around flutter_local_notifications. A no-op on web, since
/// that package doesn't support the web platform — overdue items are
/// surfaced there via the in-app banner instead.
class NotificationsService {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (kIsWeb || _initialized) return;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  Future<void> notifyOverdue(List<OverdueItem> items) async {
    if (kIsWeb || items.isEmpty) return;
    await init();

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      await _plugin.show(
        id: item.eventType.index,
        title: 'PawLog reminder',
        body: '${item.eventType.label} is overdue.',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'overdue_reminders',
            'Overdue Reminders',
            importance: Importance.defaultImportance,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    }
  }
}
