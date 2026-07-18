import { useMemo, useState } from 'react'
import {
  CartesianGrid,
  Dot,
  Line,
  LineChart,
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
    <div className="rounded-lg border border-border bg-surface px-3 py-2 text-sm shadow-sm">
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
  return <Dot cx={cx} cy={cy} r={4} fill={moodColor(payload.mood_score)} stroke="var(--surface)" strokeWidth={1} />
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

  return (
    <div className="rounded-xl border border-border bg-surface p-4 shadow-sm sm:p-6">
      <div className="mb-4 flex items-center justify-between">
        <h2 className="text-lg font-bold text-ink">Mood trend</h2>
        <div className="flex gap-1 rounded-lg border border-border bg-field p-1">
          {([7, 30] as const).map((d) => (
            <button
              key={d}
              type="button"
              onClick={() => setRange(d)}
              className={[
                'rounded-md px-3 py-1 text-sm font-medium transition-colors',
                range === d ? 'bg-blue-dark text-on-accent' : 'text-muted hover:text-ink',
              ].join(' ')}
              aria-pressed={range === d}
            >
              {d}d
            </button>
          ))}
        </div>
      </div>

      {data.length === 0 ? (
        <p className="py-12 text-center text-sm text-muted">
          No entries in this range yet — log a mood to start your trend.
        </p>
      ) : (
        <div className="h-56 w-full sm:h-64">
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={data} margin={{ top: 8, right: 8, left: -16, bottom: 0 }}>
              <CartesianGrid stroke="var(--border)" strokeDasharray="3 3" vertical={false} />
              <XAxis
                dataKey="logged_at"
                tickFormatter={(v: string) => formatTick(v, range)}
                stroke="var(--faint)"
                tick={{ fill: 'var(--muted)', fontSize: 12 }}
                tickLine={false}
                axisLine={{ stroke: 'var(--border)' }}
                interval="preserveStartEnd"
                minTickGap={24}
              />
              <YAxis
                domain={[1, 10]}
                ticks={[1, 3, 5, 7, 10]}
                stroke="var(--faint)"
                tick={{ fill: 'var(--muted)', fontSize: 12 }}
                tickLine={false}
                axisLine={false}
                width={28}
              />
              <Tooltip content={<ChartTooltip />} cursor={{ stroke: 'var(--border)' }} />
              <Line
                type="monotone"
                dataKey="mood_score"
                stroke="var(--blue-dark)"
                strokeWidth={2}
                dot={<MoodDot />}
                activeDot={{ r: 6 }}
                connectNulls
                isAnimationActive={false}
              />
            </LineChart>
          </ResponsiveContainer>
        </div>
      )}
    </div>
  )
}
