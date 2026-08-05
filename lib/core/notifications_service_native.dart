import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

import '../models/event_type.dart';
import '../providers/notification_settings_provider.dart';

class NotificationsService {
  static final NotificationsService _instance = NotificationsService._();
  factory NotificationsService() => _instance;
  NotificationsService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _overdueChannelId = 'overdue_reminders';
  static const _overdueChannelName = 'Overdue Reminders';
  static const _headsUpChannelId = 'upcoming_reminders';
  static const _headsUpChannelName = 'Upcoming Reminders';
  static const _headsUpMinThresholdHours = 168;
  static const _headsUpShortMaxThresholdHours = 336; // 14 days
  static const _headsUpShortLeadHours = 24;
  static const _headsUpLongLeadHours = 48;

  static Future<void> initializeTimezone() async {
    tz_data.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {}
  }

  Future<void> init() async {
    if (_initialized) return;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(settings: settings);

    final iOS = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await iOS?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  Future<void> rescheduleAll({
    required List<dynamic> events,
    required Map<CatEventType, EffectiveSetting> settings,
  }) async {
    await init();

    await _plugin.cancelAll();

    final lastLoggedByType = <CatEventType, DateTime>{};
    for (final event in events) {
      final type = CatEventTypeX.fromStorageKey(event.eventType as String);
      final loggedAt = event.loggedAt as DateTime;
      final current = lastLoggedByType[type];
      if (current == null || loggedAt.isAfter(current)) {
        lastLoggedByType[type] = loggedAt;
      }
    }

    final now = DateTime.now();

    for (final entry in settings.entries) {
      final type = entry.key;
      final setting = entry.value;
      if (!setting.enabled || setting.thresholdHours <= 0) continue;

      final lastLogged = lastLoggedByType[type];
      if (lastLogged == null) continue;

      final dueAt = lastLogged.add(Duration(hours: setting.thresholdHours));

      if (dueAt.isAfter(now)) {
        await _scheduleNotification(
          id: type.index,
          title: 'PawLog reminder',
          body: '${type.label} is overdue.',
          scheduledDate: dueAt,
        );

        if (setting.thresholdHours >= _headsUpMinThresholdHours) {
          final leadHours =
              setting.thresholdHours <= _headsUpShortMaxThresholdHours
                  ? _headsUpShortLeadHours
                  : _headsUpLongLeadHours;
          final headsUpAt =
              dueAt.subtract(Duration(hours: leadHours));
          if (headsUpAt.isAfter(now)) {
            final daysLeft =
                dueAt.difference(headsUpAt).inHours ~/ 24;
            await _scheduleNotification(
              id: type.index + 100,
              title: 'PawLog heads-up',
              body: '${type.label} is due in $daysLeft '
                  '${daysLeft == 1 ? 'day' : 'days'}.',
              scheduledDate: headsUpAt,
              channelId: _headsUpChannelId,
              channelName: _headsUpChannelName,
            );
          }
        }
      } else {
        await _plugin.show(
          id: type.index,
          title: 'PawLog reminder',
          body: '${type.label} is overdue.',
          notificationDetails: _notificationDetails(),
        );
      }
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? channelId,
    String? channelName,
  }) async {
    final tzDate = tz.TZDateTime(
      tz.local,
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      scheduledDate.hour,
      scheduledDate.minute,
      scheduledDate.second,
    );

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tzDate,
      notificationDetails: _notificationDetails(
        channelId: channelId ?? _overdueChannelId,
        channelName: channelName ?? _overdueChannelName,
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  NotificationDetails _notificationDetails({
    String channelId = _overdueChannelId,
    String channelName = _overdueChannelName,
  }) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.defaultImportance,
        ),
        iOS: const DarwinNotificationDetails(),
      );
}
