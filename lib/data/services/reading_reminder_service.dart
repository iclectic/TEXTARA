import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Local-only reading reminders. Defaults off; never used for marketing.
class ReadingReminderService {
  ReadingReminderService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  static const _channelId = 'reading_reminders';
  static const _notificationId = 1001;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  Future<void> scheduleDaily({required int hour, required int minute}) async {
    await init();
    const android = AndroidNotificationDetails(
      _channelId,
      'Reading reminders',
      channelDescription: 'Optional local reminders to continue reading',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(
      android: android,
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.periodicallyShow(
      _notificationId,
      'Time to read',
      'Pick up where you left off in Textara — local reminder only.',
      RepeatInterval.daily,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancel() async {
    await init();
    await _plugin.cancel(_notificationId);
  }
}
