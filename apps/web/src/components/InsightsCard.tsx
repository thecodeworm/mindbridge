import { useEffect, useState } from 'react'
import type { ActivityTag } from '../../../../shared/types'
import { getActivityTags, getLogsWithActivities } from '../lib/activityService'
import { computeCorrelations, type CorrelationResult } from '../lib/correlations'

function CorrelationRow({ r, valence }: { r: CorrelationResult; valence: 'positive' | 'negative' }) {
  return (
    <div className="flex items-center gap-3 py-2">
      <span className="text-lg" aria-hidden>{r.tagEmoji}</span>
      <div className="min-w-0 flex-1">
        <p className="font-medium text-ink">{r.tagLabel}</p>
        <p className="text-sm text-muted">
          Avg {r.avgWith}/10 with · {r.avgWithout}/10 without · {r.sampleSize} days
        </p>
      </div>
      {/* Sage for lifts, slate (low end of the mood ramp) for dips: never red/green judgement. */}
      <span
        className="tabular rounded-lg px-2.5 py-1 text-sm font-semibold text-ink"
        style={{ backgroundColor: valence === 'positive' ? 'color-mix(in srgb, var(--success) 16%, transparent)' : 'color-mix(in srgb, #7c8ba8 18%, transparent)' }}
      >
        {valence === 'positive' ? '+' : ''}{r.delta.toFixed(1)}
      </span>
    </div>
  )
}

export function InsightsCard({ userId }: { userId: string }) {
  const [positive, setPositive] = useState<CorrelationResult[]>([])
  const [negative, setNegative] = useState<CorrelationResult[]>([])
  const [loading, setLoading] = useState(true)
  const [empty, setEmpty] = useState(false)

  useEffect(() => {
    Promise.all([getActivityTags(), getLogsWithActivities(userId, 90)]).then(
      ([tagRes, logRes]) => {
        if (tagRes.error || logRes.error) { setLoading(false); return }
        const tags: ActivityTag[] = tagRes.tags
        const result = computeCorrelations(logRes.entries, tags)
        setPositive(result.positive)
        setNegative(result.negative)
        setEmpty(result.positive.length === 0 && result.negative.length === 0)
        setLoading(false)
      },
    )
  }, [userId])

  if (loading) return <div className="card h-32 animate-pulse" />

  return (
    <div className="card p-4 sm:p-6">
      <h2 className="text-xl text-ink">What lifts you</h2>
      <p className="mb-4 mt-1 text-sm text-muted">
        Activities tagged on 5+ check-ins in the last 90 days, compared with your average. Patterns, not causes.
      </p>

      {empty && (
        <p className="rounded-xl bg-surface px-4 py-3.5 text-muted">
          Tag what you were doing when you check in. After about a week, patterns show up here.
        </p>
      )}

      {positive.length > 0 && (
        <div className="mb-4">
          <p className="text-sm font-semibold text-muted">Tends to lift your mood</p>
          {positive.map((r) => <CorrelationRow key={r.tagId} r={r} valence="positive" />)}
        </div>
      )}

      {negative.length > 0 && (
        <div>
          <p className="text-sm font-semibold text-muted">Tends to weigh on you</p>
          {negative.map((r) => <CorrelationRow key={r.tagId} r={r} valence="negative" />)}
        </div>
      )}
    </div>
  )
}
