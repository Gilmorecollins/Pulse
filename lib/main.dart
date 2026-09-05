import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/backup/backup_provider.dart';
import 'core/backup/google_drive_service.dart';
import 'core/notifications/notification_provider.dart';
import 'core/notifications/notification_service.dart';
import 'core/preferences/preferences_provider.dart';
import 'core/preferences/preferences_repository.dart';
import 'core/router/app_router.dart';
import 'features/backup/presentation/backup_providers.dart';
import 'features/checkin/presentation/checkin_scheduling.dart';
import 'features/recurrence/data/recurrence_repository.dart';
import 'features/recurrence/presentation/recurrence_providers.dart';
import 'features/today/presentation/today_providers.dart';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// The 'backup' notification only reminds — it doesn't upload anything
/// itself (no reliable way to run that silently at an exact time on
/// Android without the app's process running; see
/// docs/ARCHITECTURE.md's "Backup" section). This runs the actual
/// upload once the user taps it. A failure here isn't fatal: manual
/// "Back up now" in Settings still works, and the next scheduled
/// reminder tries again regardless.
Future<void> _runScheduledBackup(ProviderContainer container) async {
  try {
    await container.read(backupRepositoryProvider).backUpNow();
    await container
        .read(preferencesRepositoryProvider)
        .setLastSyncedAt(DateTime.now());
    container.invalidate(lastSyncedAtProvider);
  } catch (_) {
    // Swallowed deliberately — see comment above.
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final notificationService = NotificationService();
  // Never let notification setup block getting into the app at all —
  // this exact call has now frozen startup completely, twice, on a
  // stripped-resource release build (see android/app/src/main/res/raw/
  // keep.xml and docs/ARCHITECTURE.md's "Notifications" section): an
  // uncaught exception here happens before runApp(), so Flutter never
  // draws a first frame and the native splash just stays up forever.
  // Any other future initialize() failure on some other device/OEM
  // should degrade the same way (notifications just don't work yet)
  // rather than bricking the whole app.
  try {
    await notificationService.initialize();
  } catch (_) {
    // Swallowed deliberately — see comment above.
  }

  final storedThemeMode = await PreferencesRepository().getThemeMode();

  // No prompt — silently restores a previous Drive sign-in if one
  // exists. Deliberately not awaited: nothing in the first frame
  // (onboarding/Today) touches Drive state, and this could take
  // multiple seconds (up to its own internal 5s timeout) on a slow or
  // flaky connection to Google Play Services — most visible on
  // emulators — which was blocking runApp() and holding the native
  // splash up long after the app was otherwise ready. driveAccountProvider
  // watches GoogleDriveService.onAccountChanged, so Settings still
  // updates reactively the moment this resolves in the background.
  final driveService = GoogleDriveService();
  unawaited(driveService.initializeSilentSignIn());

  final container = ProviderContainer(
    overrides: [
      notificationServiceProvider.overrideWithValue(notificationService),
      themeModeProvider.overrideWith((ref) => storedThemeMode),
      googleDriveServiceProvider.overrideWithValue(driveService),
    ],
  );

  // A tapped notification should always open its matching screen, whether
  // the app was already running or this tap is what launched it.
  notificationService.onNotificationTap.listen((payload) {
    if (payload == 'reflection') {
      container.read(routerProvider).go('/reflection');
    } else if (payload != null && payload.startsWith('taskcheckin:')) {
      final taskId = payload.substring('taskcheckin:'.length);
      container.read(routerProvider).go('/checkin/$taskId');
    } else if (payload == 'backup') {
      _runScheduledBackup(container);
    }
  });

  // Re-sync OS-level alarms for any task that still needs a check-in —
  // covers a fresh reinstall wiping the notification plugin's own
  // persisted schedule while the Drift task data survives (the common
  // case during dev iteration; a real reboot is already handled by the
  // plugin's own boot receiver).
  final todayRepository = container.read(todayRepositoryProvider);
  final notificationServiceForResync = container.read(
    notificationServiceProvider,
  );
  for (final task in await todayRepository.getTasksWithPendingCheckIn()) {
    final time = task.expectedCompletionTime;
    if (time != null) {
      await notificationServiceForResync.scheduleTaskCheckIn(
        task.id,
        task.title,
        time,
      );
    }
  }

  // Materialize any recurring tasks due to appear soon (see
  // RecurrenceRepository) and schedule check-ins for the new occurrences
  // that need one — same "create on first touch" spirit as the resync
  // loop above, just for recurrence instead of alarms.
  final recurrenceRepository = container.read(recurrenceRepositoryProvider);
  final today = _dateOnly(DateTime.now());
  final newOccurrences = await recurrenceRepository
      .materializeOccurrencesForRange(
        today,
        today.add(RecurrenceRepository.materializationWindow),
      );
  for (final task in newOccurrences) {
    final time = task.expectedCompletionTime;
    if (time != null) {
      await scheduleTaskCheckInFromContainer(
        container,
        taskId: task.id,
        taskTitle: task.title,
        dailyPlanId: task.dailyPlanId,
        completionTime: time,
      );
    }
  }

  runApp(
    UncontrolledProviderScope(container: container, child: const PulseApp()),
  );
}
