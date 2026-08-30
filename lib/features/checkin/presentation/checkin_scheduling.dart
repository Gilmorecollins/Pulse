import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/notification_provider.dart';
import '../../../core/notifications/notification_service.dart';
import 'checkin_providers.dart';

/// Arranges a task's check-in — a `CheckIns` row (so Insights' response
/// consistency metric counts it whether or not the user ever engages,
/// since it's recorded at schedule time, not tap time) and the matching
/// OS notification. Used by both the Add Task flow and the check-in
/// screen's "need more time" action so the two stay in sync rather than
/// duplicating this pairing at each call site.
///
/// Callers are responsible for the task's own `expectedCompletionTime`
/// field — this only handles the check-in bookkeeping and the alarm.
Future<void> scheduleTaskCheckIn(
  WidgetRef ref, {
  required String taskId,
  required String taskTitle,
  required String dailyPlanId,
  required DateTime completionTime,
}) async {
  final checkInRepo = ref.read(checkInRepositoryProvider);
  final notifications = ref.read(notificationServiceProvider);

  await checkInRepo.createPendingCheckIn(
    taskId: taskId,
    dailyPlanId: dailyPlanId,
    scheduledFor: completionTime.subtract(NotificationService.checkInLeadTime),
  );
  await notifications.scheduleTaskCheckIn(taskId, taskTitle, completionTime);
}
