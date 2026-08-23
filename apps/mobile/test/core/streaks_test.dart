// Unit tests for lib/core/streaks.dart — pure streak/practice-window
// computation, no dependencies. Log timestamps are built relative to
// DateTime.now() (rather than hardcoded dates) so the tests aren't flaky
// across days.
import 'package:flutter_test/flutter_test.dart';
import 'package:mindbridge/core/models.dart';
import 'package:mindbridge/core/streaks.dart';

MoodLog _logDaysAgo(int daysAgo, {int hour = 12}) {
  final now = DateTime.now();
  final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysAgo));
  return MoodLog(
    id: 'log-$daysAgo-$hour',
    userId: 'u1',
    moodScore: 5,
    moodTag: 'calm',
    loggedAt: DateTime(day.year, day.month, day.day, hour),
  );
}

void main() {
  group('computeStreaks', () {
    test('empty logs -> current 0, longest 0', () {
      final result = computeStreaks([]);
      expect(result.current, 0);
      expect(result.longest, 0);
    });

    test('single log today -> current 1, longest 1', () {
      final result = computeStreaks([_logDaysAgo(0)]);
      expect(result.current, 1);
      expect(result.longest, 1);
    });

    test('two consecutive days (today + yesterday) -> current 2, longest 2', () {
      final result = computeStreaks([_logDaysAgo(0), _logDaysAgo(1)]);
      expect(result.current, 2);
      expect(result.longest, 2);
    });

    test('multiple logs on the same day collapse to one day', () {
      final result = computeStreaks([
        _logDaysAgo(0, hour: 8),
        _logDaysAgo(0, hour: 20),
        _logDaysAgo(1, hour: 9),
      ]);
      expect(result.current, 2);
      expect(result.longest, 2);
    });

    test('a gap before today breaks the current streak but not longest', () {
      // Logged today and 3 days ago only — not consecutive.
      final result = computeStreaks([_logDaysAgo(0), _logDaysAgo(3)]);
      expect(result.current, 1);
      expect(result.longest, 1);
    });

    test('most recent log yesterday still counts as an active current streak', () {
      final result = computeStreaks([_logDaysAgo(1), _logDaysAgo(2)]);
      expect(result.current, 2);
      expect(result.longest, 2);
    });

    test('most recent log 2+ days ago resets current streak to 0', () {
      final result = computeStreaks([_logDaysAgo(2)]);
      expect(result.current, 0);
      expect(result.longest, 1);
    });

    test('longest run can exceed the current run', () {
      // A 3-day run (5,4,3 days ago), a gap, then a 2-day run ending today.
      final result = computeStreaks([
        _logDaysAgo(5),
        _logDaysAgo(4),
        _logDaysAgo(3),
        _logDaysAgo(1),
        _logDaysAgo(0),
      ]);
      expect(result.current, 2);
      expect(result.longest, 3);
    });

    test('current streak overtaking the prior longest updates longest too', () {
      final result = computeStreaks([
        _logDaysAgo(0),
        _logDaysAgo(1),
        _logDaysAgo(2),
        _logDaysAgo(3),
      ]);
      expect(result.current, 4);
      expect(result.longest, 4);
    });
  });

  group('computePracticeWindow', () {
    test('empty logs -> 0 practiced', () {
      final window = computePracticeWindow([]);
      expect(window.practiced, 0);
      expect(window.windowDays, 10);
    });

    test('counts distinct logged days within the default 10-day window', () {
      final window = computePracticeWindow([
        _logDaysAgo(0),
        _logDaysAgo(2),
        _logDaysAgo(4),
      ]);
      expect(window.practiced, 3);
      expect(window.windowDays, 10);
    });

    test('multiple logs on the same day only count once', () {
      final window = computePracticeWindow([
        _logDaysAgo(0, hour: 6),
        _logDaysAgo(0, hour: 18),
      ]);
      expect(window.practiced, 1);
    });

    test('logs outside the window are not counted', () {
      final window = computePracticeWindow([_logDaysAgo(15)]);
      expect(window.practiced, 0);
    });

    test('respects a custom windowDays value', () {
      final window = computePracticeWindow([
        _logDaysAgo(0),
        _logDaysAgo(4),
        _logDaysAgo(6),
      ], windowDays: 5);
      expect(window.practiced, 2);
      expect(window.windowDays, 5);
    });
  });
}
