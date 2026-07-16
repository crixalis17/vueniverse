import 'package:flutter/material.dart';

abstract final class PulseColors {
  static const canvas = Color(0xFF0B0E12);
  static const raisedCanvas = Color(0xFF10141A);
  static const surface = Color(0xFF151A21);
  static const surfaceAlt = Color(0xFF1B212A);
  static const elevated = Color(0xFF222A34);
  static const pressed = Color(0xFF2A333E);
  static const border = Color(0xFF2B333E);
  static const borderStrong = Color(0xFF3B4654);
  static const text = Color(0xFFF3F5F7);
  static const textSecondary = Color(0xFFB0B8C3);
  static const textTertiary = Color(0xFF7F8995);
  static const lime = Color(0xFFB8EF52);
  static const cyan = Color(0xFF62C7F3);
  static const mint = Color(0xFF62DDB2);
  static const violet = Color(0xFFA68AF4);
  static const coral = Color(0xFFF27E6F);
  static const amber = Color(0xFFF0B45B);
  static const nullBlue = Color(0xFF8298E8);
  static const error = Color(0xFFF16D70);
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
        fontSize: 42,
        height: 1.1,
        fontWeight: FontWeight.w600,
        letterSpacing: -1.4,
        color: PulseColors.text,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
      displayMedium: const TextStyle(
        fontSize: 34,
        height: 1.12,
        fontWeight: FontWeight.w600,
        letterSpacing: -1,
        color: PulseColors.text,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
      headlineLarge: const TextStyle(
        fontSize: 26,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.7,
        color: PulseColors.text,
      ),
      headlineSmall: const TextStyle(
        fontSize: 19,
        height: 1.3,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: PulseColors.text,
      ),
      titleMedium: const TextStyle(
        fontSize: 16,
        height: 1.29,
        fontWeight: FontWeight.w600,
        color: PulseColors.text,
      ),
      bodyLarge: const TextStyle(
        fontSize: 16,
        height: 1.45,
        color: PulseColors.text,
      ),
      bodyMedium: const TextStyle(
        fontSize: 14,
        height: 1.45,
        color: PulseColors.textSecondary,
      ),
      labelSmall: const TextStyle(
        fontSize: 12,
        height: 1.27,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.7,
        color: PulseColors.textTertiary,
      ),
    ),
    cardTheme: const CardThemeData(
      color: PulseColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
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
      height: 68,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: PulseColors.canvas,
      foregroundColor: PulseColors.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: PulseColors.text,
        fontSize: 19,
        fontWeight: FontWeight.w600,
      ),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      iconColor: PulseColors.textSecondary,
      textColor: PulseColors.text,
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: PulseColors.surfaceAlt,
      selectedColor: PulseColors.lime.withValues(alpha: 0.14),
      side: const BorderSide(color: PulseColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      labelStyle: const TextStyle(
        color: PulseColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 50),
        side: const BorderSide(color: PulseColors.borderStrong),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        foregroundColor: PulseColors.text,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: PulseColors.surfaceAlt,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: PulseColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: PulseColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
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
