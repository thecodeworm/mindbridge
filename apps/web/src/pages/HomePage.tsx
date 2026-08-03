import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { getMoodLogsInRange } from '../lib/moodService'
import type { MoodLog } from '../../../../shared/types'
import { MoodTrendChart } from '../components/MoodTrendChart'
import { HistoryList } from '../components/HistoryList'
import { StreakBadge } from '../components/StreakBadge'
import { YearInPixels } from '../components/YearInPixels'
import { InsightsCard } from '../components/InsightsCard'
import { WeeklySummaryCard } from '../components/WeeklySummaryCard'

export function HomePage() {
  const { user } = useAuth()
  const navigate = useNavigate()
  const displayName = user?.user_metadata?.display_name ?? 'there'

  const [logs, setLogs] = useState<MoodLog[]>([])
  const [loadingLogs, setLoadingLogs] = useState(true)

  useEffect(() => {
    if (!user) return
    let cancelled = false
    setLoadingLogs(true)
    getMoodLogsInRange(user.id, 30).then(({ logs, error }) => {
      if (cancelled) return
      if (!error) setLogs(logs)
      setLoadingLogs(false)
    })
    return () => { cancelled = true }
  }, [user])

  return (
    <div className="min-h-screen bg-cream p-4 pb-24 sm:p-6">
      <div className="mx-auto w-full max-w-2xl space-y-6">
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold text-ink">Welcome, {displayName}</h1>
          <button
            type="button"
            onClick={() => navigate('/settings')}
            aria-label="Settings"
            className="flex h-9 w-9 items-center justify-center rounded-full border border-border bg-surface text-ink transition-colors hover:bg-blue-tint"
          >
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <circle cx="12" cy="12" r="3" />
              <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z" />
            </svg>
          </button>
        </div>

        <StreakBadge logs={logs} />

        {loadingLogs ? (
          <div className="h-72 animate-pulse rounded-xl border border-border bg-surface" />
        ) : (
          <MoodTrendChart logs={logs} />
        )}

        <button
          type="button"
          onClick={() => navigate('/log')}
          className="w-full rounded-lg bg-blue-dark px-6 py-3 font-medium text-on-accent transition-opacity hover:opacity-90"
        >
          Log today's mood
        </button>

        {user && (
          <>
            <HistoryList userId={user.id} />
            <InsightsCard userId={user.id} />
            <WeeklySummaryCard />
            <YearInPixels userId={user.id} />
          </>
        )}

        <div className="border-t border-border pt-4 text-center">
          <a
            href="/help"
            className="text-sm text-terra-dark transition-colors hover:underline"
          >
            Crisis resources & help
          </a>
        </div>
      </div>
    </div>
  )
}
