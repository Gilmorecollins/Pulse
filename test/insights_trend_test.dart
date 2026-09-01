import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pulse/core/database/database.dart';
import 'package:pulse/features/insights/data/insights_repository.dart';
import 'package:pulse/features/today/data/today_repository.dart';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  late PulseDatabase db;
  late TodayRepository today;
  late InsightsRepository insights;

  setUp(() {
    db = PulseDatabase.forTesting(NativeDatabase.memory());
    today = TodayRepository(db);
    insights = InsightsRepository(db, today);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedReport(DateTime day, double completionRate) async {
    final plan = await today.getOrCreatePlanForDate(day);
    await db.into(db.dailyReports).insert(
          DailyReportsCompanion.insert(
            id: 'report-${plan.id}',
            dailyPlanId: plan.id,
            completionRate: completionRate,
            generatedAt: DateTime.now(),
          ),
        );
  }

  test('empty history returns an empty list', () async {
    final trend = await insights.computeCompletionTrend();
    expect(trend, isEmpty);
  });

  test('returns points ascending by date', () async {
    final today0 = _dateOnly(DateTime.now());
    await seedReport(today0, 0.5);
    await seedReport(today0.subtract(const Duration(days: 2)), 0.2);
    await seedReport(today0.subtract(const Duration(days: 1)), 0.8);

    final trend = await insights.computeCompletionTrend();

    expect(trend, hasLength(3));
    for (var i = 1; i < trend.length; i++) {
      expect(trend[i].date.isAfter(trend[i - 1].date), isTrue);
    }
    expect(trend.last.date, today0);
    expect(trend.last.completionRate, 0.5);
  });

  test('the since filter excludes older rows', () async {
    final today0 = _dateOnly(DateTime.now());
    await seedReport(today0, 1.0);
    await seedReport(today0.subtract(const Duration(days: 30)), 0.1);

    final trend = await insights.computeCompletionTrend(
      since: today0.subtract(const Duration(days: 7)),
    );

    expect(trend, hasLength(1));
    expect(trend.first.date, today0);
  });
}
