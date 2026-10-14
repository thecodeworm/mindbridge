import { useState, type CSSProperties } from 'react'
import type { MoodTag, MoodQuadrant } from '../../../../../shared/types'
import { moodColor, moodWord } from '../../lib/moodColor'
import { BreathingCircle } from '../../components/BreathingCircle'
import { FeltMoodSlider } from '../../components/FeltMoodSlider'
import { MoodTagPicker } from '../../components/MoodTagPicker'

// A small, honest sample bank keyed by quadrant — NOT a real Claude Haiku
// call. There's no session/user_id yet at this point in onboarding, so a
// live Edge Function call isn't possible without a pre-auth write; this
// preview is explicitly labeled as a sample rather than presented as real
// AI output. The user's actual first check-in happens for real, through the
// unmodified generate-suggestion pipeline, right after they sign up (see
// HomePage's onboarding nudge + MoodLogPage's initialScore/initialTag).
// Mirrors apps/mobile/lib/features/onboarding/steps/first_checkin_step.dart.
const SAMPLE_TECHNIQUES: Record<MoodQuadrant, { name: string; steps: string[] }> = {
  'high-pleasant': {
    name: 'Savoring the moment',
    steps: [
      'Pause and name one specific thing that felt good just now.',
      "Notice where you feel it in your body. That's the savoring.",
      'Write one sentence about it so future-you can look back on it.',
    ],
  },
  'high-unpleasant': {
    name: 'Box breathing',
    steps: [
      'Breathe in slowly for 4 counts.',
      'Hold for 4 counts, then breathe out for 4 counts.',
      'Hold empty for 4 counts. Repeat 4 times.',
    ],
  },
  'low-pleasant': {
    name: 'Progressive muscle relaxation',
    steps: [
      'Tense your shoulders for 5 seconds, then release.',
      'Move down through your arms, hands, and legs the same way.',
      'Notice the difference between tense and relaxed.',
    ],
  },
  'low-unpleasant': {
    name: 'Grounding: 5-4-3-2-1',
    steps: [
      'Name 5 things you can see, 4 you can touch, 3 you can hear.',
      'Name 2 things you can smell, 1 you can taste.',
      "Notice you're here, right now, safe.",
    ],
  },
}

interface Props {
  onCreateAccount: (score: number, tag: MoodTag) => void
  onHaveAccount: () => void
}

/**
 * Onboarding screen 5 — a real mood pick (local only, nothing written yet)
 * followed by a clearly-labeled sample suggestion, then account creation.
 * docs/research/00-design-direction.md §6.5.
 */
export function FirstCheckinStep({ onCreateAccount, onHaveAccount }: Props) {
  const [score, setScore] = useState(5)
  const [quadrant, setQuadrant] = useState<MoodQuadrant | null>(null)
  const [tag, setTag] = useState<MoodTag | null>(null)
  const [generating, setGenerating] = useState(false)
  const [showPreview, setShowPreview] = useState(false)

  const color = moodColor(score)

  function reveal() {
    setGenerating(true)
    setTimeout(() => {
      setGenerating(false)
      setShowPreview(true)
    }, 1100)
  }

  if (showPreview) {
    const sample = (quadrant && SAMPLE_TECHNIQUES[quadrant]) || SAMPLE_TECHNIQUES['low-pleasant']
    return (
      <div className="flex min-h-0 flex-col">
        <div className="min-h-0 flex-1 overflow-y-auto pb-8">
          <h1 className="text-3xl text-ink sm:text-4xl"><span className="hl" style={{ '--mark': color } as CSSProperties}>{sample.name}</span></h1>
          <p className="mt-4 leading-relaxed text-muted">A sample of what you get after every real check-in: one technique, three small steps.</p>
          <ol className="card mt-5 space-y-5 p-5">
            {sample.steps.map((s, i) => <li key={i} className="flex items-start gap-3"><span className="flex h-7 w-7 shrink-0 items-center justify-center rounded-lg bg-blue-dark font-bold text-on-accent">{i + 1}</span><span className="leading-relaxed text-ink">{s}</span></li>)}
          </ol>
        </div>
        <button type="button" onClick={() => tag && onCreateAccount(score, tag)} className="w-full rounded-[10px] bg-blue-dark px-6 py-3.5 font-display font-extrabold text-on-accent hover:opacity-90">Save this and create my account</button>
        <button type="button" onClick={onHaveAccount} className="mt-2 w-full rounded-[10px] px-6 py-3 text-sm font-semibold text-blue-dark hover:underline">I already have an account</button>
      </div>
    )
  }

  return (
    <div className="flex min-h-0 flex-col">
      <div className="min-h-0 flex-1 overflow-y-auto pb-8">
        <h1 className="text-3xl text-ink sm:text-4xl">Let's try it. How are you feeling right now?</h1>
        <div className="mt-7 flex items-baseline gap-3">
          <span className="tabular font-display text-4xl font-black text-ink">{Math.round(score)}</span>
          <span className="hl font-display text-2xl font-black" style={{ '--mark': color } as CSSProperties}>{moodWord(score)}</span>
        </div>
        <FeltMoodSlider value={score} onChange={setScore} />
        <div className="mt-4"><MoodTagPicker quadrant={quadrant} tag={tag} onQuadrantChange={setQuadrant} onTagChange={setTag} /></div>
      </div>
      {generating ? <div className="flex h-20 items-center justify-center" role="status" aria-label="Preparing your sample"><BreathingCircle color={color} size={72} /></div> : <button type="button" disabled={!tag} onClick={reveal} className="w-full rounded-[10px] bg-blue-dark px-6 py-3.5 font-display font-extrabold text-on-accent hover:opacity-90 disabled:opacity-50">See what you'd get</button>}
    </div>
  )
}
