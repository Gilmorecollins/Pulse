import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pulse/core/database/database.dart';
import 'package:pulse/core/models/task_enums.dart';
import 'package:pulse/features/checkin/data/checkin_repository.dart';
import 'package:pulse/features/report/presentation/report_providers.dart';
import 'package:pulse/features/report/presentation/report_share.dart';
import 'package:pulse/features/today/data/today_repository.dart';
import 'package:pulse/features/today/presentation/task_tile.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  late PulseDatabase db;
  late TodayRepository today;
  late CheckInRepository checkIns;

  setUp(() {
    db = PulseDatabase.forTesting(NativeDatabase.memory());
    today = TodayRepository(db);
    checkIns = CheckInRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('date-scoped plans', () {
    test('getOrCreatePlanForDate reuses an existing plan for the same day', () async {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final first = await today.getOrCreatePlanForDate(tomorrow);
      final second = await today.getOrCreatePlanForDate(tomorrow);
      expect(second.id, first.id);
    });

    test('a task added for tomorrow does not appear in today\'s plan', () async {
      final todayPlan = await today.getOrCreateTodayPlan();
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final tomorrowPlan = await today.getOrCreatePlanForDate(tomorrow);

      await today.addTask(
        dailyPlanId: tomorrowPlan.id,
        title: 'Future task',
        plannedFor: tomorrow,
      );

      final todaysTasks = await today.getTasksForPlan(todayPlan.id);
      final tomorrowsTasks = await today.getTasksForPlan(tomorrowPlan.id);
      expect(todaysTasks, isEmpty);
      expect(tomorrowsTasks, hasLength(1));
      expect(tomorrowsTasks.first.title, 'Future task');
    });
  });

  group('addTask', () {
    test('persists an expected completion time when given one', () async {
      final plan = await today.getOrCreateTodayPlan();
      final finish = DateTime.now().add(const Duration(hours: 2));

      final task = await today.addTask(
        dailyPlanId: plan.id,
        title: 'Finish portfolio',
        expectedCompletionTime: finish,
      );

      // SQLite stores DateTime with second-level precision here (true of
      // every DateTime column in this schema, not specific to this
      // field) — irrelevant for a "finish by 3pm" reminder.
      expect(
        task.expectedCompletionTime!.difference(finish).inSeconds.abs(),
        lessThan(1),
      );
    });

    test('a task with no expected time has a null one', () async {
      final plan = await today.getOrCreateTodayPlan();
      final task = await today.addTask(dailyPlanId: plan.id, title: 'No time');
      expect(task.expectedCompletionTime, isNull);
    });
  });

  group('updateTaskDetails', () {
    test('edits title, moves the task to a new day, and updates its time', () async {
      final plan = await today.getOrCreateTodayPlan();
      final task = await today.addTask(dailyPlanId: plan.id, title: 'Draft');
      final newDay = DateTime.now().add(const Duration(days: 3));
      final newTime = DateTime(newDay.year, newDay.month, newDay.day, 15, 0);

      await today.updateTaskDetails(
        taskId: task.id,
        title: 'Final draft',
        plannedFor: newDay,
        expectedCompletionTime: newTime,
      );

      final updated = await today.getTaskById(task.id);
      expect(updated.title, 'Final draft');
      expect(updated.dailyPlanId, isNot(plan.id));
      expect(
        updated.expectedCompletionTime!.difference(newTime).inSeconds.abs(),
        lessThan(1),
      );
    });
  });

  group('moveTaskToDay', () {
    test('moves the task to the given day\'s plan and resets its state', () async {
      final plan = await today.getOrCreateTodayPlan();
      final task = await today.addTask(
        dailyPlanId: plan.id,
        title: 'Carry me',
        expectedCompletionTime: DateTime.now().add(const Duration(hours: 1)),
      );
      await today.setTaskStatus(task.id, TaskStatus.inProgress);
      await today.setExplanationNote(task.id, 'Ran out of time');

      final tomorrow = DateTime.now().add(const Duration(days: 1));
      await today.moveTaskToDay(task.id, tomorrow);

      final updated = await today.getTaskById(task.id);
      expect(updated.dailyPlanId, isNot(plan.id));
      expect(TaskStatus.fromDb(updated.status), TaskStatus.planned);
      expect(updated.expectedCompletionTime, isNull);
      expect(updated.completedAt, isNull);
      expect(updated.explanationNote, isNull);

      final todaysTasks = await today.getTasksForPlan(plan.id);
      expect(todaysTasks, isEmpty);
    });

    test('accepts a new expected completion time on the target day', () async {
      final plan = await today.getOrCreateTodayPlan();
      final task = await today.addTask(dailyPlanId: plan.id, title: 'Carry me');
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final newTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 0);

      await today.moveTaskToDay(
        task.id,
        tomorrow,
        newExpectedCompletionTime: newTime,
      );

      final updated = await today.getTaskById(task.id);
      expect(
        updated.expectedCompletionTime!.difference(newTime).inSeconds.abs(),
        lessThan(1),
      );
    });
  });

  group('getTasksWithPendingCheckIn', () {
    test('includes an incomplete task with a future completion time', () async {
      final plan = await today.getOrCreateTodayPlan();
      final future = DateTime.now().add(const Duration(hours: 1));
      final task = await today.addTask(
        dailyPlanId: plan.id,
        title: 'Pending',
        expectedCompletionTime: future,
      );

      final pending = await today.getTasksWithPendingCheckIn();
      expect(pending.map((t) => t.id), contains(task.id));
    });

    test('excludes a completed task even with a future completion time', () async {
      final plan = await today.getOrCreateTodayPlan();
      final future = DateTime.now().add(const Duration(hours: 1));
      final task = await today.addTask(
        dailyPlanId: plan.id,
        title: 'Done already',
        expectedCompletionTime: future,
      );
      await today.setTaskStatus(task.id, TaskStatus.completed);

      final pending = await today.getTasksWithPendingCheckIn();
      expect(pending.map((t) => t.id), isNot(contains(task.id)));
    });

    test('excludes a task with no expected completion time', () async {
      final plan = await today.getOrCreateTodayPlan();
      final task = await today.addTask(dailyPlanId: plan.id, title: 'No time');

      final pending = await today.getTasksWithPendingCheckIn();
      expect(pending.map((t) => t.id), isNot(contains(task.id)));
    });
  });

  group('watchTasksForDateRange', () {
    test('groups tasks by date and excludes days outside the range', () async {
      final today0 = DateTime.now();
      final inRangePlan = await today.getOrCreatePlanForDate(
        today0.add(const Duration(days: 2)),
      );
      final outOfRangePlan = await today.getOrCreatePlanForDate(
        today0.add(const Duration(days: 10)),
      );
      await today.addTask(
        dailyPlanId: inRangePlan.id,
        title: 'In range',
        plannedFor: today0.add(const Duration(days: 2)),
      );
      await today.addTask(
        dailyPlanId: outOfRangePlan.id,
        title: 'Out of range',
        plannedFor: today0.add(const Duration(days: 10)),
      );

      final result = await today
          .watchTasksForDateRange(today0, today0.add(const Duration(days: 6)))
          .first;

      final allTitles = result.values.expand((tasks) => tasks.map((t) => t.title));
      expect(allTitles, contains('In range'));
      expect(allTitles, isNot(contains('Out of range')));
    });
  });

  group('check-in bookkeeping', () {
    test('skipPendingCheckIn marks the latest pending row skipped, not left pending', () async {
      final plan = await today.getOrCreateTodayPlan();
      final task = await today.addTask(dailyPlanId: plan.id, title: 'Rescheduled');

      await checkIns.createPendingCheckIn(
        taskId: task.id,
        dailyPlanId: plan.id,
        scheduledFor: DateTime.now(),
      );
      await checkIns.skipPendingCheckIn(task.id);

      final rows = await (db.select(db.checkIns)
            ..where((c) => c.taskId.equals(task.id)))
          .get();
      expect(rows, hasLength(1));
      expect(rows.first.status, 'skipped');
    });

    test('markResponded marks the latest pending row responded', () async {
      final plan = await today.getOrCreateTodayPlan();
      final task = await today.addTask(dailyPlanId: plan.id, title: 'Done clean');

      await checkIns.createPendingCheckIn(
        taskId: task.id,
        dailyPlanId: plan.id,
        scheduledFor: DateTime.now(),
      );
      await checkIns.markResponded(taskId: task.id);

      final rows = await (db.select(db.checkIns)
            ..where((c) => c.taskId.equals(task.id)))
          .get();
      expect(rows.first.status, 'responded');
    });
  });

  group('setExplanationNote', () {
    test('is readable back off the task and shown in the report text', () async {
      final plan = await today.getOrCreateTodayPlan();
      final task = await today.addTask(
        dailyPlanId: plan.id,
        title: 'Watch app polish',
      );
      await today.setExplanationNote(task.id, 'Got pulled into a client call');
      await today.setTaskStatus(task.id, TaskStatus.cancelled);

      final updated = await today.getTaskById(task.id);
      expect(updated.explanationNote, 'Got pulled into a client call');

      final data = ReportViewData(plan: plan, tasks: [updated], reflection: null);
      final text = buildReportShareText(data);
      expect(text, contains('Watch app polish'));
      expect(text, contains('Got pulled into a client call'));
    });

    test(
      'a task with a note stops being "unresolved" once ended — '
      'regression: "End task" used to look like it did nothing, because '
      'TaskTile only checked for a note, not whether it was still open',
      () async {
        final plan = await today.getOrCreateTodayPlan();
        final task = await today.addTask(dailyPlanId: plan.id, title: 'Explain me');
        await today.setExplanationNote(task.id, 'Ran out of time');

        final stillOpen = await today.getTaskById(task.id);
        expect(isTaskResolved(stillOpen), isFalse);

        await today.setTaskStatus(task.id, TaskStatus.cancelled);
        final ended = await today.getTaskById(task.id);
        expect(isTaskResolved(ended), isTrue);
        expect(ended.explanationNote, 'Ran out of time');
      },
    );
  });

  group('buildReportShareText', () {
    test('a day with nothing planned says so rather than showing 0%', () async {
      final plan = await today.getOrCreateTodayPlan();
      final data = ReportViewData(plan: plan, tasks: const [], reflection: null);

      final text = buildReportShareText(data);
      expect(text, contains('No tasks planned'));
      expect(text, isNot(contains('0%')));
    });

    test('numbers tasks continuously under Done then Carry Forward, with '
        'each task\'s description shown', () async {
      final plan = await today.getOrCreateTodayPlan();
      final done = await today.addTask(
        dailyPlanId: plan.id,
        title: 'Visit branch',
        description: 'Met with officials to discuss options.',
      );
      await today.setTaskStatus(done.id, TaskStatus.completed);
      final open = await today.addTask(
        dailyPlanId: plan.id,
        title: 'Follow up with client',
        description: 'Estimate the period the statement is needed by.',
      );

      final data = ReportViewData(
        plan: plan,
        tasks: [
          await today.getTaskById(done.id),
          await today.getTaskById(open.id),
        ],
        reflection: null,
      );
      final text = buildReportShareText(data);

      expect(text, contains('🟢 *DONE*'));
      expect(text, contains('1. Visit branch ✅'));
      expect(text, contains('Met with officials to discuss options.'));
      expect(text, contains('🔴 *CARRY FORWARD TO THE NEXT DAY*'));
      expect(text, contains('2. Follow up with client'));
      expect(text, contains('Estimate the period the statement is needed by.'));
    });
  });
}
