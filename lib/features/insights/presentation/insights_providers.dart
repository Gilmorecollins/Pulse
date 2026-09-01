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

/// A 60-day rolling window — enough to show a meaningful trend without a
/// horizontally-scrolling chart growing unbounded over years of use.
/// computeCompletionTrend's `since` stays optional for a future
/// "full history" view; this provider is just today's chosen default.
final insightsTrendProvider = FutureProvider<List<TrendPoint>>((ref) {
  return ref
      .watch(insightsRepositoryProvider)
      .computeCompletionTrend(
        since: DateTime.now().subtract(const Duration(days: 60)),
      );
});
