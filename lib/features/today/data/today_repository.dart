import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/database.dart';
import '../../../core/models/task_enums.dart';

const _uuid = Uuid();

/// Normalizes a DateTime to just its calendar date (no time-of-day), since
/// a DailyPlan is keyed one-per-day.
DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

class TodayRepository {
  TodayRepository(this._db);

  final PulseDatabase _db;

  /// Returns the plan for a given calendar day, creating an empty one if
  /// it doesn't exist yet. The one place both "add a task for tomorrow"
  /// and "carry a task to tomorrow" go through — a plan is just scoped to
  /// a date, today has no special status beyond being the common case.
  Future<DailyPlan> getOrCreatePlanForDate(DateTime date) async {
    final day = _dateOnly(date);
    final existing = await (_db.select(_db.dailyPlans)
          ..where((p) => p.date.equals(day)))
        .getSingleOrNull();
    if (existing != null) return existing;

    final plan = DailyPlansCompanion.insert(
      id: _uuid.v4(),
      date: day,
      createdAt: DateTime.now(),
    );
    final id = await _db.into(_db.dailyPlans).insertReturning(plan);
    return id;
  }

  Future<DailyPlan> getOrCreateTodayPlan() =>
      getOrCreatePlanForDate(DateTime.now());

  Future<DailyPlan> getPlanById(String id) {
    return (_db.select(_db.dailyPlans)..where((p) => p.id.equals(id)))
        .getSingle();
  }

  Stream<List<Task>> watchTasksForPlan(String dailyPlanId) {
    return (_db.select(_db.tasks)
          ..where((t) => t.dailyPlanId.equals(dailyPlanId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  /// One-shot fetch, for views that render a fixed snapshot (e.g. a
  /// generated report) rather than needing live updates.
  Future<List<Task>> getTasksForPlan(String dailyPlanId) {
    return (_db.select(_db.tasks)
          ..where((t) => t.dailyPlanId.equals(dailyPlanId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<Task> getTaskById(String taskId) {
    return (_db.select(_db.tasks)..where((t) => t.id.equals(taskId)))
        .getSingle();
  }

  /// Tasks with a check-in still to come — an incomplete task with an
  /// expected completion time in the future. Used to re-sync OS-level
  /// alarms on app start (see lib/main.dart) in case the plugin's own
  /// persisted schedule was wiped (e.g. a fresh reinstall during dev)
  /// while the task data survived.
  Future<List<Task>> getTasksWithPendingCheckIn() {
    return (_db.select(_db.tasks)
          ..where(
            (t) =>
                t.expectedCompletionTime.isBiggerThanValue(DateTime.now()) &
                t.status.isNotIn(['completed', 'cancelled']),
          ))
        .get();
  }

  /// Returns the created task, so callers can schedule a check-in against
  /// its id right after.
  Future<Task> addTask({
    required String dailyPlanId,
    required String title,
    TaskSource source = TaskSource.userAdded,
    int? estimatedDuration,
    DateTime? plannedFor,
    DateTime? expectedCompletionTime,
    String? description,
    // Set only when this task is a materialized occurrence of a
    // RecurrenceRule (see RecurrenceRepository) — every other feature
    // treats it as an ordinary task, this is purely for "stop
    // repeating"/series-membership UI.
    String? recurrenceRuleId,
  }) async {
    final trimmed = title.trim();
    final trimmedDescription = description?.trim();
    final task = TasksCompanion.insert(
      id: _uuid.v4(),
      dailyPlanId: dailyPlanId,
      title: trimmed,
      createdAt: DateTime.now(),
      plannedFor: _dateOnly(plannedFor ?? DateTime.now()),
      source: Value(source.toDb()),
      estimatedDuration: Value(estimatedDuration),
      expectedCompletionTime: Value(expectedCompletionTime),
      description: Value(
        trimmedDescription == null || trimmedDescription.isEmpty
            ? null
            : trimmedDescription,
      ),
      recurrenceRuleId: Value(recurrenceRuleId),
    );
    return _db.into(_db.tasks).insertReturning(task);
  }

  /// A "discovered" activity — something the user reports as already done
  /// but that wasn't part of the morning plan (e.g. "had a meeting with
  /// Eric"). This is what differentiates Pulse from a plain to-do list
  /// (see docs/PRODUCT.md) — logged as already-completed, sourced from
  /// the check-in rather than the morning plan.
  Future<void> addActivity({
    required String dailyPlanId,
    required String title,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    final now = DateTime.now();

    await _db.into(_db.tasks).insert(
          TasksCompanion.insert(
            id: _uuid.v4(),
            dailyPlanId: dailyPlanId,
            title: trimmed,
            createdAt: now,
            plannedFor: _dateOnly(now),
            source: const Value('pulse_checkin'),
            status: const Value('completed'),
            completedAt: Value(now),
          ),
        );
  }

  Future<void> setTaskStatus(String taskId, TaskStatus status) async {
    await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId))).write(
      TasksCompanion(
        status: Value(status.toDb()),
        completedAt: Value(
          status == TaskStatus.completed ? DateTime.now() : null,
        ),
      ),
    );
  }

  Future<void> updateExpectedCompletionTime(
    String taskId,
    DateTime? time,
  ) async {
    await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId))).write(
      TasksCompanion(expectedCompletionTime: Value(time)),
    );
  }

  Future<void> deleteTask(String taskId) async {
    await (_db.delete(_db.tasks)..where((t) => t.id.equals(taskId))).go();
  }

  /// Moves a task to a different day's plan and resets it to a fresh
  /// planned state — used by "carry to tomorrow" (day fixed to tomorrow)
  /// and "transfer to another day" (arbitrary day). Trimmed: no distinct
  /// "carried over" marker (TaskStatus.carriedForward stays unused) — the
  /// task just appears as a normal planned task on the new day. Revisit
  /// if that turns out to matter with real use.
  Future<void> moveTaskToDay(
    String taskId,
    DateTime newDay, {
    DateTime? newExpectedCompletionTime,
  }) async {
    final plan = await getOrCreatePlanForDate(newDay);

    await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId))).write(
      TasksCompanion(
        dailyPlanId: Value(plan.id),
        plannedFor: Value(_dateOnly(newDay)),
        status: const Value('planned'),
        completedAt: const Value(null),
        expectedCompletionTime: Value(newExpectedCompletionTime),
        // A move is a fresh start — any outstanding explanation was
        // about staying on the old day, it doesn't carry over.
        explanationNote: const Value(null),
      ),
    );
  }

  /// Edits an existing task in place — title, target day (moving it to
  /// another day's plan is just editing its day, no separate "move"
  /// action for a plain edit), and expected completion time.
  Future<void> updateTaskDetails({
    required String taskId,
    required String title,
    required DateTime plannedFor,
    DateTime? expectedCompletionTime,
    String? description,
  }) async {
    final plan = await getOrCreatePlanForDate(plannedFor);
    final trimmedDescription = description?.trim();
    await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId))).write(
      TasksCompanion(
        title: Value(title.trim()),
        dailyPlanId: Value(plan.id),
        plannedFor: Value(_dateOnly(plannedFor)),
        expectedCompletionTime: Value(expectedCompletionTime),
        description: Value(
          trimmedDescription == null || trimmedDescription.isEmpty
              ? null
              : trimmedDescription,
        ),
      ),
    );
  }

  Future<void> setExplanationNote(String taskId, String? note) async {
    await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId))).write(
      TasksCompanion(explanationNote: Value(note)),
    );
  }

  /// All tasks planned across a range of calendar days (inclusive),
  /// grouped by date — for the Week view. Live (`.watch()`), since this
  /// is a planning view like Today, not a fixed snapshot like Report.
  /// Deliberately doesn't create plan rows for empty days — this is a
  /// read, viewing a week shouldn't have side effects.
  Stream<Map<DateTime, List<Task>>> watchTasksForDateRange(
    DateTime start,
    DateTime endInclusive,
  ) {
    final startDay = _dateOnly(start);
    final endDay = _dateOnly(endInclusive);
    final query = _db.select(_db.tasks).join([
      innerJoin(
        _db.dailyPlans,
        _db.dailyPlans.id.equalsExp(_db.tasks.dailyPlanId),
      ),
    ])
      ..where(_db.dailyPlans.date.isBetweenValues(startDay, endDay))
      ..orderBy([
        OrderingTerm.asc(_db.dailyPlans.date),
        OrderingTerm.asc(_db.tasks.createdAt),
      ]);

    return query.watch().map((rows) {
      final result = <DateTime, List<Task>>{};
      for (final row in rows) {
        final date = row.readTable(_db.dailyPlans).date;
        result.putIfAbsent(date, () => []).add(row.readTable(_db.tasks));
      }
      return result;
    });
  }
}
