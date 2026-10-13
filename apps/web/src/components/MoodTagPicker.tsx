import { MOOD_TAGS, MOOD_QUADRANTS } from '../../../../shared/types'
import type { MoodTag, MoodQuadrant } from '../../../../shared/types'

interface Props {
  quadrant: MoodQuadrant | null
  tag: MoodTag | null
  onQuadrantChange: (q: MoodQuadrant | null) => void
  onTagChange: (t: MoodTag | null) => void
}

const chipClass = (selected: boolean) =>
  [
    'flex items-center gap-1.5 rounded-lg border px-3 py-1.5 text-sm font-medium transition-colors',
    selected
      ? 'border-blue-dark bg-blue-tint text-blue-dark'
      : 'border-border bg-field text-ink hover:bg-blue-tint',
  ].join(' ')

/**
 * Two-step quadrant → word mood-tag picker. Extracted as its own component
 * (mirroring apps/mobile/lib/widgets/mood_tag_picker.dart's extraction from
 * mood_log_screen.dart) so both MoodLogPage and the onboarding first-check-in
 * step reuse the exact same interaction without duplicating it.
 */
export function MoodTagPicker({ quadrant, tag, onQuadrantChange, onTagChange }: Props) {
  const tagsForQuadrant = quadrant ? MOOD_TAGS.filter((t) => t.quadrant === quadrant) : []

  if (quadrant === null) {
    return (
      <div className="grid grid-cols-2 gap-2">
        {MOOD_QUADRANTS.map((q) => (
          <button
            key={q.value}
            type="button"
            onClick={() => onQuadrantChange(q.value)}
            className="flex flex-col items-start gap-1 rounded-xl border border-border bg-field p-3 text-left transition-colors hover:bg-blue-tint"
          >
            <span className="text-lg">{q.emoji}</span>
            <span className="text-xs font-medium text-ink">{q.label}</span>
          </button>
        ))}
      </div>
    )
  }

  return (
    <div className="space-y-2">
      <button
        type="button"
        onClick={() => {
          onQuadrantChange(null)
          onTagChange(null)
        }}
        className="text-xs text-muted transition-colors hover:text-ink"
      >
        ← {MOOD_QUADRANTS.find((q) => q.value === quadrant)?.label}
      </button>
      <div className="flex flex-wrap gap-2">
        {tagsForQuadrant.map((t) => (
          <button
            key={t.value}
            type="button"
            onClick={() => onTagChange(t.value)}
            className={chipClass(tag === t.value)}
          >
            <span>{t.emoji}</span>
            <span>{t.label}</span>
          </button>
        ))}
      </div>
    </div>
  )
}
