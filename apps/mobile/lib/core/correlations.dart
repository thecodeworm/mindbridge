// Pure correlation computation — mirrors apps/web/src/lib/correlations.ts
// Requires ≥5 tagged days per tag.

import 'models.dart';

const _kMinSample = 5;

class CorrelationResult {
  const CorrelationResult({
    required this.tag,
    required this.avgWith,
    required this.avgWithout,
    required this.delta,
    required this.sampleSize,
  });
  final ActivityTag tag;
  final double avgWith;
  final double avgWithout;
  final double delta;
  final int sampleSize;
}

typedef LogWithActivities = ({MoodLog log, List<ActivityTag> activities});

class CorrelationsOutput {
  const CorrelationsOutput({required this.positive, required this.negative});
  final List<CorrelationResult> positive;
  final List<CorrelationResult> negative;
}

CorrelationsOutput computeCorrelations(
  List<LogWithActivities> entries,
  List<ActivityTag> tags,
) {
  if (entries.isEmpty) return const CorrelationsOutput(positive: [], negative: []);

  final allScores = entries.map((e) => e.log.moodScore).toList();
  final globalAvg = allScores.reduce((a, b) => a + b) / allScores.length;

  final results = <CorrelationResult>[];

  for (final tag in tags) {
    final withTag = entries.where((e) => e.activities.any((a) => a.id == tag.id)).toList();
    if (withTag.length < _kMinSample) continue;

    final withoutTag = entries.where((e) => !e.activities.any((a) => a.id == tag.id)).toList();

    final avgWith = withTag.map((e) => e.log.moodScore).reduce((a, b) => a + b) / withTag.length;
    final avgWithout = withoutTag.isEmpty
        ? globalAvg
        : withoutTag.map((e) => e.log.moodScore).reduce((a, b) => a + b) / withoutTag.length;
    final delta = avgWith - avgWithout;

    results.add(CorrelationResult(
      tag: tag,
      avgWith: (avgWith * 10).round() / 10,
      avgWithout: (avgWithout * 10).round() / 10,
      delta: (delta * 10).round() / 10,
      sampleSize: withTag.length,
    ));
  }

  results.sort((a, b) => b.delta.abs().compareTo(a.delta.abs()));

  return CorrelationsOutput(
    positive: results.where((r) => r.delta > 0).take(3).toList(),
    negative: results.where((r) => r.delta < 0).take(3).toList(),
  );
}
