// Pure streak computation — testable without UI.
// Streak definition: consecutive calendar days (user's local timezone) with ≥1 log.

export interface StreakResult {
  current: number
  longest: number
}

function toLocalDateStr(iso: string): string {
  const d = new Date(iso)
  // Format as YYYY-MM-DD in local timezone
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${y}-${m}-${day}`
}

export function computeStreaks(logs: { logged_at: string }[]): StreakResult {
  if (logs.length === 0) return { current: 0, longest: 0 }

  // Unique days, sorted ascending
  const days = [...new Set(logs.map((l) => toLocalDateStr(l.logged_at)))].sort()

  let longest = 1
  let run = 1
  for (let i = 1; i < days.length; i++) {
    const prev = new Date(days[i - 1])
    const curr = new Date(days[i])
    const diffMs = curr.getTime() - prev.getTime()
    const diffDays = Math.round(diffMs / (1000 * 60 * 60 * 24))
    if (diffDays === 1) {
      run++
      if (run > longest) longest = run
    } else {
      run = 1
    }
  }

  // Current streak: work backward from today
  const todayStr = toLocalDateStr(new Date().toISOString())
  const todayDate = new Date(todayStr)

  const latestStr = days[days.length - 1]
  const latestDate = new Date(latestStr)
  const diffToToday = Math.round((todayDate.getTime() - latestDate.getTime()) / (1000 * 60 * 60 * 24))

  // If last entry was today or yesterday, count backward
  let current = 0
  if (diffToToday <= 1) {
    current = 1
    for (let i = days.length - 2; i >= 0; i--) {
      const a = new Date(days[i])
      const b = new Date(days[i + 1])
      const diff = Math.round((b.getTime() - a.getTime()) / (1000 * 60 * 60 * 24))
      if (diff === 1) {
        current++
      } else {
        break
      }
    }
  }

  return { current, longest: Math.max(longest, current) }
}

export interface PracticeWindow {
  practiced: number
  windowDays: number
}

/**
 * Non-punitive practice metric: how many of the last `windowDays` calendar
 * days had a log, with no reset-to-zero on a missed day. Mirrors
 * apps/mobile/lib/core/streaks.dart's computePracticeWindow.
 */
export function computePracticeWindow(
  logs: { logged_at: string }[],
  windowDays = 10,
): PracticeWindow {
  const logged = new Set(logs.map((l) => toLocalDateStr(l.logged_at)))
  let practiced = 0
  for (let i = 0; i < windowDays; i++) {
    const d = new Date()
    d.setDate(d.getDate() - i)
    if (logged.has(toLocalDateStr(d.toISOString()))) practiced++
  }
  return { practiced, windowDays }
}
