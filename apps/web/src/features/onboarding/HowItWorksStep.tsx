import { useEffect, useState, type CSSProperties } from 'react'
import { moodColor } from '../../lib/moodColor'
import { NotebookIcon } from '../../components/NotebookIcon'
import type { PersonalizationOption } from './PersonalizationStep'

const FRAMES = [
  { emoji: '🎚️', title: 'Slide to how you feel', subtitle: 'A quick 1 to 10 check-in.' },
  { emoji: '🏷️', title: 'Pick a word', subtitle: 'Anxious, calm, proud, whatever fits.' },
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
  const icons = ['slider', 'tag', 'bulb'] as const
  return (
    <div className="flex min-h-0 flex-col">
      <div className="min-h-0 flex-1 overflow-y-auto pb-8">
        <h1 className="text-4xl text-ink sm:text-5xl">Small steps.<br /><span className="hl" style={{ '--mark': moodColor(9) } as CSSProperties}>Every day.</span></h1>
        <p className="mt-4 text-lg leading-relaxed text-muted">{intro}</p>
        <p className="label mt-8">How it works</p>
        <div className="card mt-2.5 p-5" aria-live="polite">
          <div key={frame}>
            <div className="flex items-center justify-between text-blue-dark">
              <span className="flex h-8 w-8 items-center justify-center rounded-lg bg-blue-dark font-bold text-on-accent">{frame + 1}</span>
              <NotebookIcon name={icons[frame]} />
            </div>
            <h2 className="mt-6 text-2xl text-ink">{current.title}</h2>
            <p className="mt-2 text-muted">{current.subtitle}</p>
          </div>
        </div>
        <div className="mt-4 flex gap-1.5" aria-hidden>
          {FRAMES.map((_, i) => <span key={i} className={`h-1.5 w-1.5 rounded-[2px] ${i === frame ? 'bg-ink' : 'bg-border'}`} />)}
        </div>
      </div>
      <button type="button" onClick={onNext} className="w-full rounded-[10px] bg-blue-dark px-6 py-3.5 font-display font-extrabold text-on-accent hover:opacity-90">Next</button>
    </div>
  )
}
