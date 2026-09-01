import 'package:flutter/material.dart';

/// Pulse's design system: "Navy Mirage" — cool, moody, matches the app
/// icon's diagonal navy/blue gradient. See docs/PRODUCT.md ("Design
/// principles") for the intent behind these choices. `navyDeep` and
/// `navyBlue` are the two colors from the user's own design swatch;
/// everything else here (the lighter primary for dark mode, the elevated
/// dark surface, the light-mode background, the error tone) is derived
/// to fit that palette rather than specified — flag any of those that
/// don't match the intended look.
abstract final class PulseColors {
  /// #141E30 — from the design swatch. Deep navy; the dark-mode surface
  /// and a strong contrast tone in light mode.
  static const Color navyDeep = Color(0xFF141E30);

  /// #3F5E96 — from the design swatch. Primary brand color, matching
  /// the app icon's lighter gradient half.
  static const Color navyBlue = Color(0xFF3F5E96);

  // Derived: a lighter tint of navyBlue — needed as the primary against
  // navyDeep in dark mode, since navyBlue itself doesn't have enough
  // contrast against a background that dark.
  static const Color navyBlueLight = Color(0xFF7C97C7);

  // Derived: a slightly-lifted navy for elevated surfaces in dark mode
  // (cards, sheets) so they read as "above" the base background rather
  // than blending into it.
  static const Color navyDeepLight = Color(0xFF1E2A42);

  // Derived: a cool, near-white background for light mode — keeps the
  // palette's cool undertone rather than defaulting to plain white.
  static const Color mist = Color(0xFFF1F4FA);

  // Derived: a warm coral-red error tone, deliberately outside the blue
  // family so error states stay visually distinct rather than blending
  // into the primary palette.
  static const Color coral = Color(0xFFC4574B);
}

abstract final class PulseTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: PulseColors.navyBlue,
      brightness: Brightness.light,
      primary: PulseColors.navyBlue,
      secondary: PulseColors.navyDeep,
      surface: PulseColors.mist,
      error: PulseColors.coral,
    );
    return _base(scheme);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: PulseColors.navyBlue,
      brightness: Brightness.dark,
      surface: PulseColors.navyDeep,
      primary: PulseColors.navyBlueLight,
      secondary: PulseColors.navyBlue,
      error: PulseColors.coral,
    );
    return _base(scheme);
  }

  static ThemeData _base(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      visualDensity: VisualDensity.comfortable,
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        elevation: 0,
        indicatorColor: scheme.secondaryContainer,
      ),
      textTheme: _textTheme(scheme),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
    );
  }

  static TextTheme _textTheme(ColorScheme scheme) {
    return const TextTheme(
      displayLarge: TextStyle(
        fontSize: 56,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.5,
        height: 1.0,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontSize: 16, height: 1.4),
      bodyMedium: TextStyle(fontSize: 14, height: 1.4),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    );
  }
}
