import 'package:flutter/material.dart';

/// How often the scheduled-backup reminder fires — see
/// docs/ARCHITECTURE.md's "Backup" section. `off` means no reminder is
/// scheduled at all (manual "Back up now" in Settings still works
/// regardless).
enum BackupFrequency {
  off,
  daily,
  weekly,
  monthly;

  static BackupFrequency fromDb(String value) => switch (value) {
        'daily' => BackupFrequency.daily,
        'weekly' => BackupFrequency.weekly,
        'monthly' => BackupFrequency.monthly,
        _ => BackupFrequency.off,
      };

  String toDb() => name;
}

/// The user's scheduled-backup settings. [weekday] (1-7,
/// DateTime.monday..sunday) and [dayOfMonth] (1-31) are only meaningful
/// for their matching [frequency] — set once, when the schedule is
/// first turned on, to "whichever day you're setting this up on" rather
/// than asking the user to separately pick a day (see
/// docs/ARCHITECTURE.md's "Backup" section for why).
class BackupSchedule {
  const BackupSchedule({
    required this.frequency,
    required this.time,
    this.weekday,
    this.dayOfMonth,
  });

  final BackupFrequency frequency;
  final TimeOfDay time;
  final int? weekday;
  final int? dayOfMonth;
}
