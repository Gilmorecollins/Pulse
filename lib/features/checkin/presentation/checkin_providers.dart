import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/models/task_enums.dart';
import '../../today/presentation/today_providers.dart';
import '../data/checkin_repository.dart';

final checkInRepositoryProvider = Provider<CheckInRepository>((ref) {
  return CheckInRepository(ref.watch(databaseProvider));
});

final todayCheckInProvider = FutureProvider<CheckIn>((ref) async {
  final plan = await ref.watch(todayPlanProvider.future);
  return ref.watch(checkInRepositoryProvider).getOrCreateTodayCheckIn(plan.id);
});

/// Tasks the check-in should ask about — anything not already finished.
final openTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final tasksAsync = ref.watch(todayTasksProvider);
  return tasksAsync.whenData(
    (tasks) => tasks.where((t) {
      final status = TaskStatus.fromDb(t.status);
      return status != TaskStatus.completed && status != TaskStatus.cancelled;
    }).toList(),
  );
});
