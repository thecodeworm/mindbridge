import { useMemo, useState } from 'react'
import {
  Area,
  AreaChart,
  CartesianGrid,
  Dot,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts'
import type { DotProps } from 'recharts'
import type { MoodLog } from '../../../../shared/types'
import { MOOD_TAGS } from '../../../../shared/types'
import { moodColor } from '../lib/moodColor'

type RangeDays = 7 | 30

interface MoodTrendChartProps {
  logs: MoodLog[]
}

function tagLabel(tag: string): string {
  return MOOD_TAGS.find((t) => t.value === tag)?.label ?? tag
}

function formatTick(iso: string, rangeDays: RangeDays): string {
  const date = new Date(iso)
  return rangeDays === 7
    ? date.toLocaleDateString(undefined, { weekday: 'short' })
    : date.toLocaleDateString(undefined, { month: 'numeric', day: 'numeric' })
}

interface TooltipPayloadEntry {
  payload: MoodLog
}

function ChartTooltip({ active, payload }: { active?: boolean; payload?: TooltipPayloadEntry[] }) {
  if (!active || !payload?.length) return null
  const log = payload[0].payload
  const date = new Date(log.logged_at).toLocaleDateString(undefined, {
    weekday: 'short',
    month: 'short',
    day: 'numeric',
  })

  return (
    <div className="card-elevated px-3 py-2 text-sm">
      <p className="font-medium text-ink">{date}</p>
      <p className="text-muted">
        Score {log.mood_score} · {tagLabel(log.mood_tag)}
      </p>
    </div>
  )
}

function MoodDot(props: DotProps & { payload?: MoodLog }) {
  const { cx, cy, payload } = props
  if (cx == null || cy == null || !payload) return null
  return <Dot cx={cx} cy={cy} r={4.5} fill={moodColor(payload.mood_score)} stroke="var(--card)" strokeWidth={2} />
}

export function MoodTrendChart({ logs }: MoodTrendChartProps) {
  const [range, setRange] = useState<RangeDays>(7)

  const data = useMemo(() => {
    if (range === 7) {
      const since = Date.now() - 7 * 24 * 60 * 60 * 1000
      return logs.filter((l) => new Date(l.logged_at).getTime() >= since)
    }
    return logs
  }, [logs, range])

  // Stroke/fill follow the mood-temperature ramp point by point, matching
  // the Flutter chart's gradient line (slate lows, gold highs).
  const stops = data.map((d, i) => ({
    offset: data.length > 1 ? `${(i / (data.length - 1)) * 100}%` : '0%',
    color: moodColor(d.mood_score),
  }))
  const lastColor = data.length ? moodColor(data[data.length - 1].mood_score) : 'var(--blue)'

  return (
    <div className="card p-4 sm:p-6">
      <div className="mb-4 flex items-center justify-between">
        <h2 className="font-body text-lg font-semibold text-ink">Mood trend</h2>
        <div className="flex gap-1 rounded-full bg-surface p-1" role="group" aria-label="Range">
          {([7, 30] as const).map((d) => (
            <button
              key={d}
              type="button"
              onClick={() => setRange(d)}
              className={[
                'rounded-full px-3.5 py-1 text-sm font-semibold transition-colors',
                range === d ? 'bg-card text-ink shadow-sm' : 'text-muted hover:text-ink',
              ].join(' ')}
              aria-pressed={range === d}
            >
              {d}d
            </button>
          ))}
        </div>
      </div>

      {data.length === 0 ? (
        <p className="py-12 text-center text-muted">
          No check-ins in this range yet. Log one to start your trend.
        </p>
      ) : (
        <div className="h-56 w-full sm:h-64">
          <ResponsiveContainer width="100%" height="100%">
            <AreaChart data={data} margin={{ top: 10, right: 12, left: 0, bottom: 0 }}>
              <defs>
                <linearGradient id="moodStroke" x1="0" y1="0" x2="1" y2="0">
                  {stops.length > 1
                    ? stops.map((s, i) => <stop key={i} offset={s.offset} stopColor={s.color} />)
                    : [<stop key="a" offset="0%" stopColor={lastColor} />, <stop key="b" offset="100%" stopColor={lastColor} />]}
                </linearGradient>
                <linearGradient id="moodFill" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor={lastColor} stopOpacity={0.28} />
                  <stop offset="100%" stopColor={lastColor} stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid stroke="var(--border)" strokeDasharray="4 4" vertical={false} />
              <XAxis
                dataKey="logged_at"
                tickFormatter={(v: string) => formatTick(v, range)}
                tick={{ fill: 'var(--muted)', fontSize: 12 }}
                tickLine={false}
                axisLine={{ stroke: 'var(--border)' }}
                interval="preserveStartEnd"
                minTickGap={24}
                padding={{ left: 8, right: 8 }}
              />
              <YAxis
                domain={[1, 10]}
                ticks={[1, 5, 10]}
                tick={{ fill: 'var(--muted)', fontSize: 12 }}
                tickLine={false}
                axisLine={false}
                width={32}
              />
              <Tooltip content={<ChartTooltip />} cursor={{ stroke: 'var(--border)' }} />
              <Area
                type="monotone"
                dataKey="mood_score"
                stroke="url(#moodStroke)"
                strokeWidth={3}
                strokeLinecap="round"
                fill="url(#moodFill)"
                dot={<MoodDot />}
                activeDot={{ r: 6 }}
                connectNulls
                isAnimationActive
                animationDuration={850}
              />
            </AreaChart>
          </ResponsiveContainer>
        </div>
      )}
    </div>
  )
}
