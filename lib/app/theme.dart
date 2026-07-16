import 'package:flutter/material.dart';

abstract final class PulseColors {
  static const canvas = Color(0xFF050707);
  static const raisedCanvas = Color(0xFF090C0B);
  static const surface = Color(0xFF101413);
  static const surfaceAlt = Color(0xFF161B19);
  static const elevated = Color(0xFF1C2220);
  static const pressed = Color(0xFF252C29);
  static const border = Color(0xFF252B29);
  static const borderStrong = Color(0xFF353D39);
  static const text = Color(0xFFF4F7F4);
  static const textSecondary = Color(0xFFA6AFAA);
  static const textTertiary = Color(0xFF747D78);
  static const lime = Color(0xFFC7FF3F);
  static const cyan = Color(0xFF55D8FF);
  static const mint = Color(0xFF5AF0BA);
  static const violet = Color(0xFF9B7BFF);
  static const coral = Color(0xFFFF725E);
  static const amber = Color(0xFFFFB547);
  static const nullBlue = Color(0xFF6F8CFF);
  static const error = Color(0xFFFF5D5D);
}

ThemeData buildPulseTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: PulseColors.lime,
        brightness: Brightness.dark,
        surface: PulseColors.surface,
      ).copyWith(
        primary: PulseColors.lime,
        onPrimary: PulseColors.canvas,
        secondary: PulseColors.cyan,
        onSecondary: PulseColors.canvas,
        surface: PulseColors.surface,
        onSurface: PulseColors.text,
        error: PulseColors.error,
        outline: PulseColors.border,
      );

  final base = ThemeData(
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: PulseColors.canvas,
    useMaterial3: true,
    fontFamily: 'Roboto',
  );

  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      displayLarge: const TextStyle(
        fontSize: 56,
        height: 1.07,
        fontWeight: FontWeight.w600,
        letterSpacing: -2.2,
        color: PulseColors.text,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
      displayMedium: const TextStyle(
        fontSize: 44,
        height: 1.09,
        fontWeight: FontWeight.w600,
        letterSpacing: -1.6,
        color: PulseColors.text,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
      headlineLarge: const TextStyle(
        fontSize: 28,
        height: 1.21,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.7,
        color: PulseColors.text,
      ),
      headlineSmall: const TextStyle(
        fontSize: 20,
        height: 1.3,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: PulseColors.text,
      ),
      titleMedium: const TextStyle(
        fontSize: 17,
        height: 1.29,
        fontWeight: FontWeight.w600,
        color: PulseColors.text,
      ),
      bodyLarge: const TextStyle(
        fontSize: 15,
        height: 1.47,
        color: PulseColors.text,
      ),
      bodyMedium: const TextStyle(
        fontSize: 13,
        height: 1.46,
        color: PulseColors.textSecondary,
      ),
      labelSmall: const TextStyle(
        fontSize: 11,
        height: 1.27,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.15,
        color: PulseColors.textTertiary,
      ),
    ),
    cardTheme: const CardThemeData(
      color: PulseColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(22)),
        side: BorderSide(color: PulseColors.border),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: PulseColors.border,
      thickness: 1,
      space: 1,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: PulseColors.raisedCanvas,
      indicatorColor: PulseColors.lime.withValues(alpha: 0.12),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? PulseColors.lime
              : PulseColors.textTertiary,
          size: 23,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? PulseColors.text
              : PulseColors.textTertiary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      height: 72,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 52),
        side: const BorderSide(color: PulseColors.borderStrong),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        foregroundColor: PulseColors.text,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: PulseColors.surfaceAlt,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: PulseColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: PulseColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: PulseColors.lime),
      ),
      hintStyle: const TextStyle(color: PulseColors.textTertiary),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: PulseColors.elevated,
      contentTextStyle: TextStyle(color: PulseColors.text),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
