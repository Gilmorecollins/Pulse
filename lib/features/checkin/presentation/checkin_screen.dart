import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ai/ai_providers.dart';
import '../../../core/database/database.dart';
import '../../../core/models/task_enums.dart';
import '../../today/presentation/today_providers.dart';
import 'checkin_providers.dart';

class CheckInScreen extends ConsumerWidget {
  const CheckInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(openTasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('⚡ Pulse Check-in'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _finish(context, ref),
        ),
      ),
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
                    "We couldn't load today's plan. Check your connection "
                    'and try again.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => ref.invalidate(openTasksProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (tasks) => tasks.isEmpty
              ? _NothingPending(onDone: () => _finish(context, ref))
              : _TaskCheckInList(
                  tasks: tasks,
                  onDone: () => _finish(context, ref),
                ),
        ),
      ),
    );
  }

  Future<void> _finish(BuildContext context, WidgetRef ref) async {
    final checkIn = await ref.read(todayCheckInProvider.future);
    await ref.read(checkInRepositoryProvider).markResponded(checkIn.id);
    if (context.mounted) context.go('/today');
  }
}

class _TaskCheckInList extends StatelessWidget {
  const _TaskCheckInList({required this.tasks, required this.onDone});

  final List<Task> tasks;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(
            'How is your day going?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              for (final task in tasks) ...[
                _CheckInTaskCard(task: task),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 8),
              const _LogActivityCard(),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: FilledButton(onPressed: onDone, child: const Text('Done')),
        ),
      ],
    );
  }
}

class _CheckInTaskCard extends ConsumerWidget {
  const _CheckInTaskCard({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStatus = TaskStatus.fromDb(task.status);

    Future<void> setStatus(TaskStatus status) =>
        ref.read(todayRepositoryProvider).setTaskStatus(task.id, status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusChip(
                  label: 'Still working',
                  selected: currentStatus == TaskStatus.inProgress,
                  onTap: () => setStatus(TaskStatus.inProgress),
                ),
                _StatusChip(
                  label: 'Completed',
                  selected: currentStatus == TaskStatus.completed,
                  onTap: () => setStatus(TaskStatus.completed),
                ),
                _StatusChip(
                  label: 'Paused',
                  selected: false,
                  onTap: () => setStatus(TaskStatus.planned),
                ),
                _StatusChip(
                  label: "Didn't start",
                  selected: currentStatus == TaskStatus.planned,
                  onTap: () => setStatus(TaskStatus.planned),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

/// The "I had a meeting with the director" affordance — logging something
/// that happened outside the morning plan. This is what differentiates
/// Pulse from a plain to-do list (see docs/PRODUCT.md).
class _LogActivityCard extends ConsumerStatefulWidget {
  const _LogActivityCard();

  @override
  ConsumerState<_LogActivityCard> createState() => _LogActivityCardState();
}

class _LogActivityCardState extends ConsumerState<_LogActivityCard> {
  final _controller = TextEditingController();
  bool _adding = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final rawTitle = _controller.text.trim();
    if (rawTitle.isEmpty) return;

    setState(() => _adding = true);

    var title = rawTitle;
    final hasAiKey = await ref.read(hasAiKeyProvider.future);
    if (hasAiKey) {
      try {
        title = await ref
            .read(geminiServiceProvider)
            .interpretActivity(rawTitle);
      } catch (_) {
        title = rawTitle;
      }
      if (mounted) {
        final confirmed = await _confirmActivity(title);
        if (confirmed == null) {
          setState(() => _adding = false);
          return;
        }
        title = confirmed;
      }
    }

    if (!mounted) return;
    final plan = await ref.read(todayPlanProvider.future);
    await ref
        .read(todayRepositoryProvider)
        .addActivity(dailyPlanId: plan.id, title: title);
    _controller.clear();
    if (mounted) {
      setState(() => _adding = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added "$title" to today\'s activities')),
      );
    }
  }

  Future<String?> _confirmActivity(String suggestedTitle) {
    final editController = TextEditingController(text: suggestedTitle);
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log this activity?'),
        content: TextField(
          controller: editController,
          autofocus: true,
          maxLines: 2,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(editController.text.trim()),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Did something else come up?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'e.g. "Had a meeting with the director"',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'What happened?',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _add(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _adding ? null : _add,
                  icon: _adding
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NothingPending extends StatelessWidget {
  const _NothingPending({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Column(
                children: [
                  const SizedBox(height: 24),
                  Icon(
                    Icons.check_circle_outline,
                    size: 40,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nothing pending right now.',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Everything on today\'s plan is already completed or '
                    'cancelled.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
              const _LogActivityCard(),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: FilledButton(onPressed: onDone, child: const Text('Done')),
        ),
      ],
    );
  }
}
