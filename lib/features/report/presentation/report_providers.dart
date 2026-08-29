import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../../core/database/database_provider.dart';
import '../../reflection/presentation/reflection_providers.dart';
import '../../today/presentation/today_providers.dart';
import '../data/report_repository.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository(ref.watch(databaseProvider));
});

final reportHistoryProvider = StreamProvider<List<ReportSummary>>((ref) {
  return ref.watch(reportRepositoryProvider).watchReportHistory();
});

final planByIdProvider = FutureProvider.family<DailyPlan, String>((
  ref,
  planId,
) {
  return ref.watch(todayRepositoryProvider).getPlanById(planId);
});

final reflectionForPlanProvider =
    FutureProvider.family<DailyReflection?, String>((ref, planId) {
      return ref
          .watch(reflectionRepositoryProvider)
          .getReflectionForPlan(planId);
    });

/// Everything the report screen needs for one day, fetched as a fixed
/// snapshot — a report reflects a moment in time, not a live view.
class ReportViewData {
  ReportViewData({
    required this.plan,
    required this.tasks,
    required this.reflection,
    required this.report,
  });

  final DailyPlan plan;
  final List<Task> tasks;
  final DailyReflection? reflection;
  final DailyReport? report;
}

final reportViewDataProvider = FutureProvider.family<ReportViewData, String>((
  ref,
  planId,
) async {
  final todayRepo = ref.watch(todayRepositoryProvider);
  final reflectionRepo = ref.watch(reflectionRepositoryProvider);
  final reportRepo = ref.watch(reportRepositoryProvider);

  final plan = await todayRepo.getPlanById(planId);
  final tasks = await todayRepo.getTasksForPlan(planId);
  final reflection = await reflectionRepo.getReflectionForPlan(planId);
  final report = await reportRepo.getReportForPlan(planId);

  return ReportViewData(
    plan: plan,
    tasks: tasks,
    reflection: reflection,
    report: report,
  );
});
