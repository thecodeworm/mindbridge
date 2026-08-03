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
  return `${d.toLocaleDateString(undefined, opts)} – ${end.toLocaleDateString(undefined, opts)}`
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
    if (!token) { setError('Not signed in'); setLoading(false); return }

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
      <div className="rounded-xl border border-border bg-surface p-4 shadow-sm sm:p-6">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-lg font-bold text-ink">Weekly review</h2>
            <p className="text-sm text-muted">{formatWeek(weekStart)}</p>
          </div>
          <button
            type="button"
            onClick={open}
            className="rounded-lg bg-blue-dark px-4 py-2 text-sm font-medium text-on-accent transition-opacity hover:opacity-90"
          >
            Generate
          </button>
        </div>
      </div>
    )
  }

  return (
    <div className="rounded-xl border border-border bg-surface p-4 shadow-sm sm:p-6">
      <h2 className="mb-1 text-lg font-bold text-ink">Weekly review</h2>
      <p className="mb-4 text-xs text-muted">{formatWeek(weekStart)}</p>

      {loading && (
        <div className="space-y-2">
          <div className="h-4 w-full animate-pulse rounded bg-field" />
          <div className="h-4 w-4/5 animate-pulse rounded bg-field" />
          <div className="h-4 w-3/5 animate-pulse rounded bg-field" />
        </div>
      )}

      {!loading && error && (
        <p className="rounded-lg bg-error-tint px-3 py-2 text-sm text-error">{error}</p>
      )}

      {!loading && !error && summary && (
        <div className="space-y-4">
          <p className="text-sm text-ink">{summary.summary}</p>
          {summary.highlights.length > 0 && (
            <ul className="space-y-1">
              {summary.highlights.map((h, i) => (
                <li key={i} className="flex gap-2 text-sm text-muted">
                  <span>•</span>
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
