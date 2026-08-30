import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/database.dart';
import '../../../core/notifications/notification_provider.dart';
import '../../checkin/presentation/checkin_providers.dart';
import '../../checkin/presentation/checkin_scheduling.dart';
import 'today_providers.dart';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Add or edit a task: title, target day (defaults to today; moving a
/// task to a different day is just editing its day, see
/// docs/ARCHITECTURE.md), and an optional expected-finish time that
/// schedules a check-in. Shared by the Today screen (tap a task to edit)
/// and the Week view (add for a specific day, or edit any day's task).
class AddEditTaskSheet extends ConsumerStatefulWidget {
  const AddEditTaskSheet({super.key, this.existingTask, this.initialDay});

  /// When set, edits this task instead of creating a new one.
  final Task? existingTask;

  /// Add mode's starting day. Ignored in edit mode (uses the task's own
  /// day). Defaults to today.
  final DateTime? initialDay;

  @override
  ConsumerState<AddEditTaskSheet> createState() => _AddEditTaskSheetState();
}

class _AddEditTaskSheetState extends ConsumerState<AddEditTaskSheet> {
  late final _controller = TextEditingController(
    text: widget.existingTask?.title ?? '',
  );
  late DateTime _day = _dateOnly(
    widget.existingTask?.plannedFor ?? widget.initialDay ?? DateTime.now(),
  );
  late TimeOfDay? _finishTime = _timeOfDayFrom(
    widget.existingTask?.expectedCompletionTime,
  );
  bool _busy = false;

  bool get _isEditing => widget.existingTask != null;

  static TimeOfDay? _timeOfDayFrom(DateTime? time) =>
      time == null ? null : TimeOfDay.fromDateTime(time);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickDay() async {
    final today = _dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _day.isBefore(today) ? today : _day,
      firstDate: today,
      lastDate: today.add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _day = _dateOnly(picked));
  }

  Future<void> _pickFinishTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _finishTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _finishTime = picked);
  }

  Future<void> _submit() async {
    final title = _controller.text.trim();
    if (title.isEmpty) return;

    setState(() => _busy = true);
    final repo = ref.read(todayRepositoryProvider);
    final time = _finishTime;
    final completionTime = time == null
        ? null
        : DateTime(_day.year, _day.month, _day.day, time.hour, time.minute);

    if (_isEditing) {
      final task = widget.existingTask!;
      await repo.updateTaskDetails(
        taskId: task.id,
        title: title,
        plannedFor: _day,
        expectedCompletionTime: completionTime,
      );
      // Unconditional: cheap no-op if nothing was scheduled, and covers
      // every case (time changed, cleared, or day moved) in one place.
      await ref.read(notificationServiceProvider).cancelTaskCheckIn(task.id);
      await ref.read(checkInRepositoryProvider).skipPendingCheckIn(task.id);
      if (completionTime != null) {
        final plan = await repo.getOrCreatePlanForDate(_day);
        await scheduleTaskCheckIn(
          ref,
          taskId: task.id,
          taskTitle: title,
          dailyPlanId: plan.id,
          completionTime: completionTime,
        );
      }
    } else {
      final plan = await repo.getOrCreatePlanForDate(_day);
      final task = await repo.addTask(
        dailyPlanId: plan.id,
        title: title,
        plannedFor: _day,
        expectedCompletionTime: completionTime,
      );
      if (completionTime != null) {
        await scheduleTaskCheckIn(
          ref,
          taskId: task.id,
          taskTitle: task.title,
          dailyPlanId: plan.id,
          completionTime: completionTime,
        );
      }
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final today = _dateOnly(DateTime.now());
    final isToday = _day == today;
    final tomorrow = today.add(const Duration(days: 1));
    final isTomorrow = _day == tomorrow;

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
        children: [
          Text(
            _isEditing ? 'Edit task' : 'What are you working on?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: 'e.g. Finish portfolio',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _pickDay,
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: Text(
                    isToday
                        ? 'Today'
                        : isTomorrow
                            ? 'Tomorrow'
                            : DateFormat('EEE, d MMM').format(_day),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _pickFinishTime,
                  icon: const Icon(Icons.access_time, size: 18),
                  label: Text(
                    _finishTime == null
                        ? 'Finish time'
                        : _finishTime!.format(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isEditing ? 'Save changes' : 'Add task'),
          ),
        ],
      ),
    );
  }
}
