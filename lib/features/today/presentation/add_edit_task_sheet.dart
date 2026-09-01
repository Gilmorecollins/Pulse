import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/database.dart';
import '../../../core/models/task_enums.dart';
import '../../../core/notifications/notification_provider.dart';
import '../../checkin/presentation/checkin_providers.dart';
import '../../checkin/presentation/checkin_scheduling.dart';
import '../../recurrence/presentation/recurrence_providers.dart';
import 'today_providers.dart';

const _weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

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
  late final _descriptionController = TextEditingController(
    text: widget.existingTask?.description ?? '',
  );
  late DateTime _day = _dateOnly(
    widget.existingTask?.plannedFor ?? widget.initialDay ?? DateTime.now(),
  );
  late TimeOfDay? _finishTime = _timeOfDayFrom(
    widget.existingTask?.expectedCompletionTime,
  );
  // Add-mode only — v1 scope trim: a task already part of a series is
  // never converted, and edit mode never sets these (see the "Part of a
  // repeating series" banner below instead).
  RecurrenceFrequency? _repeatFrequency;
  final Set<int> _repeatWeekdays = {};
  bool _busy = false;

  bool get _isEditing => widget.existingTask != null;

  static TimeOfDay? _timeOfDayFrom(DateTime? time) =>
      time == null ? null : TimeOfDay.fromDateTime(time);

  @override
  void dispose() {
    _controller.dispose();
    _descriptionController.dispose();
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

    final description = _descriptionController.text.trim();

    if (_isEditing) {
      final task = widget.existingTask!;
      await repo.updateTaskDetails(
        taskId: task.id,
        title: title,
        plannedFor: _day,
        expectedCompletionTime: completionTime,
        description: description,
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
    } else if (_repeatFrequency != null) {
      final result = await ref
          .read(recurrenceRepositoryProvider)
          .createRule(
            title: title,
            description: description,
            frequency: _repeatFrequency!,
            daysOfWeek: _repeatFrequency == RecurrenceFrequency.weekly
                ? _repeatWeekdays.toList()
                : const [],
            startDate: _day,
            expectedCompletionTime: _finishTime,
          );
      for (final occurrence in result.occurrences) {
        final occurrenceTime = occurrence.expectedCompletionTime;
        if (occurrenceTime != null) {
          await scheduleTaskCheckIn(
            ref,
            taskId: occurrence.id,
            taskTitle: occurrence.title,
            dailyPlanId: occurrence.dailyPlanId,
            completionTime: occurrenceTime,
          );
        }
      }
    } else {
      final plan = await repo.getOrCreatePlanForDate(_day);
      final task = await repo.addTask(
        dailyPlanId: plan.id,
        title: title,
        plannedFor: _day,
        expectedCompletionTime: completionTime,
        description: description,
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
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: 'e.g. Finish portfolio',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            minLines: 1,
            maxLines: 3,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: 'Add a short description (optional)',
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
          if (!_isEditing) ...[
            const SizedBox(height: 12),
            _RepeatPicker(
              frequency: _repeatFrequency,
              weekdays: _repeatWeekdays,
              enabled: !_busy,
              onFrequencyChanged: (freq) =>
                  setState(() => _repeatFrequency = freq),
              onWeekdayToggled: (day, selected) => setState(() {
                if (selected) {
                  _repeatWeekdays.add(day);
                } else {
                  _repeatWeekdays.remove(day);
                }
              }),
            ),
          ] else if (widget.existingTask!.recurrenceRuleId != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.repeat,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Part of a repeating series — this only edits today\'s '
                    'occurrence',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            ),
          ],
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

/// None / Daily / Weekdays choice, with a weekday multi-select revealed
/// only for Weekdays. Add-mode only — see AddEditTaskSheet's v1 scope
/// trim on editing a series.
class _RepeatPicker extends StatelessWidget {
  const _RepeatPicker({
    required this.frequency,
    required this.weekdays,
    required this.enabled,
    required this.onFrequencyChanged,
    required this.onWeekdayToggled,
  });

  final RecurrenceFrequency? frequency;
  final Set<int> weekdays;
  final bool enabled;
  final ValueChanged<RecurrenceFrequency?> onFrequencyChanged;
  final void Function(int weekday, bool selected) onWeekdayToggled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Once'),
              selected: frequency == null,
              onSelected: enabled ? (_) => onFrequencyChanged(null) : null,
            ),
            ChoiceChip(
              label: const Text('Daily'),
              selected: frequency == RecurrenceFrequency.daily,
              onSelected: enabled
                  ? (_) => onFrequencyChanged(RecurrenceFrequency.daily)
                  : null,
            ),
            ChoiceChip(
              label: const Text('Weekdays'),
              selected: frequency == RecurrenceFrequency.weekly,
              onSelected: enabled
                  ? (_) => onFrequencyChanged(RecurrenceFrequency.weekly)
                  : null,
            ),
          ],
        ),
        if (frequency == RecurrenceFrequency.weekly) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            children: List.generate(7, (i) {
              final weekday = i + 1; // 1 = Monday .. 7 = Sunday
              return FilterChip(
                label: Text(_weekdayLabels[i]),
                selected: weekdays.contains(weekday),
                onSelected: enabled
                    ? (selected) => onWeekdayToggled(weekday, selected)
                    : null,
              );
            }),
          ),
        ],
      ],
    );
  }
}
