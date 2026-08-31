import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/notifications/notification_provider.dart';
import 'core/notifications/notification_service.dart';
import 'core/preferences/preferences_provider.dart';
import 'core/preferences/preferences_repository.dart';
import 'core/router/app_router.dart';
import 'features/today/presentation/today_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final notificationService = NotificationService();
  await notificationService.initialize();

  final storedThemeMode = await PreferencesRepository().getThemeMode();

  final container = ProviderContainer(
    overrides: [
      notificationServiceProvider.overrideWithValue(notificationService),
      themeModeProvider.overrideWith((ref) => storedThemeMode),
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

  runApp(
    UncontrolledProviderScope(container: container, child: const PulseApp()),
  );
}
