import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/database/database.dart';
import '../../../core/models/task_enums.dart';
import '../../../core/preferences/preferences_provider.dart';
import '../../../core/update/update_check_service.dart';
import '../../../core/update/update_providers.dart';
import 'add_edit_task_sheet.dart';
import 'task_tile.dart';
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
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'logActivity',
            onPressed: () => _showLogActivitySheet(context),
            tooltip: 'Did something else come up?',
            child: const Icon(Icons.bolt_outlined),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.extended(
            heroTag: 'addTask',
            onPressed: () => _showAddTaskSheet(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Task'),
          ),
        ],
      ),
    );
  }

  void _showAddTaskSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => const AddEditTaskSheet(),
    );
  }

  void _showLogActivitySheet(BuildContext context) {
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
        child: const _LogActivityCard(),
      ),
    );
  }
}

/// The "I had a meeting with the director" affordance — logging something
/// that happened outside the morning plan. This is what differentiates
/// Pulse from a plain to-do list (see docs/PRODUCT.md). Lives on the
/// Today screen rather than gated behind a check-in notification, since
/// check-ins are per-task now and there's no single daily moment for it.
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
    final title = _controller.text.trim();
    if (title.isEmpty) return;

    setState(() => _adding = true);
    final plan = await ref.read(todayPlanProvider.future);
    await ref
        .read(todayRepositoryProvider)
        .addActivity(dailyPlanId: plan.id, title: title);
    _controller.clear();
    if (mounted) {
      setState(() => _adding = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added "$title" to today\'s activities')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
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
                autofocus: true,
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
    );
  }
}

class _TodayContent extends ConsumerWidget {
  const _TodayContent({required this.tasks});

  final List<Task> tasks;

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

    // Active = still needs attention; resolved = completed or ended (see
    // task_tile.dart's isTaskResolved) — a display grouping only, doesn't
    // change the honest completion-rate math above.
    final active = tasks.where((t) => !isTaskResolved(t)).toList();
    final resolved = tasks.where(isTaskResolved).toList();

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
                Consumer(
                  builder: (context, ref, _) {
                    final release = ref.watch(updateInfoProvider).valueOrNull;
                    if (release == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: _UpdateBanner(release: release),
                    );
                  },
                ),
                const SizedBox(height: 24),
                _ProgressCard(
                  progress: progress,
                  completed: completed,
                  total: total,
                ),
              ],
            ),
          ),
        ),
        if (tasks.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyState(),
          )
        else ...[
          if (active.isNotEmpty)
            _TaskSectionSliver(label: 'IN PROGRESS', tasks: active),
          if (resolved.isNotEmpty)
            _TaskSectionSliver(label: 'COMPLETED', tasks: resolved),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ],
    );
  }
}

class _TaskSectionSliver extends StatelessWidget {
  const _TaskSectionSliver({required this.label, required this.tasks});

  final String label;
  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      letterSpacing: 1.2,
                    ),
              ),
            ),
          ),
          SliverList.separated(
            itemCount: tasks.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final task = tasks[index];
              return TaskTile(key: ValueKey(task.id), task: task);
            },
          ),
        ],
      ),
    );
  }
}

/// Dismissible notice that a newer release exists (see
/// core/update/update_providers.dart) — "Update" opens the GitHub
/// release page in the browser so the user reviews/downloads it
/// themselves; this app never auto-downloads or auto-installs an APK.
class _UpdateBanner extends ConsumerWidget {
  const _UpdateBanner({required this.release});

  final LatestRelease release;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.system_update_outlined,
              color: scheme.onSecondaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${release.name} is available',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSecondaryContainer,
                    ),
              ),
            ),
            TextButton(
              onPressed: () async {
                final launched = await launchUrl(
                  Uri.parse(release.releaseUrl),
                  mode: LaunchMode.externalApplication,
                );
                if (!launched && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Couldn't open the release page"),
                    ),
                  );
                }
              },
              child: const Text('Update'),
            ),
            IconButton(
              icon: Icon(
                Icons.close,
                size: 18,
                color: scheme.onSecondaryContainer,
              ),
              tooltip: 'Dismiss',
              onPressed: () async {
                await ref
                    .read(preferencesRepositoryProvider)
                    .setDismissedUpdateVersion(release.version);
                ref.invalidate(updateInfoProvider);
              },
            ),
          ],
        ),
      ),
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
