import '../core/database.dart';
import '../models/event_type.dart';
import '../providers/notification_settings_provider.dart';

class NotificationsService {
  static final NotificationsService _instance = NotificationsService._();
  factory NotificationsService() => _instance;
  NotificationsService._();

  static Future<void> initializeTimezone() async {}

  Future<void> init() async {}

  Future<void> rescheduleAll({
    required List<dynamic> events,
    required Map<CatEventType, EffectiveSetting> settings,
    List<MedicationSchedule> medicationSchedules = const [],
  }) async {}
}
