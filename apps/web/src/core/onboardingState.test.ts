import { beforeEach, describe, expect, test } from 'vitest'
import {
  clearPendingCheckin,
  getPendingCheckin,
  isOnboardingCompleted,
  setOnboardingCompleted,
  stashPendingCheckin,
} from './onboardingState'

beforeEach(() => {
  localStorage.clear()
  clearPendingCheckin()
})

describe('isOnboardingCompleted / setOnboardingCompleted', () => {
  test('defaults to not completed', () => {
    expect(isOnboardingCompleted()).toBe(false)
  })

  test('setOnboardingCompleted(true) persists across reads', () => {
    setOnboardingCompleted(true)
    expect(isOnboardingCompleted()).toBe(true)
  })

  test('setOnboardingCompleted(false) clears the persisted flag', () => {
    setOnboardingCompleted(true)
    setOnboardingCompleted(false)
    expect(isOnboardingCompleted()).toBe(false)
  })
})

describe('pending checkin (in-memory only)', () => {
  test('getPendingCheckin returns null when nothing was stashed', () => {
    expect(getPendingCheckin()).toBeNull()
  })

  test('stashPendingCheckin round-trips through getPendingCheckin', () => {
    stashPendingCheckin(7, 'calm')
    expect(getPendingCheckin()).toEqual({ score: 7, tag: 'calm' })
  })

  test('clearPendingCheckin removes the stashed value', () => {
    stashPendingCheckin(7, 'calm')
    clearPendingCheckin()
    expect(getPendingCheckin()).toBeNull()
  })
})
