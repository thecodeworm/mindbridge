import { useState } from 'react'
import { useAuth } from '../context/AuthContext'
import {
  getPreviousWeekStart,
  getOrGenerateWeeklySummary,
  type WeeklySummaryResult,
} from '../lib/weeklySummaryService'
import { supabase } from '../lib/supabaseClient'

function formatWeek(weekStart: string): string {
  const d = new Date(weekStart)
  const end = new Date(d)
  end.setDate(end.getDate() + 6)
  const opts: Intl.DateTimeFormatOptions = { month: 'short', day: 'numeric' }
  return `${d.toLocaleDateString(undefined, opts)} to ${end.toLocaleDateString(undefined, opts)}`
}

export function WeeklySummaryCard() {
  const { user } = useAuth()
  const [summary, setSummary] = useState<WeeklySummaryResult | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [opened, setOpened] = useState(false)

  const weekStart = getPreviousWeekStart()

  async function open() {
    if (!user) return
    setOpened(true)
    setLoading(true)
    setError(null)

    const { data: sessionData } = await supabase.auth.getSession()
    const token = sessionData.session?.access_token
    if (!token) { setError("We couldn't confirm you're signed in. Sign out and back in, then try again."); setLoading(false); return }

    const { summary: result, error: err } = await getOrGenerateWeeklySummary(
      user.id,
      weekStart,
      token,
    )
    setLoading(false)
    if (err) { setError(err); return }
    setSummary(result)
  }

  if (!opened) {
    return (
      <div className="card p-4 sm:p-6">
        <div className="flex items-baseline justify-between gap-3">
          <h2 className="text-xl text-ink">Your week in review</h2>
          <p className="shrink-0 text-sm text-muted">{formatWeek(weekStart)}</p>
        </div>
        <p className="mt-1 text-muted">
          A short, kind reflection on last week: what stood out and what seemed to help.
        </p>
        <button
          type="button"
          onClick={open}
          className="mt-4 rounded-[10px] border border-border bg-card px-5 py-2.5 font-semibold text-ink transition-colors hover:bg-blue-tint"
        >
          ✦ Write my week in review
        </button>
      </div>
    )
  }

  return (
    <div className="card p-4 sm:p-6">
      <div className="mb-3 flex items-baseline justify-between gap-3">
        <h2 className="text-xl text-ink">Your week in review</h2>
        <p className="shrink-0 text-sm text-muted">{formatWeek(weekStart)}</p>
      </div>

      {loading && (
        <div className="space-y-2">
          <div className="h-4 w-full animate-pulse rounded bg-surface" />
          <div className="h-4 w-4/5 animate-pulse rounded bg-surface" />
          <div className="h-4 w-3/5 animate-pulse rounded bg-surface" />
        </div>
      )}

      {!loading && error && (
        <p className="rounded-xl bg-error-tint px-4 py-3 text-ink">{error}</p>
      )}

      {!loading && !error && summary && (
        <div className="space-y-4">
          <p className="text-lg leading-relaxed text-ink">{summary.summary}</p>
          {summary.highlights.length > 0 && (
            <ul className="space-y-1.5">
              {summary.highlights.map((h, i) => (
                <li key={i} className="flex gap-2.5 text-muted">
                  <span className="mt-2 h-1.5 w-1.5 shrink-0 rounded-full bg-blue-dark" aria-hidden />
                  <span>{h}</span>
                </li>
              ))}
            </ul>
          )}
        </div>
      )}
    </div>
  )
}
