import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Wraps local notification scheduling for Pulse's daily check-in (see
/// docs/ARCHITECTURE.md — "Notifications / check-in scheduling"). v1
/// schedules exactly one repeating daily notification; multiple
/// check-ins/day is deferred to ROADMAP Phase 10, which needs its own
/// reliability pass under Android's Doze/battery-optimization behavior.
class NotificationService {
  NotificationService() : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final _tapController = StreamController<String?>.broadcast();

  static const checkInNotificationId = 1;
  static const reflectionNotificationId = 2;
  static const _checkInChannelId = 'pulse_checkin';
  static const _reflectionChannelId = 'pulse_reflection';

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
        description: "Pulse's daily check-in on how your day is going.",
        importance: Importance.high,
      ),
    );
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _reflectionChannelId,
        'Pulse Reflection',
        description: "Pulse's end-of-day reflection.",
        importance: Importance.high,
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

  Future<void> scheduleDailyCheckIn(TimeOfDay time) async {
    await _plugin.zonedSchedule(
      checkInNotificationId,
      '⚡ Pulse Check-in',
      'What are you working on right now?',
      _nextInstanceOf(time),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _checkInChannelId,
          'Pulse Check-in',
          channelDescription: "Pulse's daily check-in on how your day is going.",
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'checkin',
    );
  }

  Future<void> cancelCheckIn() => _plugin.cancel(checkInNotificationId);

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
