import { describe, expect, test } from 'vitest'
import { computeStreaks } from './streaks'

// Fixtures are built relative to `new Date()`, not hardcoded calendar dates,
// so the suite isn't flaky across days — mirrors
// apps/mobile/test/core/streaks_test.dart's `_logDaysAgo` helper.
function logDaysAgo(daysAgo: number, hour = 12): { logged_at: string } {
  const now = new Date()
  const day = new Date(now.getFullYear(), now.getMonth(), now.getDate() - daysAgo, hour)
  return { logged_at: day.toISOString() }
}

describe('computeStreaks', () => {
  test('empty logs -> current 0, longest 0', () => {
    expect(computeStreaks([])).toEqual({ current: 0, longest: 0 })
  })

  test('single log today -> current 1, longest 1', () => {
    expect(computeStreaks([logDaysAgo(0)])).toEqual({ current: 1, longest: 1 })
  })

  test('two consecutive days (today + yesterday) -> current 2, longest 2', () => {
    expect(computeStreaks([logDaysAgo(0), logDaysAgo(1)])).toEqual({ current: 2, longest: 2 })
  })

  test('multiple logs on the same day collapse to one day', () => {
    const result = computeStreaks([logDaysAgo(0, 8), logDaysAgo(0, 20), logDaysAgo(1, 9)])
    expect(result).toEqual({ current: 2, longest: 2 })
  })

  test('most recent log yesterday still counts as an active current streak', () => {
    expect(computeStreaks([logDaysAgo(1), logDaysAgo(2)])).toEqual({ current: 2, longest: 2 })
  })

  test('most recent log 2+ days ago resets current streak to 0 but keeps longest', () => {
    expect(computeStreaks([logDaysAgo(2)])).toEqual({ current: 0, longest: 1 })
  })

  test('a gap before today breaks the current streak but not the longest', () => {
    expect(computeStreaks([logDaysAgo(0), logDaysAgo(3)])).toEqual({ current: 1, longest: 1 })
  })

  test('longest run can exceed the current run', () => {
    const result = computeStreaks([
      logDaysAgo(5),
      logDaysAgo(4),
      logDaysAgo(3),
      logDaysAgo(1),
      logDaysAgo(0),
    ])
    expect(result).toEqual({ current: 2, longest: 3 })
  })

  test('current streak overtaking the prior longest updates longest too', () => {
    const result = computeStreaks([logDaysAgo(0), logDaysAgo(1), logDaysAgo(2), logDaysAgo(3)])
    expect(result).toEqual({ current: 4, longest: 4 })
  })
})
