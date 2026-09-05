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

class _WeekBody extends StatefulWidget {
  const _WeekBody({required this.tasksByDate});

  final Map<DateTime, List<Task>> tasksByDate;

  @override
  State<_WeekBody> createState() => _WeekBodyState();
}

class _WeekBodyState extends State<_WeekBody>
    with SingleTickerProviderStateMixin {
  // Plays once per Week-tab mount, not on every task-list refresh — this
  // State (and its already-forwarded controller) survives rebuilds at
  // the same tree slot, so a task added later doesn't replay the intro.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Staggers item [index] of [itemCount] within the shared controller —
  /// each item's fade/slide overlaps the next rather than queuing strictly
  /// end-to-end, so the whole list settles in ~[_controller]'s duration
  /// instead of duration-times-itemCount.
  Animation<double> _itemAnimation(int index, int itemCount) {
    final start = (index / (itemCount + 1)).clamp(0.0, 1.0);
    final end = ((index + 2) / (itemCount + 1)).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = _dateOnly(DateTime.now());
    final days = List.generate(7, (i) => today.add(Duration(days: i)));
    final itemCount = days.length + 1;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        _StaggeredItem(
          animation: _itemAnimation(0, itemCount),
          child: _WeekSummaryCard(
            days: days,
            tasksByDate: widget.tasksByDate,
            today: today,
          ),
        ),
        const SizedBox(height: 20),
        for (var i = 0; i < days.length; i++) ...[
          _StaggeredItem(
            animation: _itemAnimation(i + 1, itemCount),
            child: _DaySection(
              day: days[i],
              today: today,
              tasks: widget.tasksByDate[days[i]] ?? [],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}

class _StaggeredItem extends StatelessWidget {
  const _StaggeredItem({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}

/// A "TODAY'S PROGRESS"-style hero, but for the whole week — see
/// _ProgressCard in today_screen.dart. The sparkline below it gives an
/// at-a-glance read of which days are actually planned/done without
/// having to scroll through all 7 day cards.
class _WeekSummaryCard extends StatelessWidget {
  const _WeekSummaryCard({
    required this.days,
    required this.tasksByDate,
    required this.today,
  });

  final List<DateTime> days;
  final Map<DateTime, List<Task>> tasksByDate;
  final DateTime today;

  List<Task> _plannedFor(DateTime day) {
    return (tasksByDate[day] ?? []).where((t) {
      final source = TaskSource.fromDb(t.source);
      return source == TaskSource.morningPlan ||
          source == TaskSource.userAdded;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    var totalPlanned = 0;
    var totalCompleted = 0;
    final ratios = <double>[];
    for (final day in days) {
      final planned = _plannedFor(day);
      final completed = planned
          .where((t) => TaskStatus.fromDb(t.status) == TaskStatus.completed)
          .length;
      totalPlanned += planned.length;
      totalCompleted += completed;
      ratios.add(planned.isEmpty ? 0.0 : completed / planned.length);
    }
    final pct = totalPlanned == 0 ? 0 : (totalCompleted / totalPlanned * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'THIS WEEK',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    letterSpacing: 1.2,
                  ),
            ),
            const SizedBox(height: 8),
            Text('$pct%', style: Theme.of(context).textTheme.displayLarge),
            const SizedBox(height: 4),
            Text(
              totalPlanned == 0
                  ? 'Nothing planned yet'
                  : '$totalCompleted of $totalPlanned tasks completed',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            _WeekSparkline(days: days, ratios: ratios, today: today),
          ],
        ),
      ),
    );
  }
}

class _WeekSparkline extends StatelessWidget {
  const _WeekSparkline({
    required this.days,
    required this.ratios,
    required this.today,
  });

  final List<DateTime> days;
  final List<double> ratios;
  final DateTime today;

  static const _maxBarHeight = 40.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < days.length; i++)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: _maxBarHeight,
                width: 24,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: 20,
                    height: (ratios[i] * _maxBarHeight).clamp(
                      4.0,
                      _maxBarHeight,
                    ),
                    decoration: BoxDecoration(
                      color: days[i] == today
                          ? scheme.primary
                          : scheme.primary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                DateFormat('E').format(days[i]).substring(0, 1),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: days[i] == today
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                      fontWeight: days[i] == today ? FontWeight.bold : null,
                    ),
              ),
            ],
          ),
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
    final scheme = Theme.of(context).colorScheme;
    final isToday = day == today;
    final foreground = isToday ? scheme.onPrimaryContainer : null;

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
    // Mirrors _ProgressCard's ring on Today — same "completed of planned"
    // math, just per day instead of for today alone.
    final completedCount = planned
        .where((t) => TaskStatus.fromDb(t.status) == TaskStatus.completed)
        .length;
    final progress = planned.isEmpty ? 0.0 : completedCount / planned.length;

    return Card(
      color: isToday ? scheme.primaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: foreground,
                        ),
                  ),
                ),
                if (planned.isNotEmpty) ...[
                  SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 3,
                      backgroundColor: isToday
                          ? scheme.onPrimaryContainer.withValues(alpha: 0.2)
                          : scheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(
                        isToday ? scheme.onPrimaryContainer : scheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                IconButton.filledTonal(
                  icon: const Icon(SolarIconsOutline.addCircle, size: 20),
                  tooltip: 'Add a task for $_label',
                  style: isToday
                      ? IconButton.styleFrom(
                          backgroundColor: scheme.onPrimaryContainer
                              .withValues(alpha: 0.12),
                          foregroundColor: scheme.onPrimaryContainer,
                        )
                      : null,
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => AddEditTaskSheet(initialDay: day),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (planned.isEmpty)
              Row(
                children: [
                  Icon(
                    SolarIconsOutline.calendarMinimalistic,
                    size: 18,
                    color: foreground?.withValues(alpha: 0.7) ??
                        scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Nothing planned yet',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: foreground?.withValues(alpha: 0.7) ??
                              scheme.onSurfaceVariant,
                        ),
                  ),
                ],
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
                          color: foreground?.withValues(alpha: 0.7) ??
                              scheme.onSurfaceVariant,
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
        ),
      ),
    );
  }
}
