import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../../core/database/database_provider.dart';
import '../../today/presentation/today_providers.dart';
import '../data/reflection_repository.dart';

final reflectionRepositoryProvider = Provider<ReflectionRepository>((ref) {
  return ReflectionRepository(ref.watch(databaseProvider));
});

final todayReflectionProvider = FutureProvider<DailyReflection?>((ref) async {
  final plan = await ref.watch(todayPlanProvider.future);
  return ref
      .watch(reflectionRepositoryProvider)
      .getReflectionForPlan(plan.id);
});
