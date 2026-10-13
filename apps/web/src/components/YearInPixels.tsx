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

  if (loading) return <div className="card h-40 animate-pulse" />
  const logged = Object.keys(scoreByDay).length

  return (
    <div className="card relative p-4 sm:p-6">
      <h2 className="font-body text-lg font-semibold text-ink">Year in pixels</h2>
      <p className="mb-4 mt-1 text-sm text-muted">
        {logged === 0
          ? 'One square per day. They fill with color as you check in.'
          : `${logged} day${logged === 1 ? '' : 's'} logged in the past year.`}
      </p>
      <div className="overflow-x-auto pb-1" ref={(el) => { if (el) el.scrollLeft = el.scrollWidth }}>
        <div className="flex w-max gap-[3px]">
          {weeks.map((week, wi) => (
            <div key={wi} className="flex flex-col gap-[3px]">
              {week.map((day) => {
                const score = scoreByDay[day]
                const isFuture = day > todayStr
                return (
                  <div
                    key={day}
                    className={`h-3 w-3 cursor-default rounded-[3px] ${day === todayStr ? 'ring-[1.5px] ring-blue-dark' : ''}`}
                    style={{
                      backgroundColor: isFuture
                        ? 'transparent'
                        : score != null
                        ? moodColor(score)
                        : 'var(--surface)',
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
      <div className="mt-3 flex items-center gap-1.5 text-xs text-muted">
        Heavy
        {[1.5, 3.5, 5.5, 7.5, 9.5].map((v) => (
          <span key={v} className="h-3 w-3 rounded-[3px]" style={{ backgroundColor: moodColor(v) }} />
        ))}
        Great
      </div>
      {tooltip && (
        <div className="pointer-events-none absolute -top-8 left-1/2 -translate-x-1/2 card-elevated px-2 py-1 text-xs">
          {tooltip.date}: {tooltip.score}/10
        </div>
      )}
    </div>
  )
}
