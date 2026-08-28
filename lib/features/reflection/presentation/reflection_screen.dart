import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/mood.dart';
import '../../../core/models/task_enums.dart';
import '../../today/presentation/today_providers.dart';
import 'reflection_providers.dart';

class ReflectionScreen extends ConsumerStatefulWidget {
  const ReflectionScreen({super.key});

  @override
  ConsumerState<ReflectionScreen> createState() => _ReflectionScreenState();
}

class _ReflectionScreenState extends ConsumerState<ReflectionScreen> {
  final _winController = TextEditingController();
  final _carryController = TextEditingController();
  Mood? _mood;
  bool _saving = false;

  @override
  void dispose() {
    _winController.dispose();
    _carryController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final mood = _mood;
    if (mood == null) return;

    setState(() => _saving = true);
    final plan = await ref.read(todayPlanProvider.future);
    await ref.read(reflectionRepositoryProvider).saveReflection(
          dailyPlanId: plan.id,
          mood: mood,
          biggestWin: _winController.text.trim().isEmpty
              ? null
              : _winController.text.trim(),
          carryForward: _carryController.text.trim().isEmpty
              ? null
              : _carryController.text.trim(),
        );
    ref.invalidate(todayReflectionProvider);
    if (mounted) context.go('/today');
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(todayTasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🌙 Daily Reflection'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/today'),
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
                    onPressed: () => ref.invalidate(todayTasksProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (tasks) {
            final total = tasks.length;
            final completed = tasks
                .where(
                  (t) => TaskStatus.fromDb(t.status) == TaskStatus.completed,
                )
                .length;

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  total == 0
                      ? "You didn't plan any tasks today."
                      : 'You planned $total task${total == 1 ? '' : 's'}. '
                          'You completed $completed.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 28),
                Text(
                  'How do you feel about today?',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: Mood.values
                      .map(
                        (m) => ChoiceChip(
                          label: Text(m.label),
                          selected: _mood == m,
                          onSelected: (_) => setState(() => _mood = m),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 28),
                Text(
                  'What was your biggest win today?',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _winController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Optional',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Anything to carry forward to tomorrow?',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _carryController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Optional',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _mood == null || _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save reflection'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
