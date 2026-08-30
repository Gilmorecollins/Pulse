import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../today/presentation/today_providers.dart';

/// Today through the next 6 days — forward-looking, complements History's
/// retrospective coverage of past days (see docs/ARCHITECTURE.md).
final weekTasksProvider = StreamProvider<Map<DateTime, List<Task>>>((ref) {
  final today = DateTime.now();
  return ref
      .watch(todayRepositoryProvider)
      .watchTasksForDateRange(today, today.add(const Duration(days: 6)));
});
