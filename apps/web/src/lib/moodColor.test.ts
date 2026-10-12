import { describe, expect, test } from 'vitest'
import { moodColor } from './moodColor'

describe('moodColor', () => {
  test('returns the exact stop color at each defined stop', () => {
    expect(moodColor(1)).toBe('#7c8ba8')
    expect(moodColor(3)).toBe('#96a9c1')
    expect(moodColor(5)).toBe('#c4bca9')
    expect(moodColor(7)).toBe('#dfb05e')
    expect(moodColor(10)).toBe('#DD955A')
  })

  test('interpolates linearly at the midpoint between two adjacent stops', () => {
    // Between stop 1 (#7C8BA8) and stop 3 (#96A9C1), score 2 is the midpoint.
    expect(moodColor(2)).toBe('#899ab5')
  })

  test('clamps to the lowest stop color below the defined range', () => {
    expect(moodColor(0)).toBe('#7C8BA8')
    expect(moodColor(-5)).toBe('#7C8BA8')
  })

  test('clamps to the highest stop color above the defined range', () => {
    expect(moodColor(11)).toBe('#DD955A')
    expect(moodColor(100)).toBe('#DD955A')
  })
})
