import { useEffect, useState } from 'react'
import type { MoodLog } from '../../../../shared/types'
import { supabase } from '../lib/supabaseClient'
import { moodColor } from '../lib/moodColor'

function toLocalDateStr(iso: string): string {
  const d = new Date(iso)
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${y}-${m}-${day}`
}

function buildWeeks(): string[][] {
  const today = new Date()
  const todayStr = toLocalDateStr(today.toISOString())
  // Start from 52 weeks ago (Monday)
  const start = new Date(today)
  start.setDate(start.getDate() - 7 * 52)
  const day = start.getDay()
  start.setDate(start.getDate() - (day === 0 ? 6 : day - 1))

  const weeks: string[][] = []
  let current = new Date(start)
  while (toLocalDateStr(current.toISOString()) <= todayStr) {
    const week: string[] = []
    for (let d = 0; d < 7; d++) {
      week.push(toLocalDateStr(current.toISOString()))
      current.setDate(current.getDate() + 1)
    }
    weeks.push(week)
  }
  return weeks
}

export function YearInPixels({ userId }: { userId: string }) {
  const [scoreByDay, setScoreByDay] = useState<Record<string, number>>({})
  const [loading, setLoading] = useState(true)
  const [tooltip, setTooltip] = useState<{ date: string; score: number } | null>(null)

  useEffect(() => {
    const since = new Date()
    since.setDate(since.getDate() - 7 * 52)
    supabase
      .from('mood_logs')
      .select('mood_score, logged_at')
      .eq('user_id', userId)
      .gte('logged_at', since.toISOString())
      .then(({ data }) => {
        const map: Record<string, number> = {}
        for (const row of (data ?? []) as Pick<MoodLog, 'mood_score' | 'logged_at'>[]) {
          const key = toLocalDateStr(row.logged_at)
          // Keep highest score for the day
          if (!map[key] || row.mood_score > map[key]) map[key] = row.mood_score
        }
        setScoreByDay(map)
        setLoading(false)
      })
  }, [userId])

  const weeks = buildWeeks()
  const todayStr = toLocalDateStr(new Date().toISOString())

  if (loading) return <div className="h-28 animate-pulse rounded-xl border border-border bg-surface" />

  return (
    <div className="rounded-xl border border-border bg-surface p-4 shadow-sm sm:p-6 relative">
      <h2 className="mb-3 text-lg font-bold text-ink">Year in review</h2>
      <div className="overflow-x-auto">
        <div className="flex gap-0.5">
          {weeks.map((week, wi) => (
            <div key={wi} className="flex flex-col gap-0.5">
              {week.map((day) => {
                const score = scoreByDay[day]
                const isFuture = day > todayStr
                return (
                  <div
                    key={day}
                    className="h-3 w-3 rounded-sm cursor-default"
                    style={{
                      backgroundColor: isFuture
                        ? 'transparent'
                        : score != null
                        ? moodColor(score)
                        : 'var(--border)',
                    }}
                    title={score != null ? `${day}: ${score}/10` : day}
                    onMouseEnter={() => score != null && setTooltip({ date: day, score })}
                    onMouseLeave={() => setTooltip(null)}
                  />
                )
              })}
            </div>
          ))}
        </div>
      </div>
      {tooltip && (
        <div className="pointer-events-none absolute -top-8 left-1/2 -translate-x-1/2 rounded-md border border-border bg-surface px-2 py-1 text-xs shadow-md">
          {tooltip.date}: {tooltip.score}/10
        </div>
      )}
    </div>
  )
}
