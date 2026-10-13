import 'package:flutter/material.dart';

// Mood scale as highlighter-pen colors (the "Notebook" direction), heavy
// to great: lavender, sky, butter, tangerine, pink. Matches CLAUDE.md §
// Mood Scale Stops and apps/web/src/lib/moodColor.ts. Still a temperature
// ramp: no red, no green, nothing that reads as "bad day". Same values in
// light and dark; text on top always uses AppColors.onMood.
const _kMoodStops = [
  (1.0, Color(0xFFB9B3F2)),
  (2.5, Color(0xFF9ED3F5)),
  (4.5, Color(0xFFF2E58A)),
  (6.5, Color(0xFFFFC07A)),
  (8.5, Color(0xFFFF9FCB)),
];

/// Five solid highlighter shades, one per band of two scores (1-2, 3-4,
/// 5-6, 7-8, 9-10). No blending: mixing sky blue into butter yellow makes a
/// green, and green would read as "good".
Color moodColor(num score) {
  final s = score.toDouble();
  for (int i = _kMoodStops.length - 1; i >= 0; i--) {
    if (s >= _kMoodStops[i].$1) return _kMoodStops[i].$2;
  }
  return _kMoodStops[0].$2;
}

/// One plain word for a 1–10 score. Deliberately gentle at the low end
/// ("Heavy", not "Bad") per CLAUDE.md: no shade of the scale means failure.
String moodWord(num score) {
  final s = score.round();
  if (s <= 2) return 'Heavy';
  if (s <= 4) return 'Low';
  if (s <= 6) return 'Okay';
  if (s <= 8) return 'Good';
  return 'Great';
}
