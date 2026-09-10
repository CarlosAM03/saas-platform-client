import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF2457D6));
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF7F8FC),
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      cardTheme: const CardThemeData(margin: EdgeInsets.zero),
    );
  }
}
