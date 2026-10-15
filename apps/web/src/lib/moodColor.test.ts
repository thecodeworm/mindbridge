import { describe, expect, test } from 'vitest'
import { moodColor } from './moodColor'

describe('moodColor', () => {
  test('returns the exact stop color at each defined stop', () => {
    expect(moodColor(1)).toBe('#B9B3F2')
    expect(moodColor(3)).toBe('#9ED3F5')
    expect(moodColor(5)).toBe('#F2E58A')
    expect(moodColor(7)).toBe('#FFC07A')
    expect(moodColor(9)).toBe('#FF9FCB')
    expect(moodColor(10)).toBe('#FF9FCB')
  })

  test('uses solid bands of two scores, never a blend', () => {
    expect(moodColor(2)).toBe('#B9B3F2')
    expect(moodColor(4)).toBe('#9ED3F5')
    expect(moodColor(6)).toBe('#F2E58A')
    expect(moodColor(8)).toBe('#FFC07A')
  })

  test('clamps to the lowest stop color below the defined range', () => {
    expect(moodColor(0)).toBe('#B9B3F2')
    expect(moodColor(-5)).toBe('#B9B3F2')
  })

  test('clamps to the highest stop color above the defined range', () => {
    expect(moodColor(11)).toBe('#FF9FCB')
    expect(moodColor(100)).toBe('#FF9FCB')
  })
})
