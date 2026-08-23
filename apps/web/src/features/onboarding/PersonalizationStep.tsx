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
  return (
    <div className="flex flex-col items-center justify-center px-8 text-center">
      <h1 className="font-display text-2xl font-bold text-ink">What brings you here?</h1>
      <p className="mt-1 text-sm text-muted">
        Totally optional — just helps us tailor a few things.
      </p>
      <div className="mt-6 flex flex-wrap justify-center gap-2">
        {PERSONALIZATION_OPTIONS.map((o) => {
          const isSelected = selected === o.value
          return (
            <button
              key={o.value}
              type="button"
              onClick={() => onSelect(isSelected ? null : o.value)}
              className={[
                'flex items-center gap-1.5 rounded-full border px-3 py-1.5 text-sm font-medium transition-colors',
                isSelected
                  ? 'border-blue-dark bg-blue-tint text-blue-dark'
                  : 'border-border bg-field text-ink hover:bg-blue-tint',
              ].join(' ')}
            >
              <span>{o.emoji}</span>
              <span>{o.label}</span>
            </button>
          )
        })}
      </div>
      <button
        type="button"
        onClick={onNext}
        className="mt-12 w-full max-w-xs rounded-full bg-blue-dark px-6 py-3 font-medium text-on-accent transition-opacity hover:opacity-90"
      >
        Next
      </button>
    </div>
  )
}
