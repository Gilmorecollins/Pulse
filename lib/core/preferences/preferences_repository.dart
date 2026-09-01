import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Onboarding-collected settings. Deliberately not a database table (see
/// docs/DATABASE.md) — this is small, single-user, device-local config,
/// not something that needs relational structure or history.
class PreferencesRepository {
  static const _keyOnboardingComplete = 'onboarding_complete';
  static const _keyName = 'user_name';
  static const _keyReportTime = 'report_time';
  static const _keyThemeMode = 'theme_mode';
  static const _keyNotificationsEnabled = 'notifications_enabled';
  static const _keyLastSyncedAt = 'drive_last_synced_at';

  Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingComplete) ?? false;
  }

  Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyName);
  }

  Future<void> setName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, name.trim());
  }

  Future<TimeOfDay?> getReportTime() async {
    final prefs = await SharedPreferences.getInstance();
    return _parseTime(prefs.getString(_keyReportTime));
  }

  Future<void> setReportTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyReportTime, _formatTime(time));
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

  Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotificationsEnabled) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsEnabled, enabled);
  }

  Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    switch (prefs.getString(_keyThemeMode)) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, mode.name);
  }

  /// When the last successful Drive backup or restore completed. Sync
  /// "enabled" state itself isn't separately tracked here — it's just
  /// whether GoogleDriveService has a signed-in account (see
  /// driveAccountProvider), which google_sign_in already persists across
  /// launches on its own.
  Future<DateTime?> getLastSyncedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt(_keyLastSyncedAt);
    return millis == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<void> setLastSyncedAt(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastSyncedAt, time.millisecondsSinceEpoch);
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
