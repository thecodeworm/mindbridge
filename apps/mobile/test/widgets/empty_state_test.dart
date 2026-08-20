// Widget tests for lib/widgets/empty_state.dart — pure presentational
// widget, no external dependencies.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindbridge/widgets/empty_state.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders icon, headline, and copy', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const EmptyState(
          icon: Icons.mood,
          headline: 'Nothing here yet',
          copy: 'Log a mood to get started.',
        ),
      ),
    );

    expect(find.byIcon(Icons.mood), findsOneWidget);
    expect(find.text('Nothing here yet'), findsOneWidget);
    expect(find.text('Log a mood to get started.'), findsOneWidget);
  });

  testWidgets('does not render a CTA button when ctaLabel/onCta are omitted', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const EmptyState(
          icon: Icons.mood,
          headline: 'Nothing here yet',
          copy: 'Log a mood to get started.',
        ),
      ),
    );

    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('renders a CTA button when both ctaLabel and onCta are given', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(
        EmptyState(
          icon: Icons.mood,
          headline: 'Nothing here yet',
          copy: 'Log a mood to get started.',
          ctaLabel: 'Log mood',
          onCta: () => tapped = true,
        ),
      ),
    );

    expect(find.widgetWithText(FilledButton, 'Log mood'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Log mood'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('omits the CTA when only one of ctaLabel/onCta is provided', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const EmptyState(
          icon: Icons.mood,
          headline: 'Nothing here yet',
          copy: 'Log a mood to get started.',
          ctaLabel: 'Log mood',
          // onCta intentionally omitted
        ),
      ),
    );

    expect(find.byType(FilledButton), findsNothing);
  });
}
