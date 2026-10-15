import 'package:flutter/material.dart';

/// MindBridge elevation levels. 0 = page background, 1 = resting card,
/// 2 = elevated/hovered/focused, 3 = modal/sheet/dropdown. `pressed` is an
/// interaction state, defined for forward use (no widget wires it yet —
/// press/release animation is a later step, pairs with AppMotion.instant).
enum ElevationLevel { none, resting, elevated, modal, pressed }

/// Radius scale — pairs with [ElevationLevel] (higher elevation -> bigger radius).
class AppRadius {
  AppRadius._();
  static const chip = 8.0;
  static const card = 12.0;
  static const sheet = 16.0;
  static const pill = 999.0;
}

/// Brightness-aware elevation -> BoxShadow/border/decoration mapping.
///
/// Notebook look: cards read as outlined paper (1px hairline) with at most
/// a faint neutral shadow. Higher levels add a soft neutral lift.
class AppElevation {
  AppElevation._();

  static List<BoxShadow> shadows(ElevationLevel level, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    switch (level) {
      case ElevationLevel.none:
        return const [];
      case ElevationLevel.resting:
        return dark ? _restingDark : _restingLight;
      case ElevationLevel.elevated:
        return dark ? _elevatedDark : _elevatedLight;
      case ElevationLevel.modal:
        return dark ? _modalDark : _modalLight;
      case ElevationLevel.pressed:
        return dark ? _pressedDark : _pressedLight;
    }
  }

  /// Notebook cards are outlined like paper: a 1px hairline in both themes,
  /// with only a whisper of shadow underneath.
  static Border? border(ElevationLevel level, Brightness brightness) {
    if (level == ElevationLevel.none) return null;
    return Border.all(
      color: brightness == Brightness.dark ? const Color(0xFF262A33) : const Color(0xFFE1E4EB),
    );
  }

  /// Migration entry point: replaces an ad-hoc
  /// `BoxDecoration(color: ..., borderRadius: ..., border: ...)`.
  static BoxDecoration decoration(
    BuildContext context, {
    ElevationLevel level = ElevationLevel.resting,
    double radius = AppRadius.card,
    Color? color,
  }) {
    final theme = Theme.of(context);
    return BoxDecoration(
      color: color ?? theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: shadows(level, theme.brightness),
      border: border(level, theme.brightness),
    );
  }

  // Shadow layers, transcribed from spec rgba() values via Color.fromRGBO —
  // no manual hex/alpha arithmetic, directly diffable against the spec.
  static const _restingLight = [
    BoxShadow(color: Color.fromRGBO(20, 22, 27, 0.04), offset: Offset(0, 1), blurRadius: 2),
  ];
  static const _restingDark = <BoxShadow>[];

  static const _elevatedLight = [
    BoxShadow(color: Color.fromRGBO(20, 22, 27, 0.06), offset: Offset(0, 2), blurRadius: 6),
    BoxShadow(color: Color.fromRGBO(20, 22, 27, 0.06), offset: Offset(0, 8), blurRadius: 20),
  ];
  // DERIVED — spec says "scaled proportionally from level 1", no exact
  // numbers given. Verify visually (see §5) and adjust before treating as final.
  static const _elevatedDark = [
    BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.35), offset: Offset(0, 2), blurRadius: 6),
    BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.45), offset: Offset(0, 8), blurRadius: 28),
  ];

  static const _modalLight = [
    BoxShadow(color: Color.fromRGBO(20, 22, 27, 0.10), offset: Offset(0, 8), blurRadius: 16),
    BoxShadow(color: Color.fromRGBO(20, 22, 27, 0.10), offset: Offset(0, 24), blurRadius: 48),
  ];
  // DERIVED — no explicit dark-modal spec line. Verify visually (see §5).
  static const _modalDark = [
    BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.45), offset: Offset(0, 8), blurRadius: 20),
    BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.55), offset: Offset(0, 24), blurRadius: 48),
  ];

  // Pressed: spec gives light only. translateY/scale is a widget-level
  // transform, not expressible here — pairs with AppMotion later.
  static const _pressedLight = [
    BoxShadow(color: Color.fromRGBO(28, 25, 23, 0.04), offset: Offset(0, 1), blurRadius: 2),
  ];
  // DERIVED single-layer dark analog. Verify visually (see §5).
  static const _pressedDark = [
    BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.30), offset: Offset(0, 1), blurRadius: 2),
  ];
}
