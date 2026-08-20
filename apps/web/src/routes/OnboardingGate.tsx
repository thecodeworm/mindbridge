import { useEffect, useState, type ReactNode } from 'react'
import { useAuth } from '../context/AuthContext'
import { OnboardingFlow } from '../features/onboarding/OnboardingFlow'
import { isOnboardingCompleted, setOnboardingCompleted } from '../core/onboardingState'

/**
 * Shows the five-step onboarding flow once (per browser), ahead of every
 * other route — mirrors app.dart's `_OnboardingGate` sitting above
 * `AuthGate`. An existing logged-in user (e.g. clearing localStorage never
 * happened, or this browser already has a session) is marked complete
 * immediately and never sees onboarding, mirroring main.dart's
 * `OnboardingState.load()` + immediate-complete-if-session-exists behavior.
 */
export function OnboardingGate({ children }: { children: ReactNode }) {
  const { session, loading } = useAuth()
  const [completed, setCompleted] = useState(() => isOnboardingCompleted())

  useEffect(() => {
    if (loading || completed) return
    if (session) {
      setOnboardingCompleted(true)
      setCompleted(true)
    }
  }, [loading, session, completed])

  if (loading) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-cream">
        <p className="text-muted">Loading…</p>
      </div>
    )
  }

  if (!completed) return <OnboardingFlow />

  return <>{children}</>
}
