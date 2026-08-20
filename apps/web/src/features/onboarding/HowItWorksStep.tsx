import { useEffect, useState } from 'react'
import type { PersonalizationOption } from './PersonalizationStep'

const FRAMES = [
  { emoji: '🎚️', title: 'Slide to how you feel', subtitle: 'A quick 1–10 check-in.' },
  { emoji: '🏷️', title: 'Pick a word', subtitle: 'Anxious, calm, proud — whatever fits.' },
  {
    emoji: '💡',
    title: 'Get an AI coping technique',
    subtitle: 'A personalized CBT tool, every time.',
  },
]

const INTRO_COPY: Record<PersonalizationOption, string> = {
  track: "Here's how tracking your mood works:",
  stress: "Here's how we help you manage stress:",
  habits: "Here's how the daily habit works:",
  curious: "Here's a quick look at how it works:",
}

interface Props {
  personalization: PersonalizationOption | null
  onNext: () => void
}

/**
 * Onboarding screen 4 — a short looped explainer (not commissioned
 * illustration, an explicit non-goal per the design doc) cycling through the
 * core loop: slider → word → AI suggestion.
 * docs/research/00-design-direction.md §6.4. Mirrors
 * apps/mobile/lib/features/onboarding/steps/how_it_works_step.dart.
 */
export function HowItWorksStep({ personalization, onNext }: Props) {
  const [frame, setFrame] = useState(0)

  useEffect(() => {
    const id = setInterval(() => setFrame((f) => (f + 1) % FRAMES.length), 2500)
    return () => clearInterval(id)
  }, [])

  const current = FRAMES[frame]
  const intro = personalization ? INTRO_COPY[personalization] : "Here's a quick look at how it works:"

  return (
    <div className="flex flex-col items-center justify-center px-8 text-center">
      <h1 className="font-display text-2xl font-bold text-ink">{intro}</h1>
      <div className="mt-10 flex h-40 flex-col items-center justify-center">
        <div
          key={frame}
          className="flex flex-col items-center"
          style={{
            animation: `fade-in var(--duration-medium) var(--ease-standard-decelerate)`,
          }}
        >
          <span className="text-5xl">{current.emoji}</span>
          <p className="mt-4 text-lg font-semibold text-ink">{current.title}</p>
          <p className="mt-1 text-sm text-muted">{current.subtitle}</p>
        </div>
      </div>
      <div className="mt-6 flex justify-center gap-1.5">
        {FRAMES.map((_, i) => (
          <span
            key={i}
            className="h-1.5 w-1.5 rounded-full transition-colors"
            style={{ backgroundColor: i === frame ? 'var(--blue-dark)' : 'var(--border)' }}
          />
        ))}
      </div>
      <button
        type="button"
        onClick={onNext}
        className="mt-10 w-full max-w-xs rounded-full bg-blue-dark px-6 py-3 font-medium text-on-accent transition-opacity hover:opacity-90"
      >
        Next
      </button>
      <style>{`
        @keyframes fade-in {
          from { opacity: 0; transform: translateY(4px); }
          to { opacity: 1; transform: translateY(0); }
        }
      `}</style>
    </div>
  )
}
