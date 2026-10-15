// Unit tests for lib/core/correlations.dart — pure mood/activity correlation
// computation, no dependencies. Mirrors apps/web/src/lib/correlations.test.ts.
import 'package:flutter_test/flutter_test.dart';
import 'package:mindbridge/core/correlations.dart';
import 'package:mindbridge/core/models.dart';

ActivityTag _tag(String id) =>
    ActivityTag(id: id, userId: 'u1', slug: id, label: id, emoji: '🏷️');

MoodLog _log(int score) => MoodLog(
      id: 'log-$score-${identityHashCode(score)}',
      userId: 'u1',
      moodScore: score,
      moodTag: 'calm',
      loggedAt: DateTime(2026, 1, 1),
    );

LogWithActivities _entry(int score, List<ActivityTag> activities) =>
    (log: _log(score), activities: activities);

void main() {
  group('computeCorrelations', () {
    test('empty entries -> empty positive and negative', () {
      final result = computeCorrelations([], [_tag('school')]);
      expect(result.positive, isEmpty);
      expect(result.negative, isEmpty);
    });

    test('a tag under the minimum sample size (5) is excluded even with a huge delta', () {
      final school = _tag('school');
      final entries = [
        _entry(10, [school]),
        _entry(10, [school]),
        _entry(10, [school]),
        _entry(10, [school]),
        _entry(1, <ActivityTag>[]),
      ];
      final result = computeCorrelations(entries, [school]);
      expect(result.positive, isEmpty);
      expect(result.negative, isEmpty);
    });

    test('a tag at exactly the minimum sample size is included', () {
      final school = _tag('school');
      final entries = [
        _entry(9, [school]),
        _entry(9, [school]),
        _entry(9, [school]),
        _entry(9, [school]),
        _entry(9, [school]),
        _entry(3, <ActivityTag>[]),
      ];
      final result = computeCorrelations(entries, [school]);
      expect(result.positive, hasLength(1));
      expect(result.positive.first.sampleSize, 5);
      expect(result.positive.first.avgWith, 9.0);
      expect(result.positive.first.avgWithout, 3.0);
      expect(result.positive.first.delta, 6.0);
    });

    test('avgWithout falls back to the global average when every entry has the tag', () {
      final school = _tag('school');
      final entries = List.generate(5, (_) => _entry(7, [school]));
      final result = computeCorrelations(entries, [school]);
      expect(result.positive, isEmpty);
      expect(result.negative, isEmpty);
      // delta should be 0 since avgWith == globalAvg == avgWithout fallback,
      // which is why it lands in neither positive nor negative bucket.
    });

    test('splits positive and negative deltas and sorts by |delta| descending, capped at 3 per side', () {
      final tags = List.generate(5, (i) => _tag('tag$i'));
      // tag0..tag2 boost mood (positive delta), tag3/tag4 hurt mood (negative delta).
      final entries = <LogWithActivities>[
        for (var i = 0; i < 5; i++) _entry(10, [tags[0]]),
        for (var i = 0; i < 5; i++) _entry(9, [tags[1]]),
        for (var i = 0; i < 5; i++) _entry(8, [tags[2]]),
        for (var i = 0; i < 5; i++) _entry(2, [tags[3]]),
        for (var i = 0; i < 5; i++) _entry(1, [tags[4]]),
        // baseline entries with no tags so "withoutTag" isn't empty for any tag
        for (var i = 0; i < 5; i++) _entry(5, <ActivityTag>[]),
      ];
      final result = computeCorrelations(entries, tags);

      expect(result.positive.length, 3);
      expect(result.negative.length, 2);
      // sorted by |delta| descending within each bucket
      expect(result.positive[0].tag.id, 'tag0');
      expect(result.positive[1].tag.id, 'tag1');
      expect(result.positive[2].tag.id, 'tag2');
      expect(result.negative[0].tag.id, 'tag4');
      expect(result.negative[1].tag.id, 'tag3');
    });
  });
}
