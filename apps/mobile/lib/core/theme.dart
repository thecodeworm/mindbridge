import 'package:flutter/material.dart';

/// MindBridge design tokens + light/dark [ThemeData].
///
/// Mirrors the color system in CLAUDE.md § Design System. Wired in
/// `app.dart` via `theme` / `darkTheme` / `themeMode: ThemeMode.system`.
///
/// White-text buttons use the *dark* accent variant in light mode and a
/// dark on-accent text in dark mode (where the accent fills are light),
/// so filled buttons stay AA-legible in both modes.
class AppColors {
  AppColors._();

  // ── Light ────────────────────────────────────────────────
  static const cream = Color(0xFFFCF3E3);
  static const surface = Color(0xFFF4EFE6);
  static const border = Color(0xFFE5DDD0);
  static const field = Color(0xFFFFFFFF);

  /// Card fill. Slightly lifted off the cream page (rather than the darker
  /// `surface` beige, which made every card read as a muddy inset). The
  /// beige `surface` is still used for inset wells, chips and toggles.
  static const card = Color(0xFFFFFCF7);

  static const blue = Color(0xFF4A80B5);
  static const blueDark = Color(0xFF3A6A9A);
  static const blueTint = Color(0xFFEEF4FA);

  static const terra = Color(0xFFC97B52);
  static const terraDark = Color(0xFFB56840);
  static const terraTint = Color(0xFFFBF0E9);

  static const ink = Color(0xFF1C1917);
  static const muted = Color(0xFF78716C);
  static const faint = Color(0xFFA8A29E);

  static const success = Color(0xFF5B8C6E);
  static const successTint = Color(0xFFEAF1EB);
  static const caution = Color(0xFFB98A34);
  static const cautionTint = Color(0xFFFAF1DE);
  static const error = Color(0xFFB4534B);
  static const errorTint = Color(0xFFF9EBEA);

  // ── Dark (warm — users journal at night) ─────────────────
  static const dCream = Color(0xFF1C1815);
  static const dSurface = Color(0xFF2A2420);
  static const dBorder = Color(0xFF3D3530);
  static const dField = Color(0xFF322B26);
  static const dCard = Color(0xFF26201C);

  static const dBlue = Color(0xFF6B9DCE);
  static const dBlueDark = Color(0xFF8BB5E0);
  static const dBlueTint = Color(0xFF1A2636);

  static const dTerra = Color(0xFFD89468);
  static const dTerraDark = Color(0xFFE8A882);
  static const dTerraTint = Color(0xFF2D1F16);

  static const dInk = Color(0xFFF4EFE6);
  static const dMuted = Color(0xFFB8AFA6);
  static const dFaint = Color(0xFF7A6E67);

  static const dSuccess = Color(0xFF7AAF8E);
  static const dSuccessTint = Color(0xFF1A2920);
  static const dCaution = Color(0xFFD4A84A);
  static const dCautionTint = Color(0xFF2A2210);
  static const dError = Color(0xFFD47068);
  static const dErrorTint = Color(0xFF2A1815);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(
    brightness: Brightness.light,
    scaffold: AppColors.cream,
    surface: AppColors.card,
    inset: AppColors.surface,
    field: AppColors.field,
    border: AppColors.border,
    accent: AppColors.blueDark,
    onAccent: Colors.white,
    ink: AppColors.ink,
    muted: AppColors.muted,
    faint: AppColors.faint,
    error: AppColors.error,
    errorContainer: AppColors.errorTint,
    onErrorContainer: AppColors.error,
  );

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    scaffold: AppColors.dCream,
    surface: AppColors.dCard,
    inset: AppColors.dSurface,
    field: AppColors.dField,
    border: AppColors.dBorder,
    accent: AppColors.dBlueDark,
    onAccent: AppColors.dCream,
    ink: AppColors.dInk,
    muted: AppColors.dMuted,
    faint: AppColors.dFaint,
    error: AppColors.dError,
    errorContainer: AppColors.dErrorTint,
    onErrorContainer: AppColors.dError,
  );

  /// Fraunces (display) + Figtree (body), per
  /// docs/research/00-design-direction.md §3. `titleLarge` — screen/AppBar
  /// titles — is treated as a display moment too; `titleMedium`/`titleSmall`
  /// and everything below stay Figtree for UI-chrome legibility.
  static TextTheme _textTheme(Color ink) {
    final base = Typography.material2021(platform: TargetPlatform.iOS).black;
    // Both families are bundled in assets/fonts (see pubspec.yaml).
    final body = base.apply(fontFamily: 'Figtree');
    final display = base.apply(fontFamily: 'Fraunces');
    return body
        .copyWith(
          displayLarge: display.displayLarge,
          displayMedium: display.displayMedium,
          displaySmall: display.displaySmall,
          headlineLarge: display.headlineLarge,
          headlineMedium: display.headlineMedium,
          headlineSmall: display.headlineSmall,
          titleLarge: display.titleLarge,
        )
        .apply(bodyColor: ink, displayColor: ink);
  }

  static ThemeData _build({
    required Brightness brightness,
    required Color scaffold,
    required Color surface,
    required Color inset,
    required Color field,
    required Color border,
    required Color accent,
    required Color onAccent,
    required Color ink,
    required Color muted,
    required Color faint,
    required Color error,
    required Color errorContainer,
    required Color onErrorContainer,
  }) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: accent,
      onPrimary: onAccent,
      secondary: accent,
      onSecondary: onAccent,
      surface: surface,
      onSurface: ink,
      onSurfaceVariant: muted,
      error: error,
      onError: onAccent,
      errorContainer: errorContainer,
      onErrorContainer: onErrorContainer,
      outline: border,
      outlineVariant: border,
      surfaceContainerLowest: surface,
      surfaceContainerLow: inset,
      surfaceContainer: inset,
      surfaceContainerHigh: inset,
      surfaceContainerHighest: inset,
      primaryContainer: brightness == Brightness.dark
          ? AppColors.dBlueTint
          : AppColors.blueTint,
      onPrimaryContainer: accent,
      tertiary: brightness == Brightness.dark
          ? AppColors.dTerraDark
          : AppColors.terraDark,
      tertiaryContainer: brightness == Brightness.dark
          ? AppColors.dTerraTint
          : AppColors.terraTint,
      surfaceTint: Colors.transparent,
    );
    final textTheme = _textTheme(ink);

    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffold,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontSize: 22),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: brightness == Brightness.dark
            ? AppColors.dBlueTint
            : AppColors.blueTint,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected) ? accent : muted,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? accent : muted,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: scaffold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: accent),
      chipTheme: ChipThemeData(
        backgroundColor: field,
        selectedColor: brightness == Brightness.dark
            ? AppColors.dBlueTint
            : AppColors.blueTint,
        side: BorderSide(color: border),
        shape: const StadiumBorder(),
        labelStyle: textTheme.bodyMedium?.copyWith(color: ink),
        checkmarkColor: accent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: field,
        hintStyle: TextStyle(color: faint),
        labelStyle: TextStyle(color: muted),
        helperStyle: TextStyle(color: faint, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        enabledBorder: inputBorder(border),
        border: inputBorder(border),
        focusedBorder: inputBorder(accent, 2),
        errorBorder: inputBorder(error),
        focusedErrorBorder: inputBorder(error, 2),
        errorStyle: TextStyle(color: error),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: onAccent,
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder(),
        ).copyWith(side: _focusRing(accent)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: BorderSide(color: border),
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder(),
        ).copyWith(side: _focusRing(accent, fallback: BorderSide(color: border))),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accent).copyWith(side: _focusRing(accent)),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: ink).copyWith(side: _focusRing(accent)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(focusColor: accent.withValues(alpha: 0.16)),
    );
  }
}

/// A visible 2px --blue-dark ring on keyboard focus, per the design system's
/// accessibility rule. [fallback] preserves a button style's unfocused border
/// (e.g. OutlinedButton's resting side) when one is set.
WidgetStateProperty<BorderSide?> _focusRing(Color accent, {BorderSide? fallback}) {
  return WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.focused)) {
      return BorderSide(color: accent, width: 2);
    }
    return fallback;
  });
}
