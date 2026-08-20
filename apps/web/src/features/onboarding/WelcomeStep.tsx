import { moodColor } from '../../lib/moodColor'
import { BreathingCircle } from '../../components/BreathingCircle'

/**
 * Onboarding screen 1 — wordmark over the breathing mood-ramp, one-line
 * value prop, single CTA. docs/research/00-design-direction.md §6.1.
 * Mirrors apps/mobile/lib/features/onboarding/steps/welcome_step.dart.
 */
export function WelcomeStep({ onNext }: { onNext: () => void }) {
  return (
    <div className="flex flex-col items-center justify-center px-8 text-center">
      <div className="relative flex items-center justify-center">
        <BreathingCircle
          colors={[moodColor(1), moodColor(5.5), moodColor(10)]}
          size={220}
          cycleSeconds={5}
        />
        <h1 className="absolute font-display text-3xl font-bold text-blue-dark">
          MindBridge
        </h1>
      </div>
      <p className="mt-8 text-lg text-muted">
        A private space to check in with yourself, every day.
      </p>
      <button
        type="button"
        onClick={onNext}
        className="mt-12 w-full max-w-xs rounded-full bg-blue-dark px-6 py-3 font-medium text-on-accent transition-opacity hover:opacity-90"
      >
        Get started
      </button>
    </div>
  )
}
