import { CrisisChip } from '../../components/CrisisChip'
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
    <div className="flex h-dvh flex-col overflow-hidden bg-cream px-6 pb-4 pt-5">
      <header className="mx-auto flex w-full max-w-md items-center gap-2">
        <span className="flex-1 font-display text-xl font-black tracking-tight text-ink">MindBridge</span>
        {page >= 2 && <button type="button" onClick={() => finish('/login')} className="rounded-[10px] px-3 py-2 font-semibold text-muted hover:text-ink">Skip</button>}
        <CrisisChip inline />
      </header>
      <main key={page} className="animate-step-enter mx-auto grid w-full max-w-md min-h-0 flex-1 pt-10">
        {steps[page]}
      </main>
      <div className="mt-5 flex justify-center gap-1.5" aria-label={`Step ${page + 1} of ${STEP_COUNT}`}>
        {Array.from({ length: STEP_COUNT }).map((_, i) => <span key={i} className={`h-1.5 w-1.5 rounded-[2px] ${i === page ? 'bg-ink' : 'bg-border'}`} />)}
      </div>
    </div>
  )
}
