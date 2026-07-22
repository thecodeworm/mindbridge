import 'package:flutter/material.dart';

// Mood scale color stops — matches CLAUDE.md § Mood Scale Stops and
// MoodTrendChart.tsx / moodColor.ts on web. Temperature ramp (slate ->
// gold), never red -> green; same hex values in light and dark mode.
const _kMoodStops = [
  (1.0, Color(0xFF7C8BA8)),
  (3.0, Color(0xFF96A9C1)),
  (5.0, Color(0xFFC4BCA9)),
  (7.0, Color(0xFFDFB05E)),
  (10.0, Color(0xFFDD955A)),
];

Color moodColor(num score) {
  final s = score.toDouble();
  for (int i = _kMoodStops.length - 1; i >= 0; i--) {
    if (s >= _kMoodStops[i].$1) {
      if (i == _kMoodStops.length - 1) return _kMoodStops[i].$2;
      final lo = _kMoodStops[i];
      final hi = _kMoodStops[i + 1];
      final t = (s - lo.$1) / (hi.$1 - lo.$1);
      return Color.lerp(lo.$2, hi.$2, t)!;
    }
  }
  return _kMoodStops[0].$2;
}
