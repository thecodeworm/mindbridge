import { useEffect, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { MOOD_TAGS } from '../../../../shared/types'
import { getEntryDetail } from '../lib/historyService'
import type { EntryDetail } from '../lib/historyService'
import { moodColor } from '../lib/moodColor'

function tagInfo(tag: string) {
  return MOOD_TAGS.find((t) => t.value === tag)
}

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString(undefined, {
    weekday: 'long',
    month: 'long',
    day: 'numeric',
    year: 'numeric',
  })
}

export function EntryDetailPage() {
  const { moodLogId } = useParams<{ moodLogId: string }>()
  const navigate = useNavigate()

  const [detail, setDetail] = useState<EntryDetail | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!moodLogId) return
    let cancelled = false
    setLoading(true)
    getEntryDetail(moodLogId).then(({ detail, error }) => {
      if (cancelled) return
      setDetail(detail)
      setError(error)
      setLoading(false)
    })
    return () => {
      cancelled = true
    }
  }, [moodLogId])

  return (
    <div className="flex min-h-screen items-start justify-center bg-cream p-4 pt-12">
      <div className="w-full max-w-md space-y-4">
        <button
          type="button"
          onClick={() => navigate('/')}
          className="text-sm font-medium text-muted transition-colors hover:text-ink"
        >
          ← Back to history
        </button>

        {loading && (
          <div className="animate-pulse space-y-4 rounded-xl border border-border bg-surface p-8 shadow-sm">
            <div className="h-6 w-2/3 rounded bg-field" />
            <div className="space-y-2">
              <div className="h-4 w-full rounded bg-field" />
              <div className="h-4 w-5/6 rounded bg-field" />
            </div>
          </div>
        )}

        {!loading && error && (
          <div className="rounded-xl border border-border bg-surface p-8 shadow-sm">
            <p className="rounded-lg bg-error-tint px-3 py-2 text-sm text-error">{error}</p>
          </div>
        )}

        {!loading && !error && detail && (
          <>
            <div className="space-y-4 rounded-xl border border-border bg-surface p-8 shadow-sm">
              <div className="flex items-center gap-3">
                <span
                  className="flex h-12 w-12 shrink-0 items-center justify-center rounded-full text-lg font-bold"
                  style={{ backgroundColor: moodColor(detail.moodLog.mood_score), color: '#1C1917' }}
                >
                  {detail.moodLog.mood_score}
                </span>
                <div>
                  <p className="font-medium text-ink">
                    {tagInfo(detail.moodLog.mood_tag)?.emoji} {tagInfo(detail.moodLog.mood_tag)?.label}
                  </p>
                  <p className="text-sm text-muted">{formatDate(detail.moodLog.logged_at)}</p>
                </div>
              </div>

              {detail.journalEntry && (
                <div className="space-y-1 border-t border-border pt-4">
                  <p className="text-sm font-medium text-muted">Journal</p>
                  <p className="whitespace-pre-wrap text-ink">{detail.journalEntry.body}</p>
                </div>
              )}
            </div>

            <div className="space-y-4 rounded-xl border border-border bg-surface p-8 shadow-sm">
              {detail.copingSuggestion ? (
                <>
                  <h1 className="text-2xl font-bold text-ink">{detail.copingSuggestion.technique_name}</h1>
                  <p className="text-muted">{detail.copingSuggestion.description}</p>
                  <ol className="list-decimal space-y-2 pl-5 text-ink">
                    {detail.copingSuggestion.steps.slice(0, 3).map((step, i) => (
                      <li key={i}>{step}</li>
                    ))}
                  </ol>
                </>
              ) : (
                <p className="text-sm text-muted">No coping suggestion was saved for this entry.</p>
              )}
            </div>
          </>
        )}
      </div>
    </div>
  )
}
