import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin plugin;

  NotificationService(this.plugin);

  Future<void> scheduleDaily(TimeOfDay time) async {
    tz.initializeTimeZones();

    final now = tz.TZDateTime.now(tz.local);

    final schedule = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    await plugin.zonedSchedule(
      1,
      'DiaWell Reminder',
      'Time to log your glucose!',
      schedule.isBefore(now)
          ? schedule.add(const Duration(days: 1))
          : schedule,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_channel',
          'Daily Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'daily_reminder',
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancel() async {
    await plugin.cancel(1);
  }
}
