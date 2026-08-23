// Widget tests for lib/widgets/breathing_circle.dart.
//
// The breath animation repeats forever (`..repeat(reverse: true)`), so these
// tests use bounded `tester.pump(duration)` calls rather than
// `pumpAndSettle()` — settle would never return since a frame is always
// pending. Each test unmounts the widget at the end (pumping a plain
// SizedBox in its place) so the AnimationController(s) are disposed and no
// ticker is left running past the test.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindbridge/widgets/breathing_circle.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('renders with a single fixed color', (tester) async {
    await tester.pumpWidget(_wrap(const BreathingCircle(color: Colors.blue)));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(BreathingCircle), findsOneWidget);
    expect(find.byType(Transform), findsWidgets);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('renders and animates through a color cycle when colors is given', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const BreathingCircle(
          colors: [Colors.blue, Colors.red, Colors.green],
          cycleDuration: Duration(milliseconds: 100),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.byType(BreathingCircle), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a single-item colors list behaves like a fixed color', (tester) async {
    await tester.pumpWidget(_wrap(const BreathingCircle(colors: [Colors.purple])));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(BreathingCircle), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('respects a custom size', (tester) async {
    await tester.pumpWidget(_wrap(const BreathingCircle(color: Colors.blue, size: 48)));
    await tester.pump();

    final container = tester.widget<Container>(
      find.descendant(of: find.byType(BreathingCircle), matching: find.byType(Container)),
    );
    expect(container.constraints, const BoxConstraints.tightFor(width: 48, height: 48));

    await tester.pumpWidget(const SizedBox());
  });

  test('asserts that at least one of color or colors is provided', () {
    expect(() => BreathingCircle(), throwsAssertionError);
  });
}
