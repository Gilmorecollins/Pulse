import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/database.dart';
import '../../../core/models/task_enums.dart';
import '../../../core/notifications/notification_provider.dart';
import '../../today/presentation/today_providers.dart';
import 'checkin_providers.dart';
import 'checkin_scheduling.dart';

/// Fires when a task's expected-completion check-in comes due — unlike
/// the old generic daily check-in, this is about exactly one task (see
/// docs/ARCHITECTURE.md).
class TaskCheckInScreen extends ConsumerWidget {
  const TaskCheckInScreen({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskAsync = ref.watch(checkInTaskProvider(taskId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pulse'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/today'),
        ),
      ),
      body: SafeArea(
        child: taskAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "We couldn't load this task — it may have been deleted.",
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.go('/today'),
                    child: const Text('Back to Today'),
                  ),
                ],
              ),
            ),
          ),
          data: (task) => _TaskCheckInBody(task: task),
        ),
      ),
    );
  }
}

class _TaskCheckInBody extends ConsumerStatefulWidget {
  const _TaskCheckInBody({required this.task});

  final Task task;

  @override
  ConsumerState<_TaskCheckInBody> createState() => _TaskCheckInBodyState();
}

class _TaskCheckInBodyState extends ConsumerState<_TaskCheckInBody> {
  final _noteController = TextEditingController();
  bool _explaining = false;
  bool _busy = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _markDone() async {
    setState(() => _busy = true);
    final task = widget.task;
    await ref
        .read(todayRepositoryProvider)
        .setTaskStatus(task.id, TaskStatus.completed);
    await ref.read(notificationServiceProvider).cancelTaskCheckIn(task.id);
    await ref.read(checkInRepositoryProvider).markResponded(taskId: task.id);
    if (mounted) context.go('/today');
  }

  Future<void> _needMoreTime() async {
    final task = widget.task;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        task.expectedCompletionTime ?? DateTime.now(),
      ),
    );
    if (picked == null || !mounted) return;

    setState(() => _busy = true);
    final day = task.plannedFor;
    final newTime = DateTime(
      day.year,
      day.month,
      day.day,
      picked.hour,
      picked.minute,
    );

    await ref
        .read(todayRepositoryProvider)
        .updateExpectedCompletionTime(task.id, newTime);
    await scheduleTaskCheckIn(
      ref,
      taskId: task.id,
      taskTitle: task.title,
      dailyPlanId: task.dailyPlanId,
      completionTime: newTime,
    );
    await ref.read(checkInRepositoryProvider).markResponded(taskId: task.id);
    if (mounted) context.go('/today');
  }

  Future<void> _carryForward() async {
    final task = widget.task;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    // Dismissing the picker only skips setting a time — it doesn't abort
    // the carry-forward itself (that's what the screen's close button is
    // for), so this proceeds either way.
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'WHAT TIME TOMORROW?',
    );
    if (!mounted) return;

    setState(() => _busy = true);
    final newTime = picked == null
        ? null
        : DateTime(
            tomorrow.year,
            tomorrow.month,
            tomorrow.day,
            picked.hour,
            picked.minute,
          );

    final repo = ref.read(todayRepositoryProvider);
    await repo.moveTaskToDay(
      task.id,
      tomorrow,
      newExpectedCompletionTime: newTime,
    );
    await ref.read(notificationServiceProvider).cancelTaskCheckIn(task.id);
    if (newTime != null) {
      final plan = await repo.getOrCreatePlanForDate(tomorrow);
      await scheduleTaskCheckIn(
        ref,
        taskId: task.id,
        taskTitle: task.title,
        dailyPlanId: plan.id,
        completionTime: newTime,
      );
    }
    await ref.read(checkInRepositoryProvider).markResponded(taskId: task.id);
    if (mounted) context.go('/today');
  }

  Future<void> _saveExplanation() async {
    final note = _noteController.text.trim();
    if (note.isEmpty) return;

    setState(() => _busy = true);
    await ref
        .read(todayRepositoryProvider)
        .setExplanationNote(widget.task.id, note);
    await ref.read(checkInRepositoryProvider).markResponded(taskId: widget.task.id);
    if (mounted) context.go('/today');
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          "It's almost time you planned to finish:",
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        Text(task.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 32),
        if (!_explaining) ...[
          FilledButton.icon(
            onPressed: _busy ? null : _markDone,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Mark as done'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy ? null : _needMoreTime,
            icon: const Icon(Icons.more_time),
            label: const Text('Need more time'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy ? null : _carryForward,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Carry to tomorrow'),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _busy
                ? null
                : () => setState(() => _explaining = true),
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text("Explain what's going on"),
          ),
        ] else ...[
          Text(
            "What's going on?",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'e.g. Got pulled into a client call',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _busy ? null : _saveExplanation,
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() => _explaining = false),
                child: const Text('Back'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
