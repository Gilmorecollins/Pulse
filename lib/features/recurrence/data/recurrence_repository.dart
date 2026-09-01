import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/database.dart';
import '../../../core/models/task_enums.dart';
import '../../today/data/today_repository.dart';

const _uuid = Uuid();

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Repeating tasks — see docs/ARCHITECTURE.md. A RecurrenceRule is just a
/// template; occurrences are ordinary Tasks rows materialized lazily (on
/// app open, not a batch job — same "create on first touch" spirit as
/// TodayRepository.getOrCreatePlanForDate), tagged with the rule's id.
/// Every existing feature (Today/Week/Report/Insights) handles them for
/// free since they're ordinary tasks sourced `userAdded`.
class RecurrenceRepository {
  RecurrenceRepository(this._db, this._todayRepository);

  final PulseDatabase _db;
  final TodayRepository _todayRepository;

  /// How far ahead a rule's occurrences are kept materialized —
  /// comfortably covers the Week tab's today→+6 range with margin.
  static const materializationWindow = Duration(days: 13);

  /// Creates the rule and immediately materializes its first window of
  /// occurrences (rather than waiting for the next app-open resync), so
  /// callers can schedule check-ins for them right away — see
  /// AddEditTaskSheet.
  Future<({RecurrenceRule rule, List<Task> occurrences})> createRule({
    required String title,
    String? description,
    required RecurrenceFrequency frequency,
    List<int> daysOfWeek = const [],
    required DateTime startDate,
    DateTime? endDate,
    int? estimatedDuration,
    TimeOfDay? expectedCompletionTime,
  }) async {
    final trimmedDescription = description?.trim();
    final start = _dateOnly(startDate);
    final rule = await _db.into(_db.recurrenceRules).insertReturning(
          RecurrenceRulesCompanion.insert(
            id: _uuid.v4(),
            title: title.trim(),
            description: Value(
              trimmedDescription == null || trimmedDescription.isEmpty
                  ? null
                  : trimmedDescription,
            ),
            frequency: frequency.toDb(),
            daysOfWeek: Value(
              daysOfWeek.isEmpty ? null : daysOfWeek.join(','),
            ),
            startDate: start,
            endDate: Value(endDate == null ? null : _dateOnly(endDate)),
            estimatedDuration: Value(estimatedDuration),
            expectedCompletionMinutes: Value(
              expectedCompletionTime == null
                  ? null
                  : expectedCompletionTime.hour * 60 +
                      expectedCompletionTime.minute,
            ),
            createdAt: DateTime.now(),
          ),
        );

    final occurrences = await materializeOccurrencesForRange(
      start,
      start.add(materializationWindow),
    );
    return (rule: rule, occurrences: occurrences);
  }

  /// Materializes every active rule's occurrences that fall in
  /// [start]..[endInclusive] and don't already have a Task row.
  /// Idempotent — safe to call repeatedly over overlapping ranges (e.g.
  /// every app open). Returns the newly-created tasks so callers (see
  /// lib/main.dart) can schedule check-ins for the ones that need one.
  Future<List<Task>> materializeOccurrencesForRange(
    DateTime start,
    DateTime endInclusive,
  ) async {
    final startDay = _dateOnly(start);
    final endDay = _dateOnly(endInclusive);
    final rules = await _db.select(_db.recurrenceRules).get();
    final created = <Task>[];

    for (final rule in rules) {
      final frequency = RecurrenceFrequency.fromDb(rule.frequency);
      final weekdays = (rule.daysOfWeek == null || rule.daysOfWeek!.isEmpty)
          ? const <int>{}
          : rule.daysOfWeek!.split(',').map(int.parse).toSet();

      for (
        var day = startDay;
        !day.isAfter(endDay);
        day = day.add(const Duration(days: 1))
      ) {
        if (day.isBefore(rule.startDate)) continue;
        if (rule.endDate != null && day.isAfter(rule.endDate!)) continue;
        if (frequency == RecurrenceFrequency.weekly &&
            !weekdays.contains(day.weekday)) {
          continue;
        }

        final existing = await (_db.select(_db.tasks)..where(
              (t) =>
                  t.recurrenceRuleId.equals(rule.id) &
                  t.plannedFor.equals(day),
            ))
            .getSingleOrNull();
        if (existing != null) continue;

        final plan = await _todayRepository.getOrCreatePlanForDate(day);
        final completionTime = rule.expectedCompletionMinutes == null
            ? null
            : DateTime(
                day.year,
                day.month,
                day.day,
                rule.expectedCompletionMinutes! ~/ 60,
                rule.expectedCompletionMinutes! % 60,
              );

        final task = await _todayRepository.addTask(
          dailyPlanId: plan.id,
          title: rule.title,
          description: rule.description,
          plannedFor: day,
          estimatedDuration: rule.estimatedDuration,
          expectedCompletionTime: completionTime,
          recurrenceRuleId: rule.id,
        );
        created.add(task);
      }
    }
    return created;
  }

  /// Stops future occurrences; leaves history untouched. Only untouched
  /// `planned` occurrences from today onward are removed — anything
  /// already completed/in-progress/cancelled stays, just detached from
  /// the rule. Detaching is done with an explicit UPDATE rather than
  /// relying on the column's `onDelete: setNull` — this app never turns
  /// on `PRAGMA foreign_keys`, so SQLite's own ON DELETE actions don't
  /// actually fire (a pre-existing condition across the whole schema,
  /// not something to flip on as a side effect of this feature).
  Future<void> deleteRule(String ruleId) => _db.transaction(() async {
        final today = _dateOnly(DateTime.now());
        await (_db.delete(_db.tasks)..where(
              (t) =>
                  t.recurrenceRuleId.equals(ruleId) &
                  t.plannedFor.isBiggerOrEqualValue(today) &
                  t.status.equals('planned'),
            ))
            .go();
        await (_db.update(
          _db.tasks,
        )..where((t) => t.recurrenceRuleId.equals(ruleId))).write(
          const TasksCompanion(recurrenceRuleId: Value(null)),
        );
        await (_db.delete(
          _db.recurrenceRules,
        )..where((r) => r.id.equals(ruleId))).go();
      });
}
