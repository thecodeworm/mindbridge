import { useState } from 'react'

export interface Distortion {
  id: string
  name: string
  description: string
}

// Canonical IDs are snake_case and identical to apps/mobile/lib/features/
// mood/distortion_picker.dart (and allowed by migration 0012's
// is_valid_distortions check), so both platforms write the same values.
const DISTORTIONS: Distortion[] = [
  { id: 'all_or_nothing', name: 'All-or-nothing thinking', description: 'Seeing things in black and white, with no middle ground.' },
  { id: 'catastrophizing', name: 'Catastrophizing', description: 'Assuming the worst possible outcome will happen.' },
  { id: 'mind_reading', name: 'Mind reading', description: 'Believing you know what others are thinking, usually negatively.' },
  { id: 'overgeneralization', name: 'Overgeneralization', description: 'Treating one bad moment as a pattern that will always repeat.' },
  { id: 'emotional_reasoning', name: 'Emotional reasoning', description: 'Believing something is true because it feels true.' },
  { id: 'should_statements', name: '"Should" statements', description: 'Holding yourself to rigid rules about how things should be.' },
]

interface Props {
  onDone: (selected: string[], reframe: string) => void
  onSkip: () => void
}

export function DistortionPicker({ onDone, onSkip }: Props) {
  const [selected, setSelected] = useState<string[]>([])
  const [reframe, setReframe] = useState('')
  const [step, setStep] = useState<'pick' | 'reframe'>('pick')

  function toggle(id: string) {
    setSelected((prev) => prev.includes(id) ? prev.filter((s) => s !== id) : [...prev, id])
  }

  if (step === 'reframe') {
    return (
      <div className="space-y-3 py-4">
        <h3 className="label">Challenge the thought</h3>
        <p className="text-sm text-muted">What would you tell a friend who said that?</p>
        <textarea
          value={reframe}
          onChange={(e) => setReframe(e.target.value)}
          rows={3}
          placeholder="A more balanced way to see it..."
          className="w-full resize-none rounded-[10px] border border-border bg-field px-3 py-2 text-sm text-ink placeholder:text-faint"
        />
        <div className="flex gap-2">
          <button
            type="button"
            onClick={() => setStep('pick')}
            className="flex-1 rounded-[10px] border border-border bg-field px-3 py-2 text-sm font-medium text-ink transition-colors hover:bg-blue-tint"
          >
            ← Back
          </button>
          <button
            type="button"
            onClick={() => onDone(selected, reframe)}
            className="flex-1 rounded-[10px] bg-blue-dark px-3 py-2 text-sm font-medium text-on-accent transition-opacity hover:opacity-90"
          >
            Save
          </button>
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-3 py-4">
      <div className="flex items-start justify-between gap-2">
        <div>
          <h3 className="label">Notice any thinking traps?</h3>
          <p className="text-xs text-muted">Optional, totally skippable</p>
        </div>
        <button
          type="button"
          onClick={onSkip}
          className="shrink-0 text-sm text-muted transition-colors hover:text-ink"
        >
          Skip
        </button>
      </div>

      <div className="space-y-2">
        {DISTORTIONS.map((d) => {
          const isSelected = selected.includes(d.id)
          return (
            <button
              key={d.id}
              type="button"
              aria-pressed={isSelected}
              onClick={() => toggle(d.id)}
              className={[
                'flex w-full items-start gap-3 rounded-lg border-[1.5px] px-3 py-2.5 text-left transition-colors',
                isSelected
                  ? 'border-blue-dark bg-blue-dark text-on-accent'
                  : 'border-border bg-field hover:bg-blue-tint',
              ].join(' ')}
            >
              <span className={`mt-0.5 h-4 w-4 shrink-0 rounded border-2 ${isSelected ? 'border-on-accent bg-on-accent' : 'border-border'}`} />
              <div>
                <p className={`text-sm font-medium ${isSelected ? 'text-on-accent' : 'text-ink'}`}>{d.name}</p>
                <p className={`text-xs ${isSelected ? 'text-on-accent' : 'text-muted'}`}>{d.description}</p>
              </div>
            </button>
          )
        })}
      </div>

      {selected.length > 0 && (
        <button
          type="button"
          onClick={() => setStep('reframe')}
          className="w-full rounded-[10px] bg-blue-dark px-3 py-2 text-sm font-medium text-on-accent transition-opacity hover:opacity-90"
        >
          Reframe → ({selected.length} selected)
        </button>
      )}
    </div>
  )
}
