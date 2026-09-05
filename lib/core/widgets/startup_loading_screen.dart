import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A branded loading screen shown once, right after the native splash
/// hands off to Flutter's first frame (see _StartupSequence in
/// app.dart). The native splash itself has to stay a static image —
/// Flutter isn't running yet — so anything animated lives here instead.
/// The progress bar is a fixed-duration decorative fill, not tied to
/// real startup work (that work already finished before this screen's
/// first frame even paints — see main.dart).
class StartupLoadingScreen extends StatefulWidget {
  const StartupLoadingScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<StartupLoadingScreen> createState() => _StartupLoadingScreenState();
}

class _StartupLoadingScreenState extends State<StartupLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onFinished();
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: const Alignment(0, -0.15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Pulse',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 48,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Re-imagine your daily workflow',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 14,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 40,
              right: 40,
              bottom: 64,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) => ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: _controller.value,
                        minHeight: 3,
                        backgroundColor: scheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(scheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Preparing your workspace …',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
