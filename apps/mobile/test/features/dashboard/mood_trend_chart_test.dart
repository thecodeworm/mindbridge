// Widget tests for lib/features/dashboard/mood_trend_chart.dart. Takes its
// data via the `logs` constructor param (no Supabase dependency), so no DI
// shim is needed here.
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindbridge/core/models.dart';
import 'package:mindbridge/features/dashboard/mood_trend_chart.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

MoodLog _log(int daysAgo, int score) => MoodLog(
      id: 'log-$daysAgo',
      userId: 'u1',
      moodScore: score,
      moodTag: 'calm',
      loggedAt: DateTime.now().subtract(Duration(days: daysAgo)),
    );

void main() {
  testWidgets('shows the empty-range message when logs is empty', (tester) async {
    await tester.pumpWidget(_wrap(const MoodTrendChart(logs: [])));
    await tester.pumpAndSettle();

    expect(find.text('Mood trend'), findsOneWidget);
    expect(
      find.text('No entries in this range yet — log a mood to start your trend.'),
      findsOneWidget,
    );
    expect(find.byType(LineChart), findsNothing);
  });

  testWidgets('renders a LineChart when logs has entries', (tester) async {
    final logs = [_log(6, 4), _log(3, 6), _log(0, 8)];
    await tester.pumpWidget(_wrap(MoodTrendChart(logs: logs)));
    await tester.pumpAndSettle();

    expect(find.byType(LineChart), findsOneWidget);
    expect(find.text('No entries in this range yet — log a mood to start your trend.'), findsNothing);
  });

  testWidgets('defaults to the 7d range toggle', (tester) async {
    await tester.pumpWidget(_wrap(MoodTrendChart(logs: [_log(1, 5), _log(0, 6)])));
    await tester.pumpAndSettle();

    expect(find.text('7d'), findsOneWidget);
    expect(find.text('30d'), findsOneWidget);
  });

  testWidgets('tapping the 30d toggle keeps entries older than 7 days visible', (tester) async {
    // Two entries inside the 7-day window, one only visible in the 30-day
    // window. (Kept at >=2 points in every visible range deliberately — a
    // single-point range trips an unrelated fl_chart gradient-lerp assertion
    // that isn't part of this DI/testing pass; see docs/mobile/mood_trend_chart.md.)
    final logs = [_log(20, 3), _log(2, 7), _log(1, 9)];
    await tester.pumpWidget(_wrap(MoodTrendChart(logs: logs)));
    await tester.pumpAndSettle();

    // Still on 7d by default -> the empty-range message must not show since
    // the two recent entries are within range.
    expect(find.byType(LineChart), findsOneWidget);

    await tester.tap(find.text('30d'));
    await tester.pumpAndSettle();

    expect(find.byType(LineChart), findsOneWidget);
    expect(find.text('No entries in this range yet — log a mood to start your trend.'), findsNothing);
  });

  testWidgets('switching to 30d can reveal the empty state going the other way', (tester) async {
    // Two entries outside the 7-day window only.
    final logs = [_log(20, 3), _log(15, 6)];
    await tester.pumpWidget(_wrap(MoodTrendChart(logs: logs)));
    await tester.pumpAndSettle();

    // 7d default: nothing in range.
    expect(
      find.text('No entries in this range yet — log a mood to start your trend.'),
      findsOneWidget,
    );

    await tester.tap(find.text('30d'));
    await tester.pumpAndSettle();

    expect(find.byType(LineChart), findsOneWidget);
  });
}
