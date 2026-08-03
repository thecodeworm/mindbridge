import { useEffect, useState } from 'react'
import type { ActivityTag } from '../../../../shared/types'
import { getActivityTags, getLogsWithActivities } from '../lib/activityService'
import { computeCorrelations, type CorrelationResult } from '../lib/correlations'

function CorrelationRow({ r, valence }: { r: CorrelationResult; valence: 'positive' | 'negative' }) {
  return (
    <div className="flex items-start gap-3 rounded-lg border border-border bg-field px-3 py-2.5">
      <span className="text-lg">{r.tagEmoji}</span>
      <div className="min-w-0 flex-1">
        <p className="text-sm font-medium text-ink">
          {r.tagLabel}
          <span className={`ml-2 text-xs font-normal ${valence === 'positive' ? 'text-success' : 'text-error'}`}>
            {valence === 'positive' ? '+' : ''}{r.delta.toFixed(1)}
          </span>
        </p>
        <p className="text-xs text-muted">
          Avg {r.avgWith}/10 with · {r.avgWithout}/10 without · {r.sampleSize} days
        </p>
      </div>
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

  if (loading) return <div className="h-24 animate-pulse rounded-xl border border-border bg-surface" />

  return (
    <div className="rounded-xl border border-border bg-surface p-4 shadow-sm sm:p-6">
      <h2 className="mb-1 text-lg font-bold text-ink">Insights</h2>
      <p className="mb-4 text-xs text-faint">
        Correlations, not causes. Patterns appear after about a week of tagging.
      </p>

      {empty && (
        <p className="py-4 text-center text-sm text-muted">
          Keep tagging activities — patterns appear after about a week.
        </p>
      )}

      {positive.length > 0 && (
        <div className="mb-4 space-y-2">
          <p className="text-xs font-medium uppercase tracking-wide text-success">Boosts mood</p>
          {positive.map((r) => <CorrelationRow key={r.tagId} r={r} valence="positive" />)}
        </div>
      )}

      {negative.length > 0 && (
        <div className="space-y-2">
          <p className="text-xs font-medium uppercase tracking-wide text-error">Lowers mood</p>
          {negative.map((r) => <CorrelationRow key={r.tagId} r={r} valence="negative" />)}
        </div>
      )}
    </div>
  )
}
