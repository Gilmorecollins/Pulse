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

  @override
  Set<Column> get primaryKey => {id};
}

class CheckIns extends Table {
  TextColumn get id => text()();
  TextColumn get dailyPlanId =>
      text().references(DailyPlans, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get scheduledFor => dateTime()();
  DateTimeColumn get respondedAt => dateTime().nullable()();
  // pending | responded | skipped
  TextColumn get status => text().withDefault(const Constant('pending'))();

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
  // Gemini-generated summary of the day (Phase 9). Null until AI is
  // configured, or if generation fails — never fabricated as a fallback.
  TextColumn get aiSummary => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [DailyPlans, Tasks, CheckIns, DailyReflections, DailyReports],
)
class PulseDatabase extends _$PulseDatabase {
  PulseDatabase() : super(_openConnection());

  PulseDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(dailyReports, dailyReports.aiSummary);
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
