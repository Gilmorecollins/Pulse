import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../today/presentation/today_providers.dart';
import '../data/insights_repository.dart';

final insightsRepositoryProvider = Provider<InsightsRepository>((ref) {
  return InsightsRepository(
    ref.watch(databaseProvider),
    ref.watch(todayRepositoryProvider),
  );
});

final insightsSummaryProvider = FutureProvider<InsightsSummary>((ref) {
  return ref.watch(insightsRepositoryProvider).computeSummary();
});
