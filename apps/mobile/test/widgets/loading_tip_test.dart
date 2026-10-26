// Widget tests for lib/widgets/loading_tip.dart.
//
// The tip rotates on a repeating Timer, so each test unmounts the widget at
// the end (pumping a plain SizedBox in its place) to dispose the state and
// cancel the timer; flutter_test fails a test that leaves a timer pending.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindbridge/core/loading_tips.dart';
import 'package:mindbridge/widgets/loading_tip.dart';

Widget _wrap(Widget child, {bool disableAnimations = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(body: Center(child: child)),
      ),
    );

void main() {
  testWidgets('renders the label and a tip from the list', (tester) async {
    await tester.pumpWidget(_wrap(LoadingTip(random: Random(1))));

    expect(find.text('QUICK TIP'), findsOneWidget);
    final shown = kLoadingTips.where((t) => find.text(t).evaluate().isNotEmpty);
    expect(shown.length, 1);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('starts on the given index', (tester) async {
    await tester.pumpWidget(_wrap(const LoadingTip(startIndex: 3)));
    expect(find.text(kLoadingTips[3]), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('advances to the next tip after the interval and fades', (tester) async {
    await tester.pumpWidget(_wrap(const LoadingTip(startIndex: 0)));
    expect(find.text(kLoadingTips[0]), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 3999));
    expect(find.text(kLoadingTips[0]), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1));
    // Mid-fade, both tips are briefly in the tree.
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text(kLoadingTips[1]), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(kLoadingTips[0]), findsNothing);
    expect(find.text(kLoadingTips[1]), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('wraps from the last tip back to the first', (tester) async {
    await tester.pumpWidget(_wrap(LoadingTip(startIndex: kLoadingTips.length - 1)));
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(kLoadingTips.first), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('with reduced motion it swaps instantly but still rotates', (tester) async {
    await tester.pumpWidget(_wrap(const LoadingTip(startIndex: 0), disableAnimations: true));
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    expect(find.text(kLoadingTips[0]), findsNothing);
    expect(find.text(kLoadingTips[1]), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('is a live region', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_wrap(const LoadingTip(startIndex: 0)));
    expect(
      tester.getSemantics(find.text(kLoadingTips[0])),
      matchesSemantics(label: kLoadingTips[0], isLiveRegion: true),
    );
    await tester.pumpWidget(const SizedBox());
    handle.dispose();
  });

  testWidgets('disposes cleanly: no timer left running after unmount', (tester) async {
    await tester.pumpWidget(_wrap(const LoadingTip(startIndex: 0)));
    await tester.pumpWidget(const SizedBox());
    // Advancing past the interval must not throw or rebuild a disposed state.
    await tester.pump(const Duration(seconds: 10));
    expect(tester.takeException(), isNull);
  });

  test('has 12 tips and none contains an em dash or en dash', () {
    expect(kLoadingTips.length, 12);
    for (final tip in kLoadingTips) {
      expect(tip.contains('—'), isFalse);
      expect(tip.contains('–'), isFalse);
    }
  });
}
