import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/preferences/preferences_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  final _nameController = TextEditingController();

  int _step = 0;
  TimeOfDay _checkInTime = const TimeOfDay(hour: 13, minute: 0);
  TimeOfDay _reportTime = const TimeOfDay(hour: 20, minute: 0);
  bool _saving = false;

  static const _pageCount = 4;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() => _step = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    await ref.read(preferencesRepositoryProvider).completeOnboarding(
          name: _nameController.text.trim().isEmpty
              ? 'there'
              : _nameController.text.trim(),
          checkInTime: _checkInTime,
          reportTime: _reportTime,
        );
    ref.invalidate(userNameProvider);
    if (mounted) context.go('/today');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _WelcomeStep(onGetStarted: () => _goToStep(1)),
                  _NameStep(
                    controller: _nameController,
                    onNext: () => _goToStep(2),
                    onBack: () => _goToStep(0),
                  ),
                  _TimeStep(
                    title: 'When should Pulse check in with you?',
                    subtitle: 'Once a day, Pulse will ask how things are '
                        'going.',
                    time: _checkInTime,
                    onTimeChanged: (t) => setState(() => _checkInTime = t),
                    onNext: () => _goToStep(3),
                    onBack: () => _goToStep(1),
                  ),
                  _TimeStep(
                    title: 'When would you like your daily report?',
                    subtitle: 'A short summary of what you got done.',
                    time: _reportTime,
                    onTimeChanged: (t) => setState(() => _reportTime = t),
                    onNext: _saving ? null : _finish,
                    onBack: () => _goToStep(2),
                    nextLabel: 'Start using Pulse',
                    loading: _saving,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pageCount, (i) {
                  final active = i == _step;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.onGetStarted});

  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome to', style: theme.textTheme.headlineMedium),
          Text(
            'Pulse',
            style: theme.textTheme.displayLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your day.\nYour progress.\nYour accountability.',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Text(
            'Pulse helps you plan your day, stay accountable and '
            'understand what you actually accomplished.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onGetStarted,
              child: const Text('Get Started'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NameStep extends StatelessWidget {
  const _NameStep({
    required this.controller,
    required this.onNext,
    required this.onBack,
  });

  final TextEditingController controller;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
          ),
          const SizedBox(height: 16),
          Text(
            'What should Pulse call you?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: 'Your name',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => onNext(),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: onNext, child: const Text('Next')),
          ),
        ],
      ),
    );
  }
}

class _TimeStep extends StatelessWidget {
  const _TimeStep({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.onTimeChanged,
    required this.onNext,
    required this.onBack,
    this.nextLabel = 'Next',
    this.loading = false,
  });

  final String title;
  final String subtitle;
  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onTimeChanged;
  final VoidCallback? onNext;
  final VoidCallback onBack;
  final String nextLabel;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
          ),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: time,
                );
                if (picked != null) onTimeChanged(picked);
              },
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.access_time),
                    const SizedBox(width: 16),
                    Text(
                      time.format(context),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onNext,
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(nextLabel),
            ),
          ),
        ],
      ),
    );
  }
}
