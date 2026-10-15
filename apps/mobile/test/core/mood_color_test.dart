// Unit tests for lib/core/mood_color.dart — pure function, no dependencies.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindbridge/core/mood_color.dart';

void main() {
  group('moodColor', () {
    test('returns one solid color per two-score band', () {
      expect(moodColor(1), const Color(0xFFB9B3F2));
      expect(moodColor(2), const Color(0xFFB9B3F2));
      expect(moodColor(3), const Color(0xFF9ED3F5));
      expect(moodColor(4), const Color(0xFF9ED3F5));
      expect(moodColor(5), const Color(0xFFF2E58A));
      expect(moodColor(6), const Color(0xFFF2E58A));
      expect(moodColor(7), const Color(0xFFFFC07A));
      expect(moodColor(8), const Color(0xFFFFC07A));
      expect(moodColor(9), const Color(0xFFFF9FCB));
      expect(moodColor(10), const Color(0xFFFF9FCB));
    });

    test('scores above the last stop clamp to the last stop color', () {
      expect(moodColor(12), const Color(0xFFFF9FCB));
    });

    test('scores below the first stop fall back to the first stop color', () {
      expect(moodColor(0), const Color(0xFFB9B3F2));
      expect(moodColor(0.5), const Color(0xFFB9B3F2));
    });

    test('accepts int scores as well as double', () {
      expect(moodColor(5), moodColor(5.0));
    });
  });
}
