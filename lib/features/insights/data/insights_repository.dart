import 'package:drift/drift.dart';

import '../../../core/database/database.dart';
import '../../../core/models/task_enums.dart';
import '../../today/data/today_repository.dart';

/// Deliberately only reports what can be honestly computed from real data
/// — see docs/PRODUCT.md: these are "Pulse Insights", not a claim of
/// objective or psychological measurement. With few days tracked, that
/// just means the numbers reflect a small sample, not that they're wrong.
class InsightsSummary {
  InsightsSummary({
    required this.daysTracked,
    required this.averageCompletion,
    required this.bestDay,
    required this.bestDayCompletion,
    required this.averageDailyTasks,
    required this.checkInConsistency,
  });

  final int daysTracked;
  final double averageCompletion;
  final DateTime? bestDay;
  final double bestDayCompletion;
  final double averageDailyTasks;

  /// Null when there have been no check-ins at all yet (rather than 0%,
  /// which would misleadingly suggest a track record of missing them).
  final double? checkInConsistency;
}

class InsightsRepository {
  InsightsRepository(this._db, this._todayRepository);

  final PulseDatabase _db;
  final TodayRepository _todayRepository;

  Future<InsightsSummary> computeSummary() async {
    final reportRows = await (_db.select(_db.dailyReports).join([
      innerJoin(
        _db.dailyPlans,
        _db.dailyPlans.id.equalsExp(_db.dailyReports.dailyPlanId),
      ),
    ])).get();

    // 'skipped' (superseded by an edit before it ever fired) counts
    // neither as a response nor a miss — excluded from both sides of the
    // ratio rather than dragging consistency down for a proactive
    // reschedule.
    final checkIns = await (_db.select(
      _db.checkIns,
    )..where((c) => c.status.isNotValue('skipped'))).get();
    final responded = checkIns.where((c) => c.status == 'responded').length;
    final checkInConsistency = checkIns.isEmpty
        ? null
        : responded / checkIns.length;

    if (reportRows.isEmpty) {
      return InsightsSummary(
        daysTracked: 0,
        averageCompletion: 0,
        bestDay: null,
        bestDayCompletion: 0,
        averageDailyTasks: 0,
        checkInConsistency: checkInConsistency,
      );
    }

    final entries = reportRows.map((row) {
      final report = row.readTable(_db.dailyReports);
      final plan = row.readTable(_db.dailyPlans);
      return (
        planId: plan.id,
        date: plan.date,
        completionRate: report.completionRate,
      );
    }).toList();

    final averageCompletion =
        entries.map((e) => e.completionRate).reduce((a, b) => a + b) /
        entries.length;

    final best = entries.reduce(
      (a, b) => a.completionRate >= b.completionRate ? a : b,
    );

    var totalPlannedTasks = 0;
    for (final entry in entries) {
      final tasks = await _todayRepository.getTasksForPlan(entry.planId);
      totalPlannedTasks += tasks.where((t) {
        final source = TaskSource.fromDb(t.source);
        return source == TaskSource.morningPlan ||
            source == TaskSource.userAdded;
      }).length;
    }

    return InsightsSummary(
      daysTracked: entries.length,
      averageCompletion: averageCompletion,
      bestDay: best.date,
      bestDayCompletion: best.completionRate,
      averageDailyTasks: totalPlannedTasks / entries.length,
      checkInConsistency: checkInConsistency,
    );
  }
}
