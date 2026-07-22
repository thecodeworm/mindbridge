import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { getMoodLogsInRange } from '../lib/moodService'
import type { MoodLog } from '../../../../shared/types'
import { MoodTrendChart } from '../components/MoodTrendChart'
import { HistoryList } from '../components/HistoryList'

export function HomePage() {
  const { user, signOut } = useAuth()
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
    return () => {
      cancelled = true
    }
  }, [user])

  return (
    <div className="min-h-screen bg-cream p-4 pb-24 sm:p-6">
      <div className="mx-auto w-full max-w-2xl space-y-6">
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold text-ink">Welcome, {displayName}</h1>
          <button
            type="button"
            onClick={() => signOut()}
            className="rounded-lg border border-border bg-surface px-3 py-1.5 text-sm font-medium text-ink transition-colors hover:bg-blue-tint"
          >
            Log out
          </button>
        </div>

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

        {user && <HistoryList userId={user.id} />}
      </div>
    </div>
  )
}
