import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../today/presentation/today_providers.dart';
import '../data/recurrence_repository.dart';

final recurrenceRepositoryProvider = Provider<RecurrenceRepository>((ref) {
  return RecurrenceRepository(
    ref.watch(databaseProvider),
    ref.watch(todayRepositoryProvider),
  );
});
