// Unit tests for lib/core/mood_color.dart — pure function, no dependencies.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindbridge/core/mood_color.dart';

void main() {
  group('moodColor', () {
    test('returns the exact stop color at each defined stop', () {
      expect(moodColor(1), const Color(0xFF7C8BA8));
      expect(moodColor(3), const Color(0xFF96A9C1));
      expect(moodColor(5), const Color(0xFFC4BCA9));
      expect(moodColor(7), const Color(0xFFDFB05E));
      expect(moodColor(10), const Color(0xFFDD955A));
    });

    test('interpolates linearly between two adjacent stops', () {
      final expected = Color.lerp(
        const Color(0xFF7C8BA8),
        const Color(0xFF96A9C1),
        0.5,
      );
      expect(moodColor(2), expected);
    });

    test('scores above the last stop clamp to the last stop color', () {
      expect(moodColor(12), const Color(0xFFDD955A));
    });

    test('scores below the first stop fall back to the first stop color', () {
      expect(moodColor(0), const Color(0xFF7C8BA8));
      expect(moodColor(0.5), const Color(0xFF7C8BA8));
    });

    test('accepts int scores as well as double', () {
      expect(moodColor(5), moodColor(5.0));
    });
  });
}
