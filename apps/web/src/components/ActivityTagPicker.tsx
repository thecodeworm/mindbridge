import type { ActivityTag } from '../../../../shared/types'

interface Props {
  tags: ActivityTag[]
  selected: string[]
  onChange: (ids: string[]) => void
}

export function ActivityTagPicker({ tags, selected, onChange }: Props) {
  if (tags.length === 0) return null

  function toggle(id: string) {
    onChange(
      selected.includes(id) ? selected.filter((s) => s !== id) : [...selected, id],
    )
  }

  return (
    <div className="space-y-2">
      <p className="text-sm font-medium text-muted">
        What was going on? <span className="font-normal text-faint">(optional)</span>
      </p>
      <div className="flex flex-wrap gap-2">
        {tags.map((tag) => {
          const isSelected = selected.includes(tag.id)
          return (
            <button
              key={tag.id}
              type="button"
              onClick={() => toggle(tag.id)}
              className={[
                'flex items-center gap-1.5 rounded-lg border px-3 py-1.5 text-sm font-medium transition-colors',
                isSelected
                  ? 'border-blue-dark bg-blue-tint text-blue-dark'
                  : 'border-border bg-field text-ink hover:bg-blue-tint',
              ].join(' ')}
            >
              <span>{tag.emoji}</span>
              <span>{tag.label}</span>
            </button>
          )
        })}
      </div>
    </div>
  )
}
