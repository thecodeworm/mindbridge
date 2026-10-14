import type { CSSProperties } from 'react'
import { moodColor } from '../../lib/moodColor'
import { NotebookIcon } from '../../components/NotebookIcon'

export type PersonalizationOption = 'track' | 'stress' | 'habits' | 'curious'

export const PERSONALIZATION_OPTIONS: { value: PersonalizationOption; emoji: string; label: string }[] = [
  { value: 'track', emoji: '📈', label: 'Track my mood' },
  { value: 'stress', emoji: '🌊', label: 'Manage stress & anxiety' },
  { value: 'habits', emoji: '🌱', label: 'Build better habits' },
  { value: 'curious', emoji: '👋', label: 'Just exploring' },
]

interface Props {
  selected: PersonalizationOption | null
  onSelect: (v: PersonalizationOption | null) => void
  onNext: () => void
}

/**
 * Onboarding screen 3 — one tap-only question, chips not text input.
 * Tailors copy on the next screen only; never gates progress (the CTA is
 * always enabled). docs/research/00-design-direction.md §6.3. Mirrors
 * apps/mobile/lib/features/onboarding/steps/personalization_step.dart.
 */
export function PersonalizationStep({ selected, onSelect, onNext }: Props) {
  const icons = ['chart', 'waves', 'sprout', 'explore'] as const
  return (
    <div className="flex min-h-0 flex-col">
      <div className="min-h-0 flex-1 overflow-y-auto pb-8">
        <h1 className="text-4xl text-ink sm:text-5xl">What brings<br /><span className="hl" style={{ '--mark': moodColor(7) } as CSSProperties}>you here?</span></h1>
        <p className="mt-4 text-lg leading-relaxed text-muted">Totally optional. It just helps us tailor a few things.</p>
        <p className="label mt-8">Pick what fits</p>
        <div className="mt-2.5 space-y-2.5">
          {PERSONALIZATION_OPTIONS.map((o, i) => {
            const isSelected = selected === o.value
            return (
              <button key={o.value} type="button" aria-pressed={isSelected} onClick={() => onSelect(isSelected ? null : o.value)} className={`flex w-full items-center gap-3 rounded-lg border-[1.5px] px-4 py-3.5 text-left font-semibold transition-colors ${isSelected ? 'border-ink bg-ink text-cream' : 'border-border bg-field text-ink hover:bg-surface'}`}>
                <NotebookIcon name={icons[i]} />
                {o.label}
              </button>
            )
          })}
        </div>
      </div>
      <button type="button" onClick={onNext} className="w-full rounded-[10px] bg-blue-dark px-6 py-3.5 font-display font-extrabold text-on-accent hover:opacity-90">Next</button>
    </div>
  )
}
