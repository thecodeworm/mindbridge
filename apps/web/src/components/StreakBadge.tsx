import type { MoodLog } from '../../../../shared/types'
import { computeStreaks } from '../lib/streaks'

export function StreakBadge({ logs }: { logs: MoodLog[] }) {
  const { current, longest } = computeStreaks(logs)

  if (current === 0 && longest === 0) return null

  return (
    <div className="flex gap-4 rounded-xl border border-border bg-surface px-5 py-4 shadow-sm">
      <div className="text-center">
        <p className="text-2xl font-bold text-success">{current}</p>
        <p className="text-xs text-muted">day streak</p>
      </div>
      <div className="w-px bg-border" />
      <div className="text-center">
        <p className="text-2xl font-bold text-ink">{longest}</p>
        <p className="text-xs text-muted">longest</p>
      </div>
      {current > 0 && (
        <>
          <div className="w-px bg-border" />
          <div className="flex items-center">
            <p className="text-sm text-muted">
              {current === 1 ? 'Great start — come back tomorrow!' : `${current} days in a row 🎉`}
            </p>
          </div>
        </>
      )}
    </div>
  )
}
