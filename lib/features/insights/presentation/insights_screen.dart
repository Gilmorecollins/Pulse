import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/coming_soon.dart';
import '../data/insights_repository.dart';
import 'insights_providers.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(insightsSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pulse Insights')),
      body: SafeArea(
        child: summaryAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "We couldn't load your insights. Check your connection "
                    'and try again.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => ref.invalidate(insightsSummaryProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (summary) => summary.daysTracked == 0
              ? const ComingSoon(
                  icon: SolarIconsOutline.chart,
                  title: 'Insights',
                  message: 'Pulse Insights will appear once you\'ve '
                      'completed a few daily reports.',
                )
              : _InsightsBody(summary: summary),
        ),
      ),
    );
  }
}

class _InsightsBody extends ConsumerWidget {
  const _InsightsBody({required this.summary});

  final InsightsSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consistency = summary.checkInConsistency;
    final trendAsync = ref.watch(insightsTrendProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          summary.daysTracked == 1
              ? 'Based on 1 day tracked so far'
              : 'Based on ${summary.daysTracked} days tracked so far',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),
        trendAsync.when(
          loading: () => const _TrendCardPlaceholder(),
          error: (err, st) => _TrendCardError(
            onRetry: () => ref.invalidate(insightsTrendProvider),
          ),
          data: (points) => points.isEmpty
              ? const SizedBox.shrink()
              : _TrendChart(points: points),
        ),
        const SizedBox(height: 12),
        _StatCard(
          label: 'Average completion',
          value: '${(summary.averageCompletion * 100).round()}%',
        ),
        const SizedBox(height: 12),
        _StatCard(
          label: 'Best day so far',
          value: summary.bestDay == null
              ? '—'
              : DateFormat('d MMMM').format(summary.bestDay!),
          subtitle: summary.bestDay == null
              ? null
              : '${(summary.bestDayCompletion * 100).round()}% completed',
        ),
        const SizedBox(height: 12),
        _StatCard(
          label: 'Average daily tasks',
          value: summary.averageDailyTasks.toStringAsFixed(1),
        ),
        const SizedBox(height: 12),
        _StatCard(
          label: 'Check-in consistency',
          value: consistency == null
              ? 'No check-ins yet'
              : '${(consistency * 100).round()}%',
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, this.subtitle});

  final String label;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value, style: Theme.of(context).textTheme.titleLarge),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Bar-per-day completion trend. Hand-rolled rather than a charting
/// package: no charting library exists in this app yet, and one
/// personal user's realistic data volume (tens to low-hundreds of
/// points) doesn't justify the dependency.
class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.points});

  final List<TrendPoint> points;

  static const _barWidth = 12.0;
  static const _barSpacing = 6.0;
  static const _chartHeight = 100.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Completion trend',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: _chartHeight,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true, // most recent day visible by default
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final point in points)
                      Padding(
                        padding: const EdgeInsets.only(right: _barSpacing),
                        child: Tooltip(
                          message:
                              '${DateFormat('d MMM').format(point.date)} — '
                              '${(point.completionRate * 100).round()}%',
                          child: Container(
                            width: _barWidth,
                            height:
                                _chartHeight *
                                point.completionRate.clamp(0.05, 1.0),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('d MMM').format(points.first.date),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                Text(
                  DateFormat('d MMM').format(points.last.date),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendCardPlaceholder extends StatelessWidget {
  const _TrendCardPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: SizedBox(
        height: 172,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _TrendCardError extends StatelessWidget {
  const _TrendCardError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Text(
                "Couldn't load the completion trend.",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
