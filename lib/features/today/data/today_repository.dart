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

  /// Returns today's plan, creating an empty one if it doesn't exist yet.
  Future<DailyPlan> getOrCreateTodayPlan() async {
    final today = _dateOnly(DateTime.now());
    final existing = await (_db.select(_db.dailyPlans)
          ..where((p) => p.date.equals(today)))
        .getSingleOrNull();
    if (existing != null) return existing;

    final plan = DailyPlansCompanion.insert(
      id: _uuid.v4(),
      date: today,
      createdAt: DateTime.now(),
    );
    final id = await _db.into(_db.dailyPlans).insertReturning(plan);
    return id;
  }

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

  Future<void> addTask({
    required String dailyPlanId,
    required String title,
    TaskSource source = TaskSource.userAdded,
    int? estimatedDuration,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;

    await _db.into(_db.tasks).insert(
          TasksCompanion.insert(
            id: _uuid.v4(),
            dailyPlanId: dailyPlanId,
            title: trimmed,
            createdAt: DateTime.now(),
            plannedFor: _dateOnly(DateTime.now()),
            source: Value(source.toDb()),
            estimatedDuration: Value(estimatedDuration),
          ),
        );
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

  Future<void> deleteTask(String taskId) async {
    await (_db.delete(_db.tasks)..where((t) => t.id.equals(taskId))).go();
  }
}
