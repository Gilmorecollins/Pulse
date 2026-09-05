import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/database.dart';
import '../../../core/models/task_enums.dart';
import '../../../core/notifications/notification_provider.dart';
import '../../checkin/presentation/checkin_scheduling.dart';
import '../../recurrence/presentation/recurrence_providers.dart';
import 'add_edit_task_sheet.dart';
import 'today_providers.dart';

/// A task is "resolved" — no longer needs attention today — once it's
/// either actually completed or ended (cancelled, with an explanation
/// preserved for the record). Used to group Today/Week's task lists into
/// an active section and a resolved one. Deliberately separate from the
/// completion-*rate* math elsewhere (Today's progress card, Report,
/// Insights), which only ever counts true `completed` status — grouping
/// an ended task alongside completed ones here is a display convenience,
/// not a claim that it was finished.
enum _RecurringTaskAction { deleteOccurrence, stopRepeating }

bool isTaskResolved(Task task) {
  final status = TaskStatus.fromDb(task.status);
  return status == TaskStatus.completed || status == TaskStatus.cancelled;
}

/// One task row — shared by the Today screen and the Week view. A plain
/// task opens the edit sheet on tap; a task with an outstanding
/// explanation that's still active (see docs/ARCHITECTURE.md — "explain
/// why" is a resolvable state, not a log) expands in place to show it
/// and offer "transfer to another day" or "end task" instead. Once
/// resolved (completed, or ended via "end task"), it always renders as a
/// plain row — the note stays visible as context, but the actions that
/// only make sense for something still open (transfer/end) go away.
class TaskTile extends ConsumerWidget {
  const TaskTile({super.key, required this.task});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (task.explanationNote != null && !isTaskResolved(task)) {
      return _ExplainedTaskCard(task: task);
    }

    final status = TaskStatus.fromDb(task.status);
    final isCompleted = status == TaskStatus.completed;
    final isCancelled = status == TaskStatus.cancelled;
    final source = TaskSource.fromDb(task.source);
    final isLoggedActivity =
        source == TaskSource.pulseCheckin || source == TaskSource.aiSuggested;
    final finishBy = task.expectedCompletionTime;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        onTap: isLoggedActivity
            ? null
            : () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => AddEditTaskSheet(existingTask: task),
                ),
        leading: Checkbox(
          value: isCompleted,
          onChanged: (checked) async {
            final newStatus =
                checked == true ? TaskStatus.completed : TaskStatus.planned;
            await ref
                .read(todayRepositoryProvider)
                .setTaskStatus(task.id, newStatus);
            if (newStatus == TaskStatus.completed) {
              await ref
                  .read(notificationServiceProvider)
                  .cancelTaskCheckIn(task.id);
            }
          },
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            color: (isCompleted || isCancelled)
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
            : isCancelled && task.explanationNote != null
                ? Text(
                    'Ended — "${task.explanationNote}"',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  )
                : finishBy != null
                    ? Text(
                        'By ${DateFormat.jm().format(finishBy)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      )
                    : null,
        trailing: task.recurrenceRuleId == null
            ? IconButton(
                icon: const Icon(SolarIconsOutline.closeCircle, size: 18),
                onPressed: () async {
                  await ref.read(todayRepositoryProvider).deleteTask(task.id);
                  await ref
                      .read(notificationServiceProvider)
                      .cancelTaskCheckIn(task.id);
                },
              )
            : PopupMenuButton<_RecurringTaskAction>(
                icon: const Icon(SolarIconsOutline.menuDots, size: 18),
                onSelected: (action) async {
                  switch (action) {
                    case _RecurringTaskAction.deleteOccurrence:
                      await ref
                          .read(todayRepositoryProvider)
                          .deleteTask(task.id);
                      await ref
                          .read(notificationServiceProvider)
                          .cancelTaskCheckIn(task.id);
                    case _RecurringTaskAction.stopRepeating:
                      await ref
                          .read(recurrenceRepositoryProvider)
                          .deleteRule(task.recurrenceRuleId!);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _RecurringTaskAction.deleteOccurrence,
                    child: Text('Delete this occurrence'),
                  ),
                  PopupMenuItem(
                    value: _RecurringTaskAction.stopRepeating,
                    child: Text('Stop repeating'),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ExplainedTaskCard extends ConsumerStatefulWidget {
  const _ExplainedTaskCard({required this.task});

  final Task task;

  @override
  ConsumerState<_ExplainedTaskCard> createState() =>
      _ExplainedTaskCardState();
}

class _ExplainedTaskCardState extends ConsumerState<_ExplainedTaskCard> {
  bool _busy = false;

  Future<void> _transferToAnotherDay() async {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final pickedDay = await showDatePicker(
      context: context,
      initialDate: today.add(const Duration(days: 1)),
      firstDate: today,
      lastDate: today.add(const Duration(days: 30)),
    );
    if (pickedDay == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (!mounted) return;

    setState(() => _busy = true);
    final task = widget.task;
    final newTime = pickedTime == null
        ? null
        : DateTime(
            pickedDay.year,
            pickedDay.month,
            pickedDay.day,
            pickedTime.hour,
            pickedTime.minute,
          );

    final repo = ref.read(todayRepositoryProvider);
    await repo.moveTaskToDay(
      task.id,
      pickedDay,
      newExpectedCompletionTime: newTime,
    );
    await ref.read(notificationServiceProvider).cancelTaskCheckIn(task.id);
    if (newTime != null) {
      final plan = await repo.getOrCreatePlanForDate(pickedDay);
      await scheduleTaskCheckIn(
        ref,
        taskId: task.id,
        taskTitle: task.title,
        dailyPlanId: plan.id,
        completionTime: newTime,
      );
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _endTask() async {
    setState(() => _busy = true);
    final task = widget.task;
    await ref
        .read(todayRepositoryProvider)
        .setTaskStatus(task.id, TaskStatus.cancelled);
    await ref.read(notificationServiceProvider).cancelTaskCheckIn(task.id);
    // No setState back to not-busy needed on success — once status flips
    // to cancelled, the live task stream rebuilds this list and TaskTile
    // switches this task to the plain (resolved) row on its own; this
    // widget goes away rather than needing to reset its own busy flag.
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    return Card(
      child: ExpansionTile(
        leading: Icon(
          SolarIconsOutline.infoCircle,
          color: Theme.of(context).colorScheme.tertiary,
        ),
        title: Text(task.title),
        subtitle: Text(
          task.explanationNote!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(task.explanationNote!),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _busy ? null : _transferToAnotherDay,
                        child: const Text('Transfer to another day'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: _busy ? null : _endTask,
                        child: _busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('End task'),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) =>
                                AddEditTaskSheet(existingTask: task),
                          ),
                  child: const Text('Edit details'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
