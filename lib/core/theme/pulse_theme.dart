import 'package:flutter/material.dart';

/// Pulse's design system: calm, minimal, premium. See docs/PRODUCT.md
/// ("Design principles") for the intent behind these choices.
abstract final class PulseColors {
  // Deep navy primary
  static const Color navy = Color(0xFF0B1220);
  static const Color navyLight = Color(0xFF1B2438);

  // Electric blue / violet accent
  static const Color accent = Color(0xFF6C5CE7);
  static const Color accentAlt = Color(0xFF4F8CFF);

  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFF5A623);
  static const Color error = Color(0xFFE05260);
}

abstract final class PulseTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: PulseColors.accent,
      brightness: Brightness.light,
      primary: PulseColors.navy,
      secondary: PulseColors.accent,
      error: PulseColors.error,
    );
    return _base(scheme);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: PulseColors.accent,
      brightness: Brightness.dark,
      surface: PulseColors.navy,
      primary: PulseColors.accentAlt,
      secondary: PulseColors.accent,
      error: PulseColors.error,
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
