// Pure crisis-chip visibility rule — extracted from entry_detail_screen.dart
// (and mirrored by suggestion_screen.dart's inline check) so it's unit
// testable without building a widget tree.

/// Whether the crisis-resources chip should be shown for a coping
/// suggestion. True when the AI flagged the entry as a crisis signal, or
/// when the logged mood score is very low (<= 2) regardless of what the AI
/// flagged — the mood score is a purely local, deterministic backstop that
/// doesn't depend on the model having called it correctly.
bool shouldShowCrisisChip({required bool crisisSignal, required int moodScore}) {
  return crisisSignal || moodScore <= 2;
}
