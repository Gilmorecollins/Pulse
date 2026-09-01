import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'package:sqlite3/sqlite3.dart';

part 'database.g.dart';

/// One row per calendar day. Everything else in the schema hangs off this.
class DailyPlans extends Table {
  TextColumn get id => text()();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get dailyPlanId =>
      text().references(DailyPlans, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  // planned | in_progress | completed | cancelled | carried_forward
  TextColumn get status => text().withDefault(const Constant('planned'))();
  // low | medium | high | critical
  TextColumn get priority => text().withDefault(const Constant('medium'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get plannedFor => dateTime()();
  IntColumn get estimatedDuration => integer().nullable()();
  IntColumn get actualDuration => integer().nullable()();
  // morning_plan | user_added | pulse_checkin | ai_suggested
  TextColumn get source => text().withDefault(const Constant('user_added'))();
  // The specific moment the user expects to finish (not a duration) —
  // drives per-task check-in scheduling. Null means no check-in.
  DateTimeColumn get expectedCompletionTime => dateTime().nullable()();
  // The task's current explanation for not being done yet — a live,
  // resolvable state (not a log), set by the check-in screen's "Explain"
  // action. Cleared when transferred to a new day (fresh start); left in
  // place when the task is ended, so it carries through to the report.
  TextColumn get explanationNote => text().nullable()();
  // Set only on a task materialized from a RecurrenceRule occurrence.
  // onDelete: setNull (not cascade) — deleting a rule stops future
  // occurrences but never deletes history; see RecurrenceRepository.
  TextColumn get recurrenceRuleId => text()
      .nullable()
      .references(RecurrenceRules, #id, onDelete: KeyAction.setNull)();

  @override
  Set<Column> get primaryKey => {id};
}

/// A repeat rule a task can be generated from — see
/// RecurrenceRepository. Occurrences are materialized lazily (on app
/// open, not a batch job) as ordinary Tasks rows tagged with this rule's
/// id, so every existing feature (Today/Week/Report/Insights) handles
/// them for free without knowing recurrence exists.
class RecurrenceRules extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  // 'daily' | 'weekly'
  TextColumn get frequency => text()();
  // Comma-separated ISO weekdays ("1,3,5"), null when frequency is daily.
  TextColumn get daysOfWeek => text().nullable()();
  DateTimeColumn get startDate => dateTime()(); // date-only
  DateTimeColumn get endDate => dateTime().nullable()(); // date-only, inclusive; null = indefinite
  IntColumn get estimatedDuration => integer().nullable()();
  // Minutes since midnight — the expected-finish time each occurrence is
  // given, mirroring Tasks.expectedCompletionTime's role. Null means
  // occurrences get no check-in.
  IntColumn get expectedCompletionMinutes => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class CheckIns extends Table {
  TextColumn get id => text()();
  TextColumn get dailyPlanId =>
      text().references(DailyPlans, #id, onDelete: KeyAction.cascade)();
  // Every check-in is tied to one task (see docs/ARCHITECTURE.md —
  // check-ins are per-task, not one fixed daily prompt).
  TextColumn get taskId =>
      text().nullable().references(Tasks, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get scheduledFor => dateTime()();
  DateTimeColumn get respondedAt => dateTime().nullable()();
  // pending | responded | skipped — skipped means superseded by an edit
  // before it ever fired (not a miss, doesn't count against Insights'
  // consistency metric either way).
  TextColumn get status => text().withDefault(const Constant('pending'))();
  // Unused as of the explanationNote redesign (see Tasks.explanationNote)
  // — left in the schema rather than a dropColumn migration for zero
  // benefit. Task-level explanations are a live, resolvable state, not a
  // per-check-in log, so they live on Tasks instead.
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class DailyReflections extends Table {
  TextColumn get id => text()();
  TextColumn get dailyPlanId => text()
      .references(DailyPlans, #id, onDelete: KeyAction.cascade)
      .unique()();
  // excellent | good | okay | difficult | unproductive
  TextColumn get mood => text()();
  TextColumn get biggestWin => text().nullable()();
  TextColumn get carryForward => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class DailyReports extends Table {
  TextColumn get id => text()();
  TextColumn get dailyPlanId => text()
      .references(DailyPlans, #id, onDelete: KeyAction.cascade)
      .unique()();
  RealColumn get completionRate => real()();
  DateTimeColumn get generatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    DailyPlans,
    Tasks,
    CheckIns,
    DailyReflections,
    DailyReports,
    RecurrenceRules,
  ],
)
class PulseDatabase extends _$PulseDatabase {
  PulseDatabase() : super(_openConnection());

  PulseDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(tasks, tasks.expectedCompletionTime);
            await m.addColumn(checkIns, checkIns.taskId);
            await m.addColumn(checkIns, checkIns.note);
          }
          if (from < 3) {
            await m.addColumn(tasks, tasks.explanationNote);
          }
          if (from < 4) {
            await m.createTable(recurrenceRules);
            await m.addColumn(tasks, tasks.recurrenceRuleId);
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'pulse.sqlite'));

    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }
    final cachebase = (await getTemporaryDirectory()).path;
    sqlite3.tempDirectory = cachebase;

    return NativeDatabase.createInBackground(file);
  });
}
