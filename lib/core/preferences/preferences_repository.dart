import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Onboarding-collected settings. Deliberately not a database table (see
/// docs/DATABASE.md) — this is small, single-user, device-local config,
/// not something that needs relational structure or history.
class PreferencesRepository {
  static const _keyOnboardingComplete = 'onboarding_complete';
  static const _keyName = 'user_name';
  static const _keyReportTime = 'report_time';

  Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingComplete) ?? false;
  }

  Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyName);
  }

  Future<TimeOfDay?> getReportTime() async {
    final prefs = await SharedPreferences.getInstance();
    return _parseTime(prefs.getString(_keyReportTime));
  }

  Future<void> completeOnboarding({
    required String name,
    required TimeOfDay reportTime,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, name.trim());
    await prefs.setString(_keyReportTime, _formatTime(reportTime));
    await prefs.setBool(_keyOnboardingComplete, true);
  }

  String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';

  TimeOfDay? _parseTime(String? value) {
    if (value == null) return null;
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }
}
