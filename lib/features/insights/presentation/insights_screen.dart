import 'package:flutter/material.dart';
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
                  icon: Icons.insights_outlined,
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

class _InsightsBody extends StatelessWidget {
  const _InsightsBody({required this.summary});

  final InsightsSummary summary;

  @override
  Widget build(BuildContext context) {
    final consistency = summary.checkInConsistency;

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
