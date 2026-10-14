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
    <div>
      <div className="flex flex-wrap gap-2">
        {tags.map((tag) => {
          const isSelected = selected.includes(tag.id)
          return (
            <button
              key={tag.id}
              type="button"
              aria-pressed={isSelected}
              onClick={() => toggle(tag.id)}
              className={[
                'flex items-center gap-1.5 rounded-lg border-[1.5px] px-3 py-1.5 text-sm font-medium transition-colors',
                isSelected
                  ? 'border-blue-dark bg-blue-dark text-on-accent'
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
