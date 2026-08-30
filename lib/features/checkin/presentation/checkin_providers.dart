import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../../core/database/database_provider.dart';
import '../../today/presentation/today_providers.dart';
import '../data/checkin_repository.dart';

final checkInRepositoryProvider = Provider<CheckInRepository>((ref) {
  return CheckInRepository(ref.watch(databaseProvider));
});

/// The one task a task-specific check-in screen is about.
final checkInTaskProvider = FutureProvider.family<Task, String>((
  ref,
  taskId,
) {
  return ref.watch(todayRepositoryProvider).getTaskById(taskId);
});
