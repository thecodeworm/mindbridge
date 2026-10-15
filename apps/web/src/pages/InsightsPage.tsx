import { useEffect, useState } from 'react'
import { useAuth } from '../context/AuthContext'
import { getMoodLogsInRange } from '../lib/moodService'
import type { MoodLog } from '../../../../shared/types'
import { MoodTrendChart } from '../components/MoodTrendChart'
import { InsightsCard } from '../components/InsightsCard'
import { WeeklySummaryCard } from '../components/WeeklySummaryCard'
import { YearInPixels } from '../components/YearInPixels'

/**
 * "Insights": trend chart, AI weekly reflection, activity correlations and
 * the year grid, moved off Today so the front door stays about checking in.
 */
export function InsightsPage() {
  const { user } = useAuth()
  const [logs, setLogs] = useState<MoodLog[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (!user) return
    let cancelled = false
    getMoodLogsInRange(user.id, 30).then(({ logs, error }) => {
      if (cancelled) return
      setLogs(error ? [] : logs)
      setLoading(false)
    })
    return () => {
      cancelled = true
    }
  }, [user])

  if (!user) return null

  return (
    <div>
      <h1 className="mb-6 text-3xl font-semibold text-ink">Insights</h1>
      <div className="space-y-4">
        {loading ? <div className="card h-80 animate-pulse" /> : <MoodTrendChart logs={logs} />}
        <WeeklySummaryCard />
        <InsightsCard userId={user.id} />
        <YearInPixels userId={user.id} />
      </div>
    </div>
  )
}
