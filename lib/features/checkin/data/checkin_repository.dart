import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/database.dart';

const _uuid = Uuid();

class CheckInRepository {
  CheckInRepository(this._db);

  final PulseDatabase _db;

  /// Always inserts — each scheduled check-in is its own event, unlike
  /// the old one-per-day model. Recorded at schedule time (not tap time)
  /// so an ignored notification still counts as "due" for Insights'
  /// consistency metric, rather than only ever counting responded ones.
  Future<CheckIn> createPendingCheckIn({
    required String taskId,
    required String dailyPlanId,
    required DateTime scheduledFor,
  }) {
    final row = CheckInsCompanion.insert(
      id: _uuid.v4(),
      dailyPlanId: dailyPlanId,
      taskId: Value(taskId),
      scheduledFor: scheduledFor,
    );
    return _db.into(_db.checkIns).insertReturning(row);
  }

  /// Marks the task's most recent pending check-in responded.
  Future<void> markResponded({required String taskId}) async {
    final pending = await _latestPending(taskId);
    if (pending == null) return;

    await (_db.update(_db.checkIns)..where((c) => c.id.equals(pending.id)))
        .write(
      CheckInsCompanion(
        status: const Value('responded'),
        respondedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Marks the task's most recent pending check-in "skipped" — superseded
  /// by an edit before it ever fired. Distinct from "responded": neither
  /// a response nor a miss, so Insights' consistency metric excludes it
  /// from both the numerator and denominator rather than counting it as
  /// an ignored check-in.
  Future<void> skipPendingCheckIn(String taskId) async {
    final pending = await _latestPending(taskId);
    if (pending == null) return;

    await (_db.update(_db.checkIns)..where((c) => c.id.equals(pending.id)))
        .write(const CheckInsCompanion(status: Value('skipped')));
  }

  Future<CheckIn?> _latestPending(String taskId) {
    return (_db.select(_db.checkIns)
          ..where(
            (c) => c.taskId.equals(taskId) & c.status.equals('pending'),
          )
          ..orderBy([(c) => OrderingTerm.desc(c.scheduledFor)])
          ..limit(1))
        .getSingleOrNull();
  }
}
