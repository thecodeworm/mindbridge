import type { MoodLog } from '../../../../shared/types'
import { computePracticeWindow, computeStreaks } from '../lib/streaks'

/**
 * Non-punitive practice line: "practiced X of the last 10 days" plus a
 * personal best, never a streak that snaps to zero. Mirrors
 * apps/mobile/lib/features/dashboard/streak_badge.dart.
 */
export function StreakBadge({ logs }: { logs: MoodLog[] }) {
  const { longest } = computeStreaks(logs)
  const { practiced, windowDays } = computePracticeWindow(logs)

  if (longest === 0) return null

  return (
    <div className="flex items-center gap-3">
      <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-success-tint text-success" aria-hidden>
        <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
          <path d="M12 22c4-2 7-5.5 7-10a7 7 0 0 0-7 3 7 7 0 0 0-7-3c0 4.5 3 8 7 10Z" />
          <path d="M12 15V5" />
        </svg>
      </span>
      <div>
        <p className="tabular font-semibold text-ink">
          You've practiced {practiced} of {windowDays} days
        </p>
        <p className="tabular text-sm text-muted">
          Personal best: {longest} day{longest === 1 ? '' : 's'}
        </p>
      </div>
    </div>
  )
}
