import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin plugin;

  NotificationService(this.plugin);

  Future<void> scheduleDaily(TimeOfDay time) async {
    tz.initializeTimeZones();

    final now = tz.TZDateTime.now(tz.local);

    var schedule = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (schedule.isBefore(now)) {
      schedule = schedule.add(const Duration(days: 1));
    }

    await plugin.zonedSchedule(
      1,
      'DiaWell Reminder',
      'Time to log your glucose!',
      schedule,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_channel',
          'Daily Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_reminder',
    );
  }

  Future<void> cancel() async {
    await plugin.cancel(1);
  }
}
