import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';
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
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  int _step = 0;
  TimeOfDay _reportTime = const TimeOfDay(hour: 20, minute: 0);
  bool _saving = false;

  static const _pageCount = 4;

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
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
    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    final fullName = [first, last].where((s) => s.isNotEmpty).join(' ');
    await ref.read(preferencesRepositoryProvider).completeOnboarding(
          name: fullName.isEmpty ? 'there' : fullName,
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
    // Steps 0-2 (Welcome, name, check-in explainer) run a full-bleed photo
    // behind them; only the final time-picker step uses the plain Navy
    // Mirage background. Dots/back-button styling below key off this.
    final onPhotoStep = _step <= 2;
    // No single outer SafeArea here — the photo steps need their photo
    // to run truly full-bleed behind the status bar, while the time step
    // still needs its own top inset. Each step below owns its own
    // safe-area handling instead.
    return Scaffold(
      body: Stack(
        children: [
          // Always mounted, each faded via its own opacity rather than
          // conditionally built/torn down with an `if` — removing a
          // full-screen Image+gradient from the tree instantly (on the
          // same frame _step changes) while the PageView is still 250ms
          // into sliding away caused a visible stutter, fighting the
          // slide instead of complementing it. Cross-fading them in
          // place reads as one smooth transition instead of a pop.
          for (final entry in _stepBackgrounds.asMap().entries)
            IgnorePointer(
              ignoring: _step != entry.key,
              child: AnimatedOpacity(
                opacity: _step == entry.key ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                child: _PhotoBackdrop(data: entry.value),
              ),
            ),
          Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _WelcomeStep(onGetStarted: () => _goToStep(1)),
                    _NameStep(
                      active: _step == 1,
                      firstNameController: _firstNameController,
                      lastNameController: _lastNameController,
                      onNext: () => _goToStep(2),
                      onBack: () => _goToStep(0),
                    ),
                    _CheckInExplainerStep(
                      active: _step == 2,
                      onNext: () => _goToStep(3),
                      onBack: () => _goToStep(1),
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
                              ? (onPhotoStep
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.primary)
                              : (onPhotoStep
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

/// One photo-backed step's asset + a scrim gradient tuned to that image
/// (see _stepBackgrounds below) — the scrim keeps status-bar icons and
/// glass-card text legible regardless of how bright the photo itself is.
class _StepBackgroundData {
  const _StepBackgroundData({required this.asset, required this.scrimAlphas});

  final String asset;
  final List<double> scrimAlphas;
}

const _stepBackgrounds = <_StepBackgroundData>[
  _StepBackgroundData(
    asset: 'assets/onboarding/welcome_background.jpg',
    scrimAlphas: [0.35, 0.1, 0.65, 0.85],
  ),
  _StepBackgroundData(
    asset: 'assets/onboarding/name_background.jpg',
    scrimAlphas: [0.35, 0.1, 0.65, 0.85],
  ),
  // A much brighter sky than the other two photos, so the top scrim
  // needs to be noticeably stronger for the status bar and back arrow
  // to stay legible against it.
  _StepBackgroundData(
    asset: 'assets/onboarding/checkin_background.jpg',
    scrimAlphas: [0.55, 0.3, 0.7, 0.88],
  ),
];

class _PhotoBackdrop extends StatelessWidget {
  const _PhotoBackdrop({required this.data});

  final _StepBackgroundData data;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(data.asset, fit: BoxFit.cover),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.4, 0.75, 1.0],
                colors: [
                  for (final alpha in data.scrimAlphas)
                    Colors.black.withValues(alpha: alpha),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A translucent "glass" card sitting over a photo backdrop — shared
/// shape/blur/border across all three photo steps so they read as one
/// consistent design language.
class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.32),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A back-arrow row for the photo steps that aren't the very first
/// screen — styled for legibility over a photo rather than the default
/// (dark-on-light) IconButton look.
class _PhotoStepBackButton extends StatelessWidget {
  const _PhotoStepBackButton({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 0, 0),
          child: IconButton(
            onPressed: onBack,
            icon: const Icon(SolarIconsOutline.arrowLeft, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// A text field styled to sit legibly on the frosted-glass card over a
/// photo backdrop — the app's default TextField theme assumes a plain
/// light/dark surface, not a translucent dark blur.
class _GlassTextField extends StatelessWidget {
  const _GlassTextField({
    required this.controller,
    required this.hint,
    this.autofocus = false,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
    );
    return TextField(
      controller: controller,
      autofocus: autofocus,
      textCapitalization: TextCapitalization.words,
      textInputAction: textInputAction ?? TextInputAction.next,
      onSubmitted: onSubmitted,
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
      ),
    );
  }
}

/// The one-time "hero" step — see docs/PRODUCT.md. Its photo and scrim
/// live at the OnboardingScreen level (see its build method) so they can
/// run behind the dots row below this PageView page too, not just
/// behind this page's own bounds — this Stack only positions the
/// overlay content on top of that backdrop.
class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.onGetStarted});

  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                    SolarIconsOutline.pulse,
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
              child: _GlassCard(
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
                      'Plan your day, stay accountable, and see what you '
                      'actually got done.',
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
                          padding: const EdgeInsets.symmetric(vertical: 18),
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
      ],
    );
  }
}

/// Collects first/last name over the "Start up page 3" backdrop. A
/// StatefulWidget purely so its entrance animation can replay each time
/// [active] flips true — PageView's default `children:` constructor
/// builds every page eagerly up front, so an initState-triggered
/// animation would fire while this page is still off-screen and be long
/// finished by the time the user actually swipes to it.
class _NameStep extends StatefulWidget {
  const _NameStep({
    required this.active,
    required this.firstNameController,
    required this.lastNameController,
    required this.onNext,
    required this.onBack,
  });

  final bool active;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  State<_NameStep> createState() => _NameStepState();
}

class _NameStepState extends State<_NameStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _entrance.forward();
  }

  @override
  void didUpdateWidget(covariant _NameStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _entrance.forward(from: 0);
    } else if (!widget.active && oldWidget.active) {
      _entrance.value = 0;
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  Animation<double> _stagger(double start, double end) => CurvedAnimation(
    parent: _entrance,
    curve: Interval(start, end, curve: Curves.easeOut),
  );

  Widget _riseIn(Animation<double> anim, Widget child) {
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerAnim = _stagger(0.0, 0.6);
    final fieldsAnim = _stagger(0.2, 0.8);
    final buttonAnim = _stagger(0.4, 1.0);

    return Stack(
      children: [
        _PhotoStepBackButton(onBack: widget.onBack),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: _GlassCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _riseIn(
                      headerAnim,
                      Text(
                        'What should Pulse call you?',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _riseIn(
                      headerAnim,
                      Text(
                        "We'll use this to personalize your greeting.",
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _riseIn(
                      fieldsAnim,
                      _GlassTextField(
                        controller: widget.firstNameController,
                        hint: 'First name',
                        autofocus: widget.active,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _riseIn(
                      fieldsAnim,
                      _GlassTextField(
                        controller: widget.lastNameController,
                        hint: 'Last name (optional)',
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => widget.onNext(),
                      ),
                    ),
                    const SizedBox(height: 28),
                    _riseIn(
                      buttonAnim,
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: theme.colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          onPressed: widget.onNext,
                          child: const Text(
                            'Next',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Explains the per-task check-in model before the user ever adds a
/// task — replaces what used to be a single daily check-in time picker
/// (see docs/ARCHITECTURE.md). Set over the "Start up page 4" backdrop,
/// with a staggered entrance (icon, then title, then body, then button)
/// plus a slow continuous "breathing" pulse on the icon — a nod to the
/// app's own name/heartbeat motif — each time [active] flips true (see
/// _NameStep's doc comment for why that's needed instead of initState).
class _CheckInExplainerStep extends StatefulWidget {
  const _CheckInExplainerStep({
    required this.active,
    required this.onNext,
    required this.onBack,
  });

  final bool active;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  State<_CheckInExplainerStep> createState() => _CheckInExplainerStepState();
}

class _CheckInExplainerStepState extends State<_CheckInExplainerStep>
    with TickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    if (widget.active) _entrance.forward();
  }

  @override
  void didUpdateWidget(covariant _CheckInExplainerStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _entrance.forward(from: 0);
    } else if (!widget.active && oldWidget.active) {
      _entrance.value = 0;
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    _pulse.dispose();
    super.dispose();
  }

  Animation<double> _stagger(double start, double end) => CurvedAnimation(
    parent: _entrance,
    curve: Interval(start, end, curve: Curves.easeOut),
  );

  Widget _riseIn(Animation<double> anim, Widget child) {
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconAnim = _stagger(0.0, 0.5);
    final titleAnim = _stagger(0.2, 0.7);
    final bodyAnim = _stagger(0.35, 0.85);
    final buttonAnim = _stagger(0.5, 1.0);

    return Stack(
      children: [
        _PhotoStepBackButton(onBack: widget.onBack),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            top: false,
            // No glass card here, unlike the other two photo steps —
            // this backdrop's water/arch is the whole point of the
            // image, and a blurred box over the bottom third hid most
            // of it. Text shadows (plus the already-strengthened bottom
            // scrim in _stepBackgrounds) keep it legible directly over
            // the photo instead.
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ScaleTransition(
                    scale: Tween<double>(
                      begin: 0.5,
                      end: 1.0,
                    ).animate(iconAnim),
                    child: FadeTransition(
                      opacity: iconAnim,
                      child: AnimatedBuilder(
                        animation: _pulse,
                        builder: (context, child) => Transform.scale(
                          scale: 1.0 + (_pulse.value * 0.08),
                          child: child,
                        ),
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Icon(
                            SolarIconsOutline.bolt,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _riseIn(
                    titleAnim,
                    Text(
                      'Pulse checks in per task',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        shadows: const [
                          Shadow(color: Colors.black54, blurRadius: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _riseIn(
                    bodyAnim,
                    Text(
                      'Not once a day — when you add a task, you\'ll say '
                      'when you expect to finish it, and Pulse checks in '
                      '5 minutes before that time to see how it\'s going.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
                        shadows: const [
                          Shadow(color: Colors.black54, blurRadius: 12),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _riseIn(
                    buttonAnim,
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: theme.colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                        onPressed: widget.onNext,
                        child: const Text(
                          'Next',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
            icon: const Icon(SolarIconsOutline.arrowLeft),
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
                    const Icon(SolarIconsOutline.clockCircle),
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
