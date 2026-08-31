import 'package:flutter/material.dart';

/// Pulse's design system: "Eucalyptus Glow" — calm, minimal, botanical.
/// See docs/PRODUCT.md ("Design principles") for the intent behind these
/// choices. `cream` and `sage` are the two colors from the user's own
/// design swatch; everything else here (deeper/lighter sage, the dark-mode
/// background, the error tone) is derived to fit that palette rather than
/// specified — flag any of those that don't match the intended look.
abstract final class PulseColors {
  /// #F4EFE6 — from the design swatch. Light-mode surface/background.
  static const Color cream = Color(0xFFF4EFE6);

  /// #A7C4A0 — from the design swatch. Primary brand color.
  static const Color sage = Color(0xFFA7C4A0);

  // Derived: a deeper sage for contrast on cream (buttons, selected states)
  // and a lighter sage for use as the primary against a dark background.
  static const Color sageDeep = Color(0xFF6E8967);
  static const Color sageLight = Color(0xFFC3DABC);

  // Derived: a warm, deep green-charcoal dark-mode background — keeps the
  // botanical undertone rather than defaulting to a cold navy/black.
  static const Color charcoal = Color(0xFF1B211A);
  static const Color charcoalLight = Color(0xFF262E24);

  // Derived: a warm terracotta rather than a harsh red, to stay in the
  // same earthy family as the rest of the palette.
  static const Color terracotta = Color(0xFFC6674A);
}

abstract final class PulseTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: PulseColors.sage,
      brightness: Brightness.light,
      primary: PulseColors.sageDeep,
      secondary: PulseColors.sage,
      surface: PulseColors.cream,
      error: PulseColors.terracotta,
    );
    return _base(scheme);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: PulseColors.sage,
      brightness: Brightness.dark,
      surface: PulseColors.charcoal,
      primary: PulseColors.sageLight,
      secondary: PulseColors.sage,
      error: PulseColors.terracotta,
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
