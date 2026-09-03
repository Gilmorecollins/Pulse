import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/notifications/notification_provider.dart';
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
          reportTime: _reportTime,
        );
    ref.invalidate(userNameProvider);

    // Notification setup is secondary to actually getting into the app —
    // a permission denial or a scheduling failure (e.g. a stripped sound
    // resource; see android/app/src/main/res/raw/keep.xml) must never
    // strand the user on this loading spinner with no way forward. Worst
    // case here, reflection just isn't scheduled yet; the resync logic
    // in main.dart and the Settings notifications toggle can recover it.
    try {
      final notifications = ref.read(notificationServiceProvider);
      await notifications.requestPermissions();
      await notifications.scheduleDailyReflection(_reportTime);
    } catch (_) {
      // Swallowed deliberately — see comment above.
    }

    if (mounted) context.go('/today');
  }

  @override
  Widget build(BuildContext context) {
    final onWelcome = _step == 0;
    // No single outer SafeArea here — the Welcome step needs its photo
    // background to run truly full-bleed behind the status bar, while
    // the other three steps still need their own top inset. Each step
    // below owns its own safe-area handling instead.
    //
    // The background photo lives here, at the whole-screen level, not
    // inside _WelcomeStep — it needs to run behind the dots row too
    // (below the PageView), not just behind the PageView's own bounds,
    // so there's no seam where the photo would otherwise cut off short.
    return Scaffold(
      body: Stack(
        children: [
          if (onWelcome) ...[
            Positioned.fill(
              child: Image.asset(
                'assets/onboarding/welcome_background.jpg',
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.4, 0.75, 1.0],
                    colors: [
                      Colors.black.withValues(alpha: 0.35),
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.65),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),
            ),
          ],
          Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _WelcomeStep(onGetStarted: () => _goToStep(1)),
                    SafeArea(
                      bottom: false,
                      child: _NameStep(
                        controller: _nameController,
                        onNext: () => _goToStep(2),
                        onBack: () => _goToStep(0),
                      ),
                    ),
                    SafeArea(
                      bottom: false,
                      child: _CheckInExplainerStep(
                        onNext: () => _goToStep(3),
                        onBack: () => _goToStep(1),
                      ),
                    ),
                    SafeArea(
                      bottom: false,
                      child: _TimeStep(
                        title: 'When would you like your daily report?',
                        subtitle: 'A short summary of what you got done.',
                        time: _reportTime,
                        onTimeChanged: (t) => setState(() => _reportTime = t),
                        onNext: _saving ? null : _finish,
                        onBack: () => _goToStep(2),
                        nextLabel: 'Start using Pulse',
                        loading: _saving,
                      ),
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 16),
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
                              ? (onWelcome
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.primary)
                              : (onWelcome
                                    ? Colors.white.withValues(alpha: 0.3)
                                    : Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerHighest),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The one screen in the app with a photographic background — see
/// docs/PRODUCT.md. Deliberately full-bleed (ignores the shared
/// SafeArea in OnboardingScreen.build) so the photo runs behind the
/// status bar like a real first-impression screen, with a scrim
/// gradient keeping the status bar icons and the glass card both
/// legible against it.
class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.onGetStarted});

  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // The photo and its scrim live at the OnboardingScreen level (see
    // its build method) so they can run behind the dots row below this
    // PageView page too, not just behind this page's own bounds — this
    // Stack only positions the overlay content on top of that backdrop.
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  const Icon(
                    Icons.monitor_heart_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'PULSE',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      letterSpacing: 3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.32),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome to Pulse',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Plan your day, stay accountable, and see what '
                          'you actually got done.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: theme.colorScheme.primary,
                              padding: const EdgeInsets.symmetric(
                                vertical: 18,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                            onPressed: onGetStarted,
                            child: const Text(
                              'Get Started',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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

/// Explains the per-task check-in model before the user ever adds a
/// task — replaces what used to be a single daily check-in time picker
/// (see docs/ARCHITECTURE.md).
class _CheckInExplainerStep extends StatelessWidget {
  const _CheckInExplainerStep({required this.onNext, required this.onBack});

  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          Icon(Icons.bolt_outlined, size: 40, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Pulse checks in per task',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'Not once a day — when you add a task, you\'ll say when you '
            'expect to finish it, and Pulse checks in 5 minutes before '
            'that time to see how it\'s going.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
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
