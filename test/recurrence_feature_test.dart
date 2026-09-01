import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pulse/core/database/database.dart';
import 'package:pulse/core/models/task_enums.dart';
import 'package:pulse/features/insights/data/insights_repository.dart';
import 'package:pulse/features/recurrence/data/recurrence_repository.dart';
import 'package:pulse/features/today/data/today_repository.dart';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  late PulseDatabase db;
  late TodayRepository today;
  late RecurrenceRepository recurrence;

  setUp(() {
    db = PulseDatabase.forTesting(NativeDatabase.memory());
    today = TodayRepository(db);
    recurrence = RecurrenceRepository(db, today);
  });

  tearDown(() async {
    await db.close();
  });

  group('createRule', () {
    test('a daily rule materializes an occurrence for today', () async {
      final start = _dateOnly(DateTime.now());
      final result = await recurrence.createRule(
        title: 'Stretch',
        frequency: RecurrenceFrequency.daily,
        startDate: start,
      );

      expect(result.occurrences, isNotEmpty);
      expect(
        result.occurrences.any(
          (t) => t.plannedFor == start && t.title == 'Stretch',
        ),
        isTrue,
      );
      expect(
        result.occurrences.every((t) => t.recurrenceRuleId == result.rule.id),
        isTrue,
      );
    });

    test('a weekly rule only materializes on its chosen weekdays', () async {
      final start = _dateOnly(DateTime.now());
      // Every day in the window has a distinct ISO weekday, so a rule
      // scoped to exactly one weekday should produce exactly one
      // occurrence in a 13-day window.
      final targetWeekday = start.weekday;
      final result = await recurrence.createRule(
        title: 'Team sync',
        frequency: RecurrenceFrequency.weekly,
        daysOfWeek: [targetWeekday],
        startDate: start,
      );

      expect(
        result.occurrences.every((t) => t.plannedFor.weekday == targetWeekday),
        isTrue,
      );
      expect(result.occurrences, isNotEmpty);
    });
  });

  group('materializeOccurrencesForRange', () {
    test('is idempotent across repeated calls over the same range', () async {
      final start = _dateOnly(DateTime.now());
      await recurrence.createRule(
        title: 'Journal',
        frequency: RecurrenceFrequency.daily,
        startDate: start,
      );

      final end = start.add(const Duration(days: 13));
      await recurrence.materializeOccurrencesForRange(start, end);
      await recurrence.materializeOccurrencesForRange(start, end);

      final allTasks = await db.select(db.tasks).get();
      final byDay = <DateTime>{};
      for (final t in allTasks) {
        expect(byDay.contains(t.plannedFor), isFalse, reason: 'duplicate occurrence for ${t.plannedFor}');
        byDay.add(t.plannedFor);
      }
    });
  });

  group('deleteRule', () {
    test(
      'removes future planned occurrences but leaves completed history, '
      'detached from the rule',
      () async {
        final start = _dateOnly(DateTime.now());
        final result = await recurrence.createRule(
          title: 'Log expenses',
          frequency: RecurrenceFrequency.daily,
          startDate: start,
        );
        final ruleId = result.rule.id;

        // Complete today's occurrence — this one should survive deletion.
        final todaysOccurrence = result.occurrences.firstWhere(
          (t) => t.plannedFor == start,
        );
        await today.setTaskStatus(todaysOccurrence.id, TaskStatus.completed);

        await recurrence.deleteRule(ruleId);

        final remaining = await db.select(db.tasks).get();
        expect(remaining, hasLength(1));
        expect(remaining.first.id, todaysOccurrence.id);
        expect(remaining.first.recurrenceRuleId, isNull);

        final rules = await db.select(db.recurrenceRules).get();
        expect(rules, isEmpty);
      },
    );
  });

  group('cross-feature visibility', () {
    test(
      'a materialized occurrence is counted in InsightsRepository '
      'averageDailyTasks (same as an ordinary user-added task)',
      () async {
        final start = _dateOnly(DateTime.now());
        await recurrence.createRule(
          title: 'Read',
          frequency: RecurrenceFrequency.daily,
          startDate: start,
          endDate: start, // exactly one occurrence, keeps the math simple
        );

        final plan = await today.getOrCreatePlanForDate(start);
        await db
            .into(db.dailyReports)
            .insert(
              DailyReportsCompanion.insert(
                id: 'report-1',
                dailyPlanId: plan.id,
                completionRate: 1.0,
                generatedAt: DateTime.now(),
              ),
            );

        final insights = InsightsRepository(db, today);
        final summary = await insights.computeSummary();
        expect(summary.averageDailyTasks, 1.0);
      },
    );
  });
}
