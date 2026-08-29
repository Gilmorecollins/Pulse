import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/database.dart';

const _uuid = Uuid();

/// One row of report history — a day plus its stored completion rate,
/// enough to back the History tab's list without loading full task data.
class ReportSummary {
  ReportSummary({
    required this.dailyPlanId,
    required this.date,
    required this.completionRate,
  });

  final String dailyPlanId;
  final DateTime date;
  final double completionRate;
}

class ReportRepository {
  ReportRepository(this._db);

  final PulseDatabase _db;

  Future<DailyReport?> getReportForPlan(String dailyPlanId) {
    return (_db.select(_db.dailyReports)
          ..where((r) => r.dailyPlanId.equals(dailyPlanId)))
        .getSingleOrNull();
  }

  /// A day has at most one report — regenerating (e.g. re-saving a
  /// reflection) overwrites it rather than creating a duplicate.
  Future<DailyReport> generateReport({
    required String dailyPlanId,
    required double completionRate,
  }) async {
    final existing = await getReportForPlan(dailyPlanId);
    if (existing != null) {
      await (_db.update(_db.dailyReports)
            ..where((r) => r.id.equals(existing.id)))
          .write(
        DailyReportsCompanion(
          completionRate: Value(completionRate),
          generatedAt: Value(DateTime.now()),
        ),
      );
      return existing.copyWith(
        completionRate: completionRate,
        generatedAt: DateTime.now(),
      );
    }

    final report = DailyReportsCompanion.insert(
      id: _uuid.v4(),
      dailyPlanId: dailyPlanId,
      completionRate: completionRate,
      generatedAt: DateTime.now(),
    );
    return _db.into(_db.dailyReports).insertReturning(report);
  }

  /// Fills in the AI-generated summary after the report itself already
  /// exists — summary generation is best-effort and shouldn't block or
  /// fail the report's creation (see docs/ARCHITECTURE.md: AI is always a
  /// suggestion layered on a working app, never a dependency of it).
  Future<void> updateAiSummary(String dailyPlanId, String summary) async {
    final existing = await getReportForPlan(dailyPlanId);
    if (existing == null) return;
    await (_db.update(_db.dailyReports)..where((r) => r.id.equals(existing.id)))
        .write(DailyReportsCompanion(aiSummary: Value(summary)));
  }

  Stream<List<ReportSummary>> watchReportHistory() {
    final query = _db.select(_db.dailyReports).join([
      innerJoin(
        _db.dailyPlans,
        _db.dailyPlans.id.equalsExp(_db.dailyReports.dailyPlanId),
      ),
    ])..orderBy([OrderingTerm.desc(_db.dailyPlans.date)]);

    return query.watch().map(
          (rows) => rows
              .map(
                (row) => ReportSummary(
                  dailyPlanId: row.readTable(_db.dailyPlans).id,
                  date: row.readTable(_db.dailyPlans).date,
                  completionRate:
                      row.readTable(_db.dailyReports).completionRate,
                ),
              )
              .toList(),
        );
  }
}
