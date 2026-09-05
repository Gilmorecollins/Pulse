import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/database.dart';
import '../../../core/models/task_enums.dart';
import '../../today/presentation/add_edit_task_sheet.dart';
import '../../today/presentation/task_tile.dart';
import 'week_providers.dart';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Today through the next 6 days, one section per day — lets tasks
/// planned for a future day (invisible on the Today screen until that
/// day arrives) be seen and managed ahead of time (see
/// docs/ARCHITECTURE.md).
class WeekScreen extends ConsumerWidget {
  const WeekScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(weekTasksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('This Week')),
      body: SafeArea(
        child: tasksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "We couldn't load this week. Check your connection "
                    'and try again.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => ref.invalidate(weekTasksProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (tasksByDate) => _WeekBody(tasksByDate: tasksByDate),
        ),
      ),
    );
  }
}

class _WeekBody extends StatelessWidget {
  const _WeekBody({required this.tasksByDate});

  final Map<DateTime, List<Task>> tasksByDate;

  @override
  Widget build(BuildContext context) {
    final today = _dateOnly(DateTime.now());
    final days = List.generate(7, (i) => today.add(Duration(days: i)));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        for (final day in days) ...[
          _DaySection(day: day, today: today, tasks: tasksByDate[day] ?? []),
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({
    required this.day,
    required this.today,
    required this.tasks,
  });

  final DateTime day;
  final DateTime today;
  final List<Task> tasks;

  String get _label {
    if (day == today) return 'Today';
    if (day == today.add(const Duration(days: 1))) return 'Tomorrow';
    return DateFormat('EEEE, d MMM').format(day);
  }

  @override
  Widget build(BuildContext context) {
    // Same "planned only" filter as Today/Report — logged activities
    // are always "today, already done" and wouldn't naturally appear on
    // a future day anyway.
    final planned = tasks.where((t) {
      final source = TaskSource.fromDb(t.source);
      return source == TaskSource.morningPlan ||
          source == TaskSource.userAdded;
    }).toList();
    // Same active/resolved split as Today (see task_tile.dart's
    // isTaskResolved) — active tasks first, resolved ones grouped below.
    final active = planned.where((t) => !isTaskResolved(t)).toList();
    final resolved = planned.where(isTaskResolved).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(_label, style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            IconButton(
              icon: const Icon(SolarIconsOutline.addCircle),
              tooltip: 'Add a task for $_label',
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => AddEditTaskSheet(initialDay: day),
              ),
            ),
          ],
        ),
        if (planned.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Text(
              'Nothing planned yet',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          )
        else ...[
          for (final task in active) ...[
            TaskTile(key: ValueKey(task.id), task: task),
            const SizedBox(height: 8),
          ],
          if (resolved.isNotEmpty) ...[
            if (active.isNotEmpty) const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(
                'COMPLETED',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      letterSpacing: 1.2,
                    ),
              ),
            ),
            for (final task in resolved) ...[
              TaskTile(key: ValueKey(task.id), task: task),
              const SizedBox(height: 8),
            ],
          ],
        ],
      ],
    );
  }
}
