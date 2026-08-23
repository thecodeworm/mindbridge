import type { MoodTag } from '../../../../shared/types'

// Tracks whether the user has completed (or skipped) onboarding, persisted
// to localStorage — mirrors apps/mobile/lib/core/onboarding_state.dart's
// FlutterSecureStorage-backed pattern. OnboardingFlow marks this true on
// exit; nothing currently reads it to gate routing (that was the deleted
// OnboardingGate's job — onboarding is now opt-in via LandingPage's
// "Get started" link at /onboarding instead of an automatic redirect).
const STORAGE_KEY = 'mindbridge.onboarding_completed'

export function isOnboardingCompleted(): boolean {
  return localStorage.getItem(STORAGE_KEY) === 'true'
}

export function setOnboardingCompleted(value: boolean) {
  if (value) {
    localStorage.setItem(STORAGE_KEY, 'true')
  } else {
    localStorage.removeItem(STORAGE_KEY)
  }
}

// The mood the user picked during onboarding's first-check-in step, carried
// in memory only (not persisted — same tab session only, mirrors the Dart
// static fields' in-memory-only behavior) so HomePage can offer to save it
// as a real check-in right after sign-up. Cleared by clearPendingCheckin()
// once offered.
let pendingScore: number | null = null
let pendingTag: MoodTag | null = null

export function stashPendingCheckin(score: number, tag: MoodTag) {
  pendingScore = score
  pendingTag = tag
}

export function getPendingCheckin(): { score: number; tag: MoodTag } | null {
  if (pendingScore === null || pendingTag === null) return null
  return { score: pendingScore, tag: pendingTag }
}

export function clearPendingCheckin() {
  pendingScore = null
  pendingTag = null
}
