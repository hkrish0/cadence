import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(settings);
  }

  // Schedules a local notification 24 hours from now reminding the user
  // that the next video in [trackTitle] is ready to unlock.
  static Future<void> scheduleUnlockReminder({
    required int id,
    required String trackTitle,
    required int videoNumber,
  }) async {
    final scheduledTime =
        tz.TZDateTime.now(tz.local).add(const Duration(hours: 24));

    await _plugin.zonedSchedule(
      id,
      'Time to continue "$trackTitle"',
      'Video $videoNumber is ready — complete your quiz to unlock it.',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'cadence_unlock',
          'Video Unlock Reminders',
          channelDescription:
              'Notifies you when the next video is ready to unlock.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelNotification(int id) => _plugin.cancel(id);
}
