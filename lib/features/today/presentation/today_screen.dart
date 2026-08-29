import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/ai/ai_providers.dart';
import '../../../core/ai/gemini_client.dart';
import '../../../core/ai/gemini_service.dart';
import '../../../core/models/task_enums.dart';
import '../../../core/preferences/preferences_provider.dart';
import 'today_providers.dart';

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 18) return 'Good afternoon';
  return 'Good evening';
}

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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => const _AddTaskSheet(),
    );
  }
}

/// Add-task sheet: a single-task manual add (always available), plus an
/// AI "split my day" flow once Gemini is configured — text in, a list of
/// extracted tasks the user reviews and confirms before anything is
/// written (see docs/ARCHITECTURE.md's AI flow).
class _AddTaskSheet extends ConsumerStatefulWidget {
  const _AddTaskSheet();

  @override
  ConsumerState<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends ConsumerState<_AddTaskSheet> {
  final _controller = TextEditingController();
  List<ExtractedTask>? _suggestions;
  Set<int> _checked = {};
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _addSingle() async {
    final title = _controller.text.trim();
    if (title.isEmpty) return;
    final plan = await ref.read(todayPlanProvider.future);
    await ref
        .read(todayRepositoryProvider)
        .addTask(dailyPlanId: plan.id, title: title);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _splitWithAi() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _busy = true);
    try {
      final tasks = await ref.read(geminiServiceProvider).extractTasks(text);
      if (!mounted) return;
      if (tasks.isEmpty) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't find any tasks in that")),
        );
        return;
      }
      setState(() {
        _suggestions = tasks;
        _checked = {for (var i = 0; i < tasks.length; i++) i};
        _busy = false;
      });
    } on GeminiNotConfiguredException {
      if (mounted) setState(() => _busy = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("AI split didn't work — try adding it as one task"),
        ),
      );
    }
  }

  Future<void> _confirmSuggestions() async {
    final suggestions = _suggestions;
    if (suggestions == null || _checked.isEmpty) return;

    setState(() => _busy = true);
    final plan = await ref.read(todayPlanProvider.future);
    final repo = ref.read(todayRepositoryProvider);
    for (final i in _checked) {
      final task = suggestions[i];
      // userAdded, not aiSuggested — these are freshly planned tasks
      // (not-yet-done), and aiSuggested is bucketed everywhere else in
      // the app as a discovered/already-done activity like pulseCheckin.
      await repo.addTask(
        dailyPlanId: plan.id,
        title: task.title,
        source: TaskSource.userAdded,
        estimatedDuration: task.estimatedDurationMinutes,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final hasAiKey = ref.watch(hasAiKeyProvider).valueOrNull ?? false;
    final suggestions = _suggestions;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: suggestions == null
            ? [
                Text(
                  'What are you working on?',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  minLines: 1,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: hasAiKey
                        ? 'e.g. Finish portfolio and spend an hour on '
                            'the watch app'
                        : 'e.g. Finish portfolio',
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _addSingle(),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy ? null : _addSingle,
                  child: const Text('Add as one task'),
                ),
                if (hasAiKey) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _splitWithAi,
                    icon: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome, size: 18),
                    label: const Text('Split with AI'),
                  ),
                ],
              ]
            : [
                Text(
                  'Add these tasks?',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Uncheck anything that\'s not right — nothing is saved '
                  'until you confirm.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < suggestions.length; i++)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _checked.contains(i),
                    title: Text(suggestions[i].title),
                    subtitle: suggestions[i].estimatedDurationMinutes == null
                        ? null
                        : Text(
                            '~${suggestions[i].estimatedDurationMinutes} min',
                          ),
                    onChanged: (checked) => setState(() {
                      if (checked == true) {
                        _checked.add(i);
                      } else {
                        _checked.remove(i);
                      }
                    }),
                  ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _busy || _checked.isEmpty
                      ? null
                      : _confirmSuggestions,
                  child: Text('Add ${_checked.length} task'
                      '${_checked.length == 1 ? '' : 's'}'),
                ),
                TextButton(
                  onPressed: _busy ? null : () => setState(() => _suggestions = null),
                  child: const Text('Back'),
                ),
              ],
      ),
    );
  }
}

class _TodayContent extends ConsumerWidget {
  const _TodayContent({required this.tasks});

  final List<dynamic> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Progress reflects the *planned* day — activities logged via
    // check-in are real and shown in the list below, but don't inflate
    // this ratio just because they're created already-completed.
    final planned = tasks.where((t) {
      final source = TaskSource.fromDb(t.source);
      return source == TaskSource.morningPlan ||
          source == TaskSource.userAdded;
    }).toList();
    final completed = planned
        .where((t) => TaskStatus.fromDb(t.status) == TaskStatus.completed)
        .length;
    final total = planned.length;
    final progress = total == 0 ? 0.0 : completed / total;
    final name = ref.watch(userNameProvider).valueOrNull;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name == null || name.isEmpty
                      ? _greeting()
                      : '${_greeting()}, $name',
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
    final source = TaskSource.fromDb(task.source);
    final isLoggedActivity =
        source == TaskSource.pulseCheckin || source == TaskSource.aiSuggested;

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
        subtitle: isLoggedActivity
            ? Text(
                'Logged during check-in',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              )
            : null,
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
