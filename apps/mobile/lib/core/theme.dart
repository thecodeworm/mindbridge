import 'package:flutter/material.dart';

/// MindBridge design tokens + light/dark [ThemeData]: the "Notebook"
/// direction (clean journal page, one ballpoint-blue accent, mood colors
/// used like highlighter pens). Mirrors CLAUDE.md § Design System and
/// apps/web/src/index.css.
///
/// Token names are kept from the earlier palette so call sites didn't all
/// have to change; read them by role:
///   cream  = page background      surface = inset wells, chips, toggles
///   card   = card fill            border  = hairlines and card outlines
///   blue*  = ballpoint primary    terra*  = the Help chip / crisis accent
class AppColors {
  AppColors._();

  // ── Light ────────────────────────────────────────────────
  static const cream = Color(0xFFF6F7F9);
  static const surface = Color(0xFFEEF0F4);
  static const border = Color(0xFFE1E4EB);
  static const field = Color(0xFFFFFFFF);
  static const card = Color(0xFFFFFFFF);

  static const blue = Color(0xFF3D5BE0);
  static const blueDark = Color(0xFF2446D8);
  static const blueTint = Color(0xFFE8ECFC);

  static const terra = Color(0xFFE07AAB);
  static const terraDark = Color(0xFFA3245F);
  static const terraTint = Color(0xFFFFF0F6);

  static const ink = Color(0xFF14161B);
  static const muted = Color(0xFF5C6270);
  static const faint = Color(0xFF8A909C);

  static const success = Color(0xFF2F7D5B);
  static const successTint = Color(0xFFE6F4EC);
  static const caution = Color(0xFF9A6B00);
  static const cautionTint = Color(0xFFFFF4D6);
  static const error = Color(0xFFB0365F);
  static const errorTint = Color(0xFFFCEBF1);

  // ── Dark (users journal at night) ────────────────────────
  static const dCream = Color(0xFF101216);
  static const dSurface = Color(0xFF20242C);
  static const dBorder = Color(0xFF262A33);
  static const dField = Color(0xFF181B21);
  static const dCard = Color(0xFF181B21);

  static const dBlue = Color(0xFF6A84FF);
  static const dBlueDark = Color(0xFF7D95FF);
  static const dBlueTint = Color(0xFF1C2340);

  static const dTerra = Color(0xFFE88BB8);
  static const dTerraDark = Color(0xFFFFB3D5);
  static const dTerraTint = Color(0xFF3A1527);

  static const dInk = Color(0xFFECEFF4);
  static const dMuted = Color(0xFF9097A3);
  static const dFaint = Color(0xFF6B7180);

  static const dSuccess = Color(0xFF6FCF9F);
  static const dSuccessTint = Color(0xFF15281F);
  static const dCaution = Color(0xFFE7C15A);
  static const dCautionTint = Color(0xFF2A2310);
  static const dError = Color(0xFFF08AAE);
  static const dErrorTint = Color(0xFF341622);

  /// Text drawn on top of a mood/highlighter color, in both themes.
  static const onMood = Color(0xFF14161B);
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
    onAccent: Color(0xFF0B1030),
    ink: AppColors.dInk,
    muted: AppColors.dMuted,
    faint: AppColors.dFaint,
    error: AppColors.dError,
    errorContainer: AppColors.dErrorTint,
    onErrorContainer: AppColors.dError,
  );

  /// Schibsted Grotesk (display: heavy, tight) + Hanken Grotesk (body).
  /// Display/headline/titleLarge get the heavy grotesk; titleMedium and
  /// below stay Hanken for UI-chrome legibility.
  static TextTheme _textTheme(Color ink) {
    final base = Typography.material2021(platform: TargetPlatform.iOS).black;
    final body = base.apply(fontFamily: 'Hanken Grotesk');
    TextStyle? heavy(TextStyle? s, FontWeight w, double tracking) => s?.copyWith(
          fontFamily: 'Schibsted Grotesk',
          fontWeight: w,
          letterSpacing: tracking,
          height: 1.05,
        );
    return body
        .copyWith(
          displayLarge: heavy(body.displayLarge, FontWeight.w900, -2.0),
          displayMedium: heavy(body.displayMedium, FontWeight.w900, -1.6),
          displaySmall: heavy(body.displaySmall, FontWeight.w900, -1.2),
          headlineLarge: heavy(body.headlineLarge, FontWeight.w900, -1.0),
          headlineMedium: heavy(body.headlineMedium, FontWeight.w900, -0.9),
          headlineSmall: heavy(body.headlineSmall, FontWeight.w800, -0.6),
          titleLarge: heavy(body.titleLarge, FontWeight.w800, -0.4),
          titleMedium: body.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          labelLarge: body.labelLarge?.copyWith(fontWeight: FontWeight.w700),
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
          borderRadius: BorderRadius.circular(10),
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
        titleTextStyle: textTheme.headlineSmall?.copyWith(fontSize: 26, fontWeight: FontWeight.w900),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        // Active tab = a ballpoint underline, not a filled pill.
        indicatorColor: Colors.transparent,
        indicatorShape: UnderlineInputBorder(borderSide: BorderSide(color: accent, width: 2.5)),
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected) ? ink : muted,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? ink : muted,
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
        side: BorderSide(color: border, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontFamily: 'Schibsted Grotesk', fontWeight: FontWeight.w800, fontSize: 16),
        ).copyWith(side: _focusRing(accent)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: BorderSide(color: border),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontFamily: 'Schibsted Grotesk', fontWeight: FontWeight.w700, fontSize: 15),
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
