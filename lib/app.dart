import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/preferences/preferences_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/pulse_theme.dart';

class PulseApp extends ConsumerWidget {
  const PulseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'Pulse',
      debugShowCheckedModeBanner: false,
      theme: PulseTheme.light(),
      darkTheme: PulseTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      // The native splash has to stay static (Flutter isn't running
      // yet), but the handoff to this first real frame doesn't have to
      // be an abrupt cut — see docs/ARCHITECTURE.md. _StartupFadeIn
      // plays once, the first time this subtree mounts, then stays at
      // rest; later rebuilds (navigation, theme toggles) just pass
      // `child` straight through with no re-animation.
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        return _StartupFadeIn(child: child);
      },
    );
  }
}

class _StartupFadeIn extends StatefulWidget {
  const _StartupFadeIn({required this.child});

  final Widget child;

  @override
  State<_StartupFadeIn> createState() => _StartupFadeInState();
}

class _StartupFadeInState extends State<_StartupFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 0.92,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    // Wait for the first real frame to actually paint before starting
    // the fade — the Welcome step's background photo takes a moment to
    // decode, and starting the controller immediately (as this used to)
    // meant the fade finished on blank/placeholder content, with the
    // photo popping in afterward once decoded — invisible in practice.
    // Precaching it here guarantees the fade reveals fully-loaded
    // content instead of racing it. Harmless no-op cost for returning
    // users who land on Today instead of Welcome.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        await precacheImage(
          const AssetImage('assets/onboarding/welcome_background.jpg'),
          context,
        );
      } catch (_) {
        // Fine either way — proceed with the fade regardless.
      }
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
