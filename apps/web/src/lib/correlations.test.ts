import { describe, expect, test } from 'vitest'
import { computeCorrelations } from './correlations'
import type { LogWithActivities } from './activityService'
import type { ActivityTag } from '../../../../shared/types'

function tag(id: string): ActivityTag {
  return { id, user_id: 'u1', slug: id, label: id, emoji: '🏷️', created_at: '2026-01-01T00:00:00Z' }
}

function entry(moodScore: number, activities: ActivityTag[]): LogWithActivities {
  return { moodLogId: `log-${Math.random()}`, moodScore, loggedAt: '2026-01-01T00:00:00Z', activities }
}

describe('computeCorrelations', () => {
  test('empty entries -> empty positive and negative', () => {
    const result = computeCorrelations([], [tag('school')])
    expect(result.positive).toEqual([])
    expect(result.negative).toEqual([])
  })

  test('a tag under the minimum sample size (5) is excluded even with a huge delta', () => {
    const school = tag('school')
    const entries = [
      entry(10, [school]),
      entry(10, [school]),
      entry(10, [school]),
      entry(10, [school]),
      entry(1, []),
    ]
    const result = computeCorrelations(entries, [school])
    expect(result.positive).toEqual([])
    expect(result.negative).toEqual([])
  })

  test('a tag at exactly the minimum sample size is included', () => {
    const school = tag('school')
    const entries = [
      entry(9, [school]),
      entry(9, [school]),
      entry(9, [school]),
      entry(9, [school]),
      entry(9, [school]),
      entry(3, []),
    ]
    const result = computeCorrelations(entries, [school])
    expect(result.positive).toHaveLength(1)
    expect(result.positive[0]).toMatchObject({
      tagId: 'school',
      avgWith: 9,
      avgWithout: 3,
      delta: 6,
      sampleSize: 5,
    })
  })

  test('avgWithout falls back to the global average when every entry has the tag', () => {
    const school = tag('school')
    const entries = Array.from({ length: 5 }, () => entry(7, [school]))
    const result = computeCorrelations(entries, [school])
    // delta is 0 (avgWith == globalAvg == avgWithout fallback), so it lands
    // in neither bucket.
    expect(result.positive).toEqual([])
    expect(result.negative).toEqual([])
  })

  test('splits positive/negative deltas, sorts by |delta| descending, caps at 3 per side', () => {
    const tags = Array.from({ length: 5 }, (_, i) => tag(`tag${i}`))
    const entries: LogWithActivities[] = [
      ...Array.from({ length: 5 }, () => entry(10, [tags[0]])),
      ...Array.from({ length: 5 }, () => entry(9, [tags[1]])),
      ...Array.from({ length: 5 }, () => entry(8, [tags[2]])),
      ...Array.from({ length: 5 }, () => entry(2, [tags[3]])),
      ...Array.from({ length: 5 }, () => entry(1, [tags[4]])),
      ...Array.from({ length: 5 }, () => entry(5, [])),
    ]
    const result = computeCorrelations(entries, tags)

    expect(result.positive.map((r) => r.tagId)).toEqual(['tag0', 'tag1', 'tag2'])
    expect(result.negative.map((r) => r.tagId)).toEqual(['tag4', 'tag3'])
  })
})
