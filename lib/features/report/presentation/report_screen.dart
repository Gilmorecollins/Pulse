import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/models/mood.dart';
import '../../../core/models/task_enums.dart';
import 'report_providers.dart';

class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key, required this.planId});

  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(reportViewDataProvider(planId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Day'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/today');
            }
          },
        ),
      ),
      body: SafeArea(
        child: dataAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "We couldn't load this report. Check your connection "
                    'and try again.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () =>
                        ref.invalidate(reportViewDataProvider(planId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (data) => _ReportBody(data: data),
        ),
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({required this.data});

  final ReportViewData data;

  @override
  Widget build(BuildContext context) {
    // Productivity % reflects the *planned* day only — activities logged
    // via check-in are real and shown below, but don't inflate the ratio
    // just because they're created already-completed (see docs/PRODUCT.md
    // §13-equivalent: "planned completion" vs "activity completion").
    final planned = data.tasks
        .where(
          (t) =>
              TaskSource.fromDb(t.source) == TaskSource.morningPlan ||
              TaskSource.fromDb(t.source) == TaskSource.userAdded,
        )
        .toList();
    final completed = planned
        .where((t) => TaskStatus.fromDb(t.status) == TaskStatus.completed)
        .toList();
    final notCompleted = planned
        .where((t) => TaskStatus.fromDb(t.status) != TaskStatus.completed)
        .toList();
    final activities = data.tasks
        .where(
          (t) =>
              TaskSource.fromDb(t.source) == TaskSource.pulseCheckin ||
              TaskSource.fromDb(t.source) == TaskSource.aiSuggested,
        )
        .toList();
    final total = planned.length;
    final pct = total == 0 ? 0 : ((completed.length / total) * 100).round();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          DateFormat('EEEE, d MMMM yyyy').format(data.plan.date),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PRODUCTIVITY',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        letterSpacing: 1.2,
                      ),
                ),
                const SizedBox(height: 8),
                Text('$pct%', style: Theme.of(context).textTheme.displayLarge),
                const SizedBox(height: 4),
                Text(
                  total == 0
                      ? 'No tasks planned'
                      : '${completed.length} / $total planned tasks '
                          'completed',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        if (completed.isNotEmpty) ...[
          const SizedBox(height: 28),
          _SectionHeader(icon: Icons.check_circle_outline, label: 'Completed'),
          const SizedBox(height: 12),
          ...completed.map((t) => _TaskLine(title: t.title)),
        ],
        if (notCompleted.isNotEmpty) ...[
          const SizedBox(height: 28),
          _SectionHeader(
            icon: Icons.radio_button_unchecked,
            label: 'Not completed',
          ),
          const SizedBox(height: 12),
          ...notCompleted.map((t) => _TaskLine(title: t.title)),
        ],
        if (activities.isNotEmpty) ...[
          const SizedBox(height: 28),
          _SectionHeader(icon: Icons.add_circle_outline, label: 'New activities'),
          const SizedBox(height: 12),
          ...activities.map((t) => _TaskLine(title: t.title)),
        ],
        if (data.reflection != null) ...[
          const SizedBox(height: 28),
          _SectionHeader(icon: Icons.nightlight_round, label: 'Your reflection'),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Chip(label: Text(Mood.fromDb(data.reflection!.mood).label)),
                  if (data.reflection!.biggestWin != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Biggest win',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(data.reflection!.biggestWin!),
                  ],
                  if (data.reflection!.carryForward != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Carried forward',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(data.reflection!.carryForward!),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                letterSpacing: 1.2,
              ),
        ),
      ],
    );
  }
}

class _TaskLine extends StatelessWidget {
  const _TaskLine({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text('•  $title', style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}
