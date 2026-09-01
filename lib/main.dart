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
import 'features/checkin/presentation/checkin_scheduling.dart';
import 'features/recurrence/data/recurrence_repository.dart';
import 'features/recurrence/presentation/recurrence_providers.dart';
import 'features/today/presentation/today_providers.dart';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final notificationService = NotificationService();
  await notificationService.initialize();

  final storedThemeMode = await PreferencesRepository().getThemeMode();

  // No prompt — silently restores a previous Drive sign-in if one
  // exists, so Settings shows the right account state immediately.
  final driveService = GoogleDriveService();
  await driveService.initializeSilentSignIn();

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
