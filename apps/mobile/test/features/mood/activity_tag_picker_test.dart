// Widget tests for lib/features/mood/activity_tag_picker.dart — pure
// presentational widget, no external dependencies.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindbridge/core/models.dart';
import 'package:mindbridge/features/mood/activity_tag_picker.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

List<ActivityTag> _tags() => [
      ActivityTag(id: '1', userId: 'u1', slug: 'exercise', label: 'Exercise', emoji: '🏃'),
      ActivityTag(id: '2', userId: 'u1', slug: 'sleep', label: 'Sleep', emoji: '😴'),
    ];

void main() {
  testWidgets('renders nothing when tags is empty', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ActivityTagPicker(tags: const [], selected: const {}, onChanged: (_) {}),
      ),
    );

    expect(find.byType(FilterChip), findsNothing);
  });

  testWidgets('renders one chip per tag with emoji + label', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ActivityTagPicker(tags: _tags(), selected: const {}, onChanged: (_) {}),
      ),
    );

    expect(find.byType(FilterChip), findsNWidgets(2));
    expect(find.text('🏃 Exercise'), findsOneWidget);
    expect(find.text('😴 Sleep'), findsOneWidget);
  });

  testWidgets('tapping an unselected chip adds its id via onChanged', (tester) async {
    Set<String>? result;
    await tester.pumpWidget(
      _wrap(
        ActivityTagPicker(
          tags: _tags(),
          selected: const {},
          onChanged: (next) => result = next,
        ),
      ),
    );

    await tester.tap(find.text('🏃 Exercise'));
    await tester.pump();

    expect(result, {'1'});
  });

  testWidgets('tapping an already-selected chip removes its id via onChanged', (tester) async {
    Set<String>? result;
    await tester.pumpWidget(
      _wrap(
        ActivityTagPicker(
          tags: _tags(),
          selected: const {'1', '2'},
          onChanged: (next) => result = next,
        ),
      ),
    );

    await tester.tap(find.text('🏃 Exercise'));
    await tester.pump();

    expect(result, {'2'});
  });

  testWidgets('selected chips render with FilterChip.selected true', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ActivityTagPicker(tags: _tags(), selected: const {'2'}, onChanged: (_) {}),
      ),
    );

    final chips = tester.widgetList<FilterChip>(find.byType(FilterChip)).toList();
    final sleepChip = chips.firstWhere((c) => (c.label as Text).data == '😴 Sleep');
    final exerciseChip = chips.firstWhere((c) => (c.label as Text).data == '🏃 Exercise');
    expect(sleepChip.selected, isTrue);
    expect(exerciseChip.selected, isFalse);
  });
}
