import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/notification_provider.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/preferences/preferences_provider.dart';
import '../../../core/preferences/preferences_repository.dart';
import '../data/checkin_repository.dart';
import 'checkin_providers.dart';

/// Arranges a task's check-in — a `CheckIns` row (so Insights' response
/// consistency metric counts it whether or not the user ever engages,
/// since it's recorded at schedule time, not tap time) and the matching
/// OS notification. Used by both the Add Task flow and the check-in
/// screen's "need more time" action so the two stay in sync rather than
/// duplicating this pairing at each call site.
///
/// A no-op if notifications are turned off in Settings — no point
/// creating a check-in that can never fire and would just look like an
/// ignored one later.
///
/// Callers are responsible for the task's own `expectedCompletionTime`
/// field — this only handles the check-in bookkeeping and the alarm.
Future<void> scheduleTaskCheckIn(
  WidgetRef ref, {
  required String taskId,
  required String taskTitle,
  required String dailyPlanId,
  required DateTime completionTime,
}) {
  return _scheduleTaskCheckIn(
    preferences: ref.read(preferencesRepositoryProvider),
    checkInRepo: ref.read(checkInRepositoryProvider),
    notifications: ref.read(notificationServiceProvider),
    taskId: taskId,
    taskTitle: taskTitle,
    dailyPlanId: dailyPlanId,
    completionTime: completionTime,
  );
}

/// Same as [scheduleTaskCheckIn], but usable during app startup (see
/// lib/main.dart's recurring-task materialization step), before a widget
/// tree — and therefore a WidgetRef — exists yet. A bare ProviderContainer
/// exposes the same `.read()` shape, so the actual scheduling logic is
/// shared via [_scheduleTaskCheckIn] rather than duplicated.
Future<void> scheduleTaskCheckInFromContainer(
  ProviderContainer container, {
  required String taskId,
  required String taskTitle,
  required String dailyPlanId,
  required DateTime completionTime,
}) {
  return _scheduleTaskCheckIn(
    preferences: container.read(preferencesRepositoryProvider),
    checkInRepo: container.read(checkInRepositoryProvider),
    notifications: container.read(notificationServiceProvider),
    taskId: taskId,
    taskTitle: taskTitle,
    dailyPlanId: dailyPlanId,
    completionTime: completionTime,
  );
}

Future<void> _scheduleTaskCheckIn({
  required PreferencesRepository preferences,
  required CheckInRepository checkInRepo,
  required NotificationService notifications,
  required String taskId,
  required String taskTitle,
  required String dailyPlanId,
  required DateTime completionTime,
}) async {
  final enabled = await preferences.getNotificationsEnabled();
  if (!enabled) return;

  await checkInRepo.createPendingCheckIn(
    taskId: taskId,
    dailyPlanId: dailyPlanId,
    scheduledFor: completionTime.subtract(NotificationService.checkInLeadTime),
  );
  await notifications.scheduleTaskCheckIn(taskId, taskTitle, completionTime);
}
