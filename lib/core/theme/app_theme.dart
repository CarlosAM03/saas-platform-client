import 'package:flutter/material.dart';

import 'catalog_palette.dart';

class AppTheme {
  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: CatalogPalette.cobalt,
      onPrimary: Colors.white,
      primaryContainer: CatalogPalette.accentSurface,
      onPrimaryContainer: CatalogPalette.ink,
      secondary: CatalogPalette.cobaltDark,
      onSecondary: Colors.white,
      secondaryContainer: CatalogPalette.lime,
      onSecondaryContainer: CatalogPalette.ink,
      tertiary: CatalogPalette.link,
      onTertiary: Colors.white,
      tertiaryContainer: CatalogPalette.rail,
      onTertiaryContainer: CatalogPalette.ink,
      surface: CatalogPalette.surface,
      onSurface: CatalogPalette.ink,
      onSurfaceVariant: CatalogPalette.muted,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: CatalogPalette.surface,
      surfaceContainer: CatalogPalette.soft,
      surfaceContainerHigh: CatalogPalette.canvas,
      surfaceContainerHighest: CatalogPalette.rail,
      outline: CatalogPalette.outlineStrong,
      outlineVariant: CatalogPalette.outline,
      inverseSurface: CatalogPalette.cobaltDark,
      onInverseSurface: Colors.white,
      inversePrimary: CatalogPalette.lime,
      surfaceTint: Colors.transparent,
      error: CatalogPalette.error,
      onError: Colors.white,
      errorContainer: CatalogPalette.errorSurface,
      onErrorContainer: CatalogPalette.error,
    );
    const corners = BorderRadius.all(Radius.circular(2));
    const shape = RoundedRectangleBorder(borderRadius: corners);
    const panelShape = RoundedRectangleBorder(
      borderRadius: corners,
      side: BorderSide(color: CatalogPalette.outline),
    );
    const inputBorder = OutlineInputBorder(
      borderRadius: corners,
      borderSide: BorderSide(color: CatalogPalette.outlineStrong),
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Inter',
    );
    final text = base.textTheme.apply(
      bodyColor: CatalogPalette.ink,
      displayColor: CatalogPalette.ink,
    );

    return base.copyWith(
      scaffoldBackgroundColor: CatalogPalette.canvas,
      textTheme: text.copyWith(
        headlineLarge: text.headlineLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -1.35,
        ),
        headlineMedium: text.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -.85,
        ),
        headlineSmall: text.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -.6,
        ),
        titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        bodyMedium: text.bodyMedium?.copyWith(color: CatalogPalette.muted),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: CatalogPalette.cobalt,
        foregroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
        shape: Border(bottom: BorderSide(color: CatalogPalette.cobaltDark)),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: CatalogPalette.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 11,
        ),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: CatalogPalette.cobalt, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 44),
          backgroundColor: CatalogPalette.lime,
          foregroundColor: CatalogPalette.ink,
          disabledBackgroundColor: CatalogPalette.rail,
          disabledForegroundColor: CatalogPalette.muted,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          shape: shape,
        ).copyWith(side: _buttonBorder(CatalogPalette.cobaltDark)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 44),
          backgroundColor: CatalogPalette.surface,
          foregroundColor: CatalogPalette.cobaltDark,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape: shape,
        ).copyWith(side: _buttonBorder(CatalogPalette.outlineStrong)),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: CatalogPalette.link,
          shape: shape,
        ),
      ),
      cardTheme: const CardThemeData(
        color: CatalogPalette.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: panelShape,
      ),
      listTileTheme: const ListTileThemeData(
        selectedTileColor: CatalogPalette.accentSurface,
        selectedColor: CatalogPalette.ink,
        shape: shape,
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: shape,
        side: const BorderSide(color: CatalogPalette.outlineStrong),
        backgroundColor: CatalogPalette.surface,
        selectedColor: CatalogPalette.accentSurface,
        secondarySelectedColor: CatalogPalette.accentSurface,
        labelStyle: text.labelMedium,
        secondaryLabelStyle: text.labelMedium,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: CatalogPalette.rail,
        indicatorColor: CatalogPalette.lime,
        indicatorShape: panelShape,
        surfaceTintColor: Colors.transparent,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: CatalogPalette.rail,
        indicatorColor: CatalogPalette.lime,
        indicatorShape: panelShape,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: CatalogPalette.ink,
        unselectedLabelColor: CatalogPalette.muted,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: CatalogPalette.accentSurface,
          border: Border.fromBorderSide(
            BorderSide(color: CatalogPalette.outlineStrong),
          ),
          borderRadius: corners,
        ),
        dividerColor: CatalogPalette.outlineStrong,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: CatalogPalette.surface,
        surfaceTintColor: Colors.transparent,
        shape: panelShape,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: CatalogPalette.rail,
        surfaceTintColor: Colors.transparent,
        shape: shape,
      ),
      dividerTheme: const DividerThemeData(
        color: CatalogPalette.outline,
        thickness: 1,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: shape,
      ),
    );
  }

  static WidgetStateProperty<BorderSide> _buttonBorder(Color border) =>
      WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return const BorderSide(color: CatalogPalette.outline);
        }
        if (states.contains(WidgetState.focused)) {
          return const BorderSide(color: CatalogPalette.cobaltDark, width: 2);
        }
        return BorderSide(color: border);
      });
}
