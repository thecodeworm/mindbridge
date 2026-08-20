import 'package:flutter/material.dart';

/// MindBridge motion tokens — durations, easing curves, spring presets.
///
/// Never use Curves.easeInOut / Curves.linear directly — reach for a named
/// curve below. High-frequency interactions (chip taps, toggles — dozens of
/// times per session) should use `instant` or no animation at all.
class AppMotion {
  AppMotion._();

  // ── Durations ────────────────────────────────────────────
  static const instant = Duration(milliseconds: 80);
  static const micro = Duration(milliseconds: 180);
  static const short = Duration(milliseconds: 250);
  static const medium = Duration(milliseconds: 350);
  static const long = Duration(milliseconds: 500);
  static const extraLong = Duration(milliseconds: 850);

  // ── Easing curves ────────────────────────────────────────
  static const standard = Cubic(0.2, 0, 0, 1);
  static const standardDecelerate = Cubic(0, 0, 0, 1);
  static const standardAccelerate = Cubic(0.3, 0, 1, 1);
  static const emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1); // hero entrances
  static const emphasizedAccelerate = Cubic(0.3, 0, 0.8, 0.15); // dismissals

  // Aliases the spec names explicitly onto Flutter built-ins.
  static const easeOutCubic = Curves.easeOutCubic;
  static const easeInOutCubic = Curves.easeInOutCubic;

  // ── Spring presets (mass: 1) ─────────────────────────────
  // For SpringSimulation-driven widgets. "default" is reserved in Dart, so
  // presets are `spring`-prefixed for a consistent namespace.
  static const springGentle = SpringDescription(mass: 1, stiffness: 120, damping: 14);
  static const springDefault = SpringDescription(mass: 1, stiffness: 170, damping: 26);
  static const springWobbly = SpringDescription(mass: 1, stiffness: 180, damping: 12);
  static const springStiff = SpringDescription(mass: 1, stiffness: 210, damping: 20);
  static const springSlow = SpringDescription(mass: 1, stiffness: 280, damping: 60);
}
