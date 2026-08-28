import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/task_enums.dart';
import 'today_providers.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(todayTasksProvider);

    return Scaffold(
      body: SafeArea(
        child: tasksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => _ErrorState(
            onRetry: () => ref.invalidate(todayTasksProvider),
          ),
          data: (tasks) => _TodayContent(tasks: tasks),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }

  void _showAddTaskSheet(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'What are you working on?',
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                hintText: 'e.g. Finish portfolio',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(sheetContext, ref, controller),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _submit(sheetContext, ref, controller),
              child: const Text('Add to today'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(
    BuildContext sheetContext,
    WidgetRef ref,
    TextEditingController controller,
  ) async {
    final title = controller.text.trim();
    if (title.isEmpty) return;
    final plan = await ref.read(todayPlanProvider.future);
    await ref
        .read(todayRepositoryProvider)
        .addTask(dailyPlanId: plan.id, title: title);
    if (sheetContext.mounted) Navigator.of(sheetContext).pop();
  }
}

class _TodayContent extends ConsumerWidget {
  const _TodayContent({required this.tasks});

  final List<dynamic> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completed = tasks
        .where((t) => TaskStatus.fromDb(t.status) == TaskStatus.completed)
        .length;
    final total = tasks.length;
    final progress = total == 0 ? 0.0 : completed / total;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good morning',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, d MMMM').format(DateTime.now()),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 24),
                _ProgressCard(
                  progress: progress,
                  completed: completed,
                  total: total,
                ),
                const SizedBox(height: 24),
                Text(
                  "TODAY'S FOCUS",
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        letterSpacing: 1.2,
                      ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        if (tasks.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyState(),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList.separated(
              itemCount: tasks.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final task = tasks[index];
                return _TaskTile(task: task);
              },
            ),
          ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.progress,
    required this.completed,
    required this.total,
  });

  final double progress;
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "TODAY'S PROGRESS",
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                          letterSpacing: 1.2,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text('$pct%', style: Theme.of(context).textTheme.displayLarge),
                  const SizedBox(height: 4),
                  Text(
                    total == 0
                        ? 'No tasks planned yet'
                        : '$completed of $total tasks completed',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                value: total == 0 ? 0 : progress,
                strokeWidth: 6,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskTile extends ConsumerWidget {
  const _TaskTile({required this.task});

  final dynamic task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = TaskStatus.fromDb(task.status);
    final isCompleted = status == TaskStatus.completed;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: Checkbox(
          value: isCompleted,
          onChanged: (checked) {
            ref.read(todayRepositoryProvider).setTaskStatus(
                  task.id,
                  checked == true ? TaskStatus.completed : TaskStatus.planned,
                );
          },
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            color: isCompleted
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : null,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 18),
          onPressed: () =>
              ref.read(todayRepositoryProvider).deleteTask(task.id),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wb_sunny_outlined,
              size: 40,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'What are you working on today?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first task to start today\'s plan.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: 16),
            const Text(
              "We couldn't load today's plan. Check your connection and try again.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
