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
    surface: AppColors.surface,
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
    surface: AppColors.dSurface,
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

  static ThemeData _build({
    required Brightness brightness,
    required Color scaffold,
    required Color surface,
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
    );

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
      textTheme: Typography.material2021(platform: TargetPlatform.iOS)
          .black
          .apply(bodyColor: ink, displayColor: ink),
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
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: BorderSide(color: border),
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accent),
      ),
    );
  }
}
