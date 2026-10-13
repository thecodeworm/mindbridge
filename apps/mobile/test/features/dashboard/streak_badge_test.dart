// Widget tests for lib/features/dashboard/streak_badge.dart.
//
// StreakBadge normally reads the signed-in user id from
// `Supabase.instance.client` and persists milestone state via
// FlutterSecureStorage — both real network/platform-channel dependencies
// that aren't available in a plain widget test. The `currentUserId` and
// `milestoneStore` constructor params (added alongside this test file) are
// the DI shim that unblocks testing this widget: pass `() => null` to skip
// the milestone check entirely, or a fixed id plus an in-memory
// FakeMilestoneStore to exercise the milestone-pop path.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindbridge/core/models.dart';
import 'package:mindbridge/features/dashboard/streak_badge.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

MoodLog _log(int daysAgo) => MoodLog(
      id: 'log-$daysAgo',
      userId: 'u1',
      moodScore: 5,
      moodTag: 'calm',
      loggedAt: DateTime.now().subtract(Duration(days: daysAgo)),
    );

class FakeMilestoneStore implements MilestoneStore {
  FakeMilestoneStore({int initial = 0}) : _stored = initial;

  int _stored;
  final List<int> setCalls = [];

  @override
  Future<int> lastCelebrated(String userId) async => _stored;

  @override
  Future<void> setLastCelebrated(String userId, int value) async {
    _stored = value;
    setCalls.add(value);
  }
}

void main() {
  testWidgets('renders nothing when logs is empty', (tester) async {
    await tester.pumpWidget(
      _wrap(StreakBadge(logs: const [], currentUserId: () => null)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(StreakBadge), findsOneWidget);
    expect(find.byIcon(Icons.spa_outlined), findsNothing);
  });

  testWidgets('shows the practiced count and personal best', (tester) async {
    final logs = [_log(0), _log(1), _log(2)];
    await tester.pumpWidget(
      _wrap(StreakBadge(logs: logs, currentUserId: () => null)),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.spa_outlined), findsOneWidget);
    expect(find.text("You've practiced 3 of 10 days"), findsOneWidget);
    expect(find.text('Personal best: 3 days'), findsOneWidget);
  });

  testWidgets('singular "day" wording when personal best is exactly 1', (tester) async {
    await tester.pumpWidget(
      _wrap(StreakBadge(logs: [_log(0)], currentUserId: () => null)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Personal best: 1 day'), findsOneWidget);
  });

  testWidgets('milestone check no-ops when currentUserId resolves to null', (tester) async {
    final store = FakeMilestoneStore();
    await tester.pumpWidget(
      _wrap(
        StreakBadge(
          logs: [_log(0), _log(1)],
          currentUserId: () => null,
          milestoneStore: store,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("You've practiced 2 of 10 days"), findsOneWidget);
    expect(store.setCalls, isEmpty);
  });

  testWidgets('persists a new milestone when longest exceeds the stored value', (tester) async {
    final store = FakeMilestoneStore(initial: 1);
    final logs = [_log(0), _log(1), _log(2)]; // longest == 3

    await tester.pumpWidget(
      _wrap(
        StreakBadge(
          logs: logs,
          currentUserId: () => 'user-1',
          milestoneStore: store,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(store.setCalls, [3]);
  });

  testWidgets('does not re-persist when longest has already been celebrated', (tester) async {
    final store = FakeMilestoneStore(initial: 3);
    final logs = [_log(0), _log(1), _log(2)]; // longest == 3, already stored

    await tester.pumpWidget(
      _wrap(
        StreakBadge(
          logs: logs,
          currentUserId: () => 'user-1',
          milestoneStore: store,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(store.setCalls, isEmpty);
  });

  testWidgets('didUpdateWidget re-checks the milestone when logs grows', (tester) async {
    final store = FakeMilestoneStore(initial: 0);

    await tester.pumpWidget(
      _wrap(
        StreakBadge(
          logs: [_log(0)],
          currentUserId: () => 'user-1',
          milestoneStore: store,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(store.setCalls, [1]);

    await tester.pumpWidget(
      _wrap(
        StreakBadge(
          logs: [_log(0), _log(1)],
          currentUserId: () => 'user-1',
          milestoneStore: store,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(store.setCalls, [1, 2]);
  });
}
