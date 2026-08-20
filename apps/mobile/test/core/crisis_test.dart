// Unit tests for lib/core/crisis.dart — pure crisis-chip visibility rule,
// extracted from entry_detail_screen.dart's inline condition.
import 'package:flutter_test/flutter_test.dart';
import 'package:mindbridge/core/crisis.dart';

void main() {
  group('shouldShowCrisisChip', () {
    test('false when neither the AI flag nor a low mood score is present', () {
      expect(shouldShowCrisisChip(crisisSignal: false, moodScore: 5), isFalse);
      expect(shouldShowCrisisChip(crisisSignal: false, moodScore: 3), isFalse);
    });

    test('true when the AI flagged a crisis signal, regardless of mood score', () {
      expect(shouldShowCrisisChip(crisisSignal: true, moodScore: 10), isTrue);
      expect(shouldShowCrisisChip(crisisSignal: true, moodScore: 5), isTrue);
    });

    test('true when mood score is 2 or below, regardless of the AI flag', () {
      expect(shouldShowCrisisChip(crisisSignal: false, moodScore: 2), isTrue);
      expect(shouldShowCrisisChip(crisisSignal: false, moodScore: 1), isTrue);
    });

    test('false right above the mood-score threshold with no crisis signal', () {
      expect(shouldShowCrisisChip(crisisSignal: false, moodScore: 3), isFalse);
    });

    test('true when both conditions hold', () {
      expect(shouldShowCrisisChip(crisisSignal: true, moodScore: 1), isTrue);
    });
  });
}
