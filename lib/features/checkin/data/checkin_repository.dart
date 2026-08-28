import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/database.dart';

const _uuid = Uuid();

class CheckInRepository {
  CheckInRepository(this._db);

  final PulseDatabase _db;

  /// A day has at most one open (pending) check-in at a time — reuse it if
  /// the user opens the check-in screen more than once before responding.
  Future<CheckIn> getOrCreateTodayCheckIn(String dailyPlanId) async {
    final existing = await (_db.select(_db.checkIns)
          ..where(
            (c) =>
                c.dailyPlanId.equals(dailyPlanId) & c.status.equals('pending'),
          ))
        .getSingleOrNull();
    if (existing != null) return existing;

    final row = CheckInsCompanion.insert(
      id: _uuid.v4(),
      dailyPlanId: dailyPlanId,
      scheduledFor: DateTime.now(),
    );
    return _db.into(_db.checkIns).insertReturning(row);
  }

  Future<void> markResponded(String checkInId) async {
    await (_db.update(_db.checkIns)..where((c) => c.id.equals(checkInId)))
        .write(
      CheckInsCompanion(
        status: const Value('responded'),
        respondedAt: Value(DateTime.now()),
      ),
    );
  }
}
