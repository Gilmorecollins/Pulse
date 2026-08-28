import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/database.dart';
import '../../../core/models/mood.dart';

const _uuid = Uuid();

class ReflectionRepository {
  ReflectionRepository(this._db);

  final PulseDatabase _db;

  Future<DailyReflection?> getReflectionForPlan(String dailyPlanId) {
    return (_db.select(_db.dailyReflections)
          ..where((r) => r.dailyPlanId.equals(dailyPlanId)))
        .getSingleOrNull();
  }

  /// A day has at most one reflection — overwrite it if the user revisits
  /// this screen the same day rather than creating a duplicate.
  Future<void> saveReflection({
    required String dailyPlanId,
    required Mood mood,
    String? biggestWin,
    String? carryForward,
  }) async {
    final existing = await getReflectionForPlan(dailyPlanId);
    if (existing != null) {
      await (_db.update(_db.dailyReflections)
            ..where((r) => r.id.equals(existing.id)))
          .write(
        DailyReflectionsCompanion(
          mood: Value(mood.toDb()),
          biggestWin: Value(biggestWin),
          carryForward: Value(carryForward),
        ),
      );
      return;
    }

    await _db.into(_db.dailyReflections).insert(
          DailyReflectionsCompanion.insert(
            id: _uuid.v4(),
            dailyPlanId: dailyPlanId,
            mood: mood.toDb(),
            biggestWin: Value(biggestWin),
            carryForward: Value(carryForward),
            createdAt: DateTime.now(),
          ),
        );
  }
}
