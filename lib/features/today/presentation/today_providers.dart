import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../../core/database/database_provider.dart';
import '../data/today_repository.dart';

final todayRepositoryProvider = Provider<TodayRepository>((ref) {
  return TodayRepository(ref.watch(databaseProvider));
});

/// Today's plan, created lazily on first access.
final todayPlanProvider = FutureProvider<DailyPlan>((ref) async {
  return ref.watch(todayRepositoryProvider).getOrCreateTodayPlan();
});

/// Live task list for today's plan. Empty while the plan is still loading.
final todayTasksProvider = StreamProvider<List<Task>>((ref) {
  final planAsync = ref.watch(todayPlanProvider);
  return planAsync.when(
    data: (plan) =>
        ref.watch(todayRepositoryProvider).watchTasksForPlan(plan.id),
    loading: () => const Stream.empty(),
    error: (err, st) => Stream.error(err, st),
  );
});
