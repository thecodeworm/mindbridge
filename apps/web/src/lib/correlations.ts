// Pure correlation computation — testable without UI.
// Requires ≥5 tagged days to surface a tag (below that, too few to be meaningful).

import type { LogWithActivities } from './activityService'

export interface CorrelationResult {
  tagId: string
  tagSlug: string
  tagLabel: string
  tagEmoji: string
  avgWith: number
  avgWithout: number
  delta: number
  sampleSize: number
}

const MIN_SAMPLE = 5

export function computeCorrelations(
  entries: LogWithActivities[],
  tags: { id: string; slug: string; label: string; emoji: string }[],
): { positive: CorrelationResult[]; negative: CorrelationResult[] } {
  const allScores = entries.map((e) => e.moodScore)
  const globalAvg = allScores.length > 0
    ? allScores.reduce((a, b) => a + b, 0) / allScores.length
    : 5

  const results: CorrelationResult[] = []

  for (const tag of tags) {
    const withTag = entries.filter((e) => e.activities.some((a) => a.id === tag.id))
    if (withTag.length < MIN_SAMPLE) continue

    const withoutTag = entries.filter((e) => !e.activities.some((a) => a.id === tag.id))

    const avgWith = withTag.reduce((s, e) => s + e.moodScore, 0) / withTag.length
    const avgWithout =
      withoutTag.length > 0
        ? withoutTag.reduce((s, e) => s + e.moodScore, 0) / withoutTag.length
        : globalAvg
    const delta = avgWith - avgWithout

    results.push({
      tagId: tag.id,
      tagSlug: tag.slug,
      tagLabel: tag.label,
      tagEmoji: tag.emoji,
      avgWith: Math.round(avgWith * 10) / 10,
      avgWithout: Math.round(avgWithout * 10) / 10,
      delta: Math.round(delta * 10) / 10,
      sampleSize: withTag.length,
    })
  }

  results.sort((a, b) => Math.abs(b.delta) - Math.abs(a.delta))

  return {
    positive: results.filter((r) => r.delta > 0).slice(0, 3),
    negative: results.filter((r) => r.delta < 0).slice(0, 3),
  }
}
