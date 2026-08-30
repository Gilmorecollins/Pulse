import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Wraps local notification scheduling for Pulse (see
/// docs/ARCHITECTURE.md — "Notifications / check-in scheduling"). Check-ins
/// are per-task: each task with an expected completion time gets its own
/// one-time notification 5 minutes before, rather than one fixed daily
/// prompt.
class NotificationService {
  NotificationService() : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final _tapController = StreamController<String?>.broadcast();

  static const reflectionNotificationId = 2;
  static const checkInLeadTime = Duration(minutes: 5);
  // _v2 (custom sound) — Android notification channels are immutable
  // once created, so changing the sound requires a new channel id rather
  // than editing the existing one; an install that already created the
  // old channel would otherwise keep the default sound forever.
  static const _checkInChannelId = 'pulse_checkin_v2';
  static const _reflectionChannelId = 'pulse_reflection_v2';
  static const _checkInSound = RawResourceAndroidNotificationSound(
    'f1_checkin',
  );

  bool _initialized = false;

  /// Fires with the notification payload whenever the user taps a
  /// notification (including the one that launched the app, replayed once
  /// a listener attaches).
  Stream<String?> get onNotificationTap => _tapController.stream;

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone));
    } catch (_) {
      // Falls back to UTC if the platform timezone can't be resolved.
      // Check-in scheduling will still work, just not at the exact local
      // wall-clock time until this succeeds on a later launch.
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        _tapController.add(response.payload);
      },
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _checkInChannelId,
        'Pulse Check-in',
        description: "Pulse's per-task check-ins.",
        importance: Importance.high,
        sound: _checkInSound,
      ),
    );
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _reflectionChannelId,
        'Pulse Reflection',
        description: "Pulse's end-of-day reflection.",
        importance: Importance.high,
        sound: _checkInSound,
      ),
    );

    _initialized = true;

    if (launchDetails?.didNotificationLaunchApp ?? false) {
      // Let the widget tree finish building before the router acts on it.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tapController.add(launchDetails!.notificationResponse?.payload);
      });
    }
  }

  /// Requests POST_NOTIFICATIONS (Android 13+) and exact-alarm scheduling
  /// permission (Android 12+). Safe to call repeatedly — a no-op once
  /// granted.
  Future<void> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
  }

  /// A stable per-task notification ID derived from the task's UUID, so
  /// the same task always maps to the same OS-level id and can be
  /// cancelled later just by recomputing it — no separate ID-tracking
  /// table needed. Masked to a positive 31-bit int (platform requirement)
  /// and offset well clear of the fixed `reflectionNotificationId`.
  static int _taskNotificationId(String taskId) =>
      1000 + (taskId.hashCode & 0x7fffffff) % 1000000000;

  /// Schedules a one-time check-in [checkInLeadTime] before
  /// [completionTime]. Silently skips if that moment has already passed —
  /// nothing to remind about.
  Future<void> scheduleTaskCheckIn(
    String taskId,
    String taskTitle,
    DateTime completionTime,
  ) async {
    final fireAt = completionTime.subtract(checkInLeadTime);
    if (fireAt.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      _taskNotificationId(taskId),
      '⚡ Pulse Check-in',
      "Almost time for '$taskTitle' — how's it going?",
      tz.TZDateTime.from(fireAt, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _checkInChannelId,
          'Pulse Check-in',
          channelDescription: "Pulse's per-task check-ins.",
          importance: Importance.high,
          priority: Priority.high,
          sound: _checkInSound,
          playSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'taskcheckin:$taskId',
    );
  }

  Future<void> cancelTaskCheckIn(String taskId) =>
      _plugin.cancel(_taskNotificationId(taskId));

  Future<void> scheduleDailyReflection(TimeOfDay time) async {
    await _plugin.zonedSchedule(
      reflectionNotificationId,
      '🌙 Daily Reflection',
      "Let's look back on today.",
      _nextInstanceOf(time),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _reflectionChannelId,
          'Pulse Reflection',
          channelDescription: "Pulse's end-of-day reflection.",
          importance: Importance.high,
          priority: Priority.high,
          sound: _checkInSound,
          playSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'reflection',
    );
  }

  Future<void> cancelReflection() => _plugin.cancel(reflectionNotificationId);

  tz.TZDateTime _nextInstanceOf(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  void dispose() => _tapController.close();
}
