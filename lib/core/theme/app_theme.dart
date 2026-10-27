import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() {
    const primary = Color(0xFF2563EB);
    const border = Color(0xFFE2E8F0);
    final scheme = ColorScheme.fromSeed(seedColor: primary).copyWith(
      primary: primary,
      surface: Colors.white,
      error: const Color(0xFFDC2626),
      onSurface: const Color(0xFF0F172A),
      secondary: const Color(0xFF1E3A8A),
    );
    final base =
        ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: 'Inter');
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      textTheme: base.textTheme.copyWith(
        headlineLarge: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A)),
        headlineMedium: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A)),
        titleLarge: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A)),
        bodyLarge: const TextStyle(
            fontFamily: 'Inter', fontSize: 16, color: Color(0xFF0F172A)),
        bodyMedium: const TextStyle(
            fontFamily: 'Inter', fontSize: 14, color: Color(0xFF475569)),
      ),
      appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF0F172A),
          elevation: 0,
          surfaceTintColor: Colors.transparent),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: primary, width: 2)),
      ),
      filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
              minimumSize: const Size(48, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)))),
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
              minimumSize: const Size(48, 48),
              side: const BorderSide(color: border),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)))),
      cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: border))),
      navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Colors.white, indicatorColor: Color(0xFFDBEAFE)),
      navigationRailTheme: const NavigationRailThemeData(
          backgroundColor: Colors.white, indicatorColor: Color(0xFFDBEAFE)),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
      snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
    );
  }
}
