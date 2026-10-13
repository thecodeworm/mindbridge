import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import type { MoodTag } from '../../../../../shared/types'
import { setOnboardingCompleted, stashPendingCheckin } from '../../core/onboardingState'
import { WelcomeStep } from './WelcomeStep'
import { TrustStep } from './TrustStep'
import { PersonalizationStep, type PersonalizationOption } from './PersonalizationStep'
import { HowItWorksStep } from './HowItWorksStep'
import { FirstCheckinStep } from './FirstCheckinStep'

const STEP_COUNT = 5

/**
 * Five-screen onboarding flow, shown once per browser ahead of the routed
 * app. docs/research/00-design-direction.md §6 — dots not a percentage bar,
 * skippable from screen 3 onward (never before the privacy screen). Mirrors
 * apps/mobile/lib/features/onboarding/onboarding_flow.dart.
 *
 * Deviation from the Flutter version, made as a judgment call: Flutter's
 * exit CTAs both fall through to AuthGate's default (sign-in) screen, so
 * "Save this and create my account" actually lands on sign-in there (one
 * extra tap to reach sign-up). On web, routing directly to the page the
 * button names is just as easy to get right, so `onCreateAccount` routes to
 * /signup and `onHaveAccount`/Skip route to /login.
 */
export function OnboardingFlow() {
  const navigate = useNavigate()
  const [page, setPage] = useState(0)
  const [personalization, setPersonalization] = useState<PersonalizationOption | null>(null)

  function finish(target: '/signup' | '/login', checkin?: { score: number; tag: MoodTag }) {
    if (checkin) stashPendingCheckin(checkin.score, checkin.tag)
    setOnboardingCompleted(true)
    navigate(target, { replace: true })
  }

  const steps = [
    <WelcomeStep key="welcome" onNext={() => setPage(1)} />,
    <TrustStep key="trust" onNext={() => setPage(2)} />,
    <PersonalizationStep
      key="personalization"
      selected={personalization}
      onSelect={setPersonalization}
      onNext={() => setPage(3)}
    />,
    <HowItWorksStep key="how-it-works" personalization={personalization} onNext={() => setPage(4)} />,
    <FirstCheckinStep
      key="first-checkin"
      onCreateAccount={(score, tag) => finish('/signup', { score, tag })}
      onHaveAccount={() => finish('/login')}
    />,
  ]

  return (
    <div className="relative flex min-h-screen flex-col items-center justify-center bg-cream py-16">
      {page >= 2 && (
        <button
          type="button"
          onClick={() => finish('/login')}
          className="absolute right-4 top-4 rounded-[10px] px-3 py-1.5 text-sm font-medium text-muted transition-colors hover:text-ink"
        >
          Skip
        </button>
      )}

      <div key={page} className="animate-step-enter w-full">
        {steps[page]}
      </div>

      <div className="absolute bottom-4 flex justify-center gap-1.5">
        {Array.from({ length: STEP_COUNT }).map((_, i) => (
          <span
            key={i}
            className="rounded-full transition-all"
            style={{
              width: i === page ? 20 : 6,
              height: 6,
              backgroundColor: i === page ? 'var(--blue-dark)' : 'var(--border)',
            }}
          />
        ))}
      </div>
    </div>
  )
}
