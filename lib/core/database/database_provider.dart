import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database.dart';

/// Single shared connection to the local Drift database for the app's
/// lifetime. See docs/ARCHITECTURE.md — this is the source of truth for v1.
final databaseProvider = Provider<PulseDatabase>((ref) {
  final db = PulseDatabase();
  ref.onDispose(db.close);
  return db;
});
