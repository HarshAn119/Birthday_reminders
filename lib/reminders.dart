import 'dart:io';
import 'dart:ui' show Color;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'entry.dart';
import 'themes.dart';

final _plugin = FlutterLocalNotificationsPlugin();
final _android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
var _askedExact = false;
Future<void> _queue = Future.value(); // init + every reschedule run one at a time

Future<void> initReminders() => _queue = _init();

Future<void> _init() async {
  tzdata.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation((await FlutterTimezone.getLocalTimezone()).identifier));
  await _plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('ic_notification'),
      iOS: DarwinInitializationSettings(),
    ),
  );
}

/// Replaces every pending reminder with the next batch, worded for [theme].
/// Called on launch and after every change, which is what keeps the batch rolling.
/// shortcut: if the app isn't opened for ~2 years (iPhone: until 64 reminders fire), they run out; add a background refresh task if that ever matters.
Future<void> reschedule(List<Entry> entries, BdayTheme theme) {
  final snapshot = [...entries];
  return _queue = _queue.catchError((_) {}).then((_) => _reschedule(snapshot, theme));
}

Future<void> _reschedule(List<Entry> entries, BdayTheme theme) async {
  await _plugin.cancelAll();
  if (entries.isEmpty) return;

  var mode = AndroidScheduleMode.exactAllowWhileIdle;
  final android = _android;
  if (android != null) {
    await android.requestNotificationsPermission();
    if (await android.canScheduleExactNotifications() != true && !_askedExact) {
      _askedExact = true; // opens a system settings page, so only once per launch
      await android.requestExactAlarmsPermission();
    }
    if (await android.canScheduleExactNotifications() != true) mode = AndroidScheduleMode.inexactAllowWhileIdle;
  }

  // iPhone keeps at most 64 pending; Android has no cap but some makers limit an app to 500 alarms.
  final batch = upcoming(entries, DateTime.now(), limit: Platform.isIOS ? 64 : 400, years: 2);
  const details = NotificationDetails(
    android: AndroidNotificationDetails('birthdays', 'Birthdays',
        channelDescription: 'Midnight reminders on the day',
        icon: 'ic_notification',
        color: Color(0xFFB5533C),
        importance: Importance.high,
        priority: Priority.high),
    iOS: DarwinNotificationDetails(),
  );
  for (var i = 0; i < batch.length; i++) {
    final o = batch[i];
    final (title, body) = theme.notification(o.entry, o.entry.ageIn(o.at.year));
    await _plugin.zonedSchedule(
      id: i,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime(tz.local, o.at.year, o.at.month, o.at.day),
      notificationDetails: details,
      androidScheduleMode: mode,
    );
  }
}
