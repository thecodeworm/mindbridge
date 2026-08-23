import { useRef, useState } from 'react'
import { moodColor } from '../lib/moodColor'

interface Props {
  value: number
  onChange: (value: number) => void
  min?: number
  max?: number
}

const TRACK_HEIGHT = 10
const THUMB_DIAMETER = 28
const HEIGHT = 64

/**
 * MindBridge's felt mood-entry slider, per
 * docs/research/00-design-direction.md §5: thumb scales up on drag start
 * (spring-like settle on release), track fill continuously interpolates
 * through the mood-temperature ramp, a numeral bubble floats above the
 * thumb while dragging.
 *
 * A custom pointer-driven drag surface rather than a native `<input
 * type="range">` — the thumb-scale + floating-label combination isn't
 * expressible through native range styling. Mirrors
 * apps/mobile/lib/widgets/felt_mood_slider.dart (haptics omitted — not
 * applicable on web).
 */
export function FeltMoodSlider({ value, onChange, min = 1, max = 10 }: Props) {
  const trackRef = useRef<HTMLDivElement>(null)
  const [dragging, setDragging] = useState(false)

  const fraction = Math.min(1, Math.max(0, (value - min) / (max - min)))
  const color = moodColor(value)

  function updateFromClientX(clientX: number) {
    const el = trackRef.current
    if (!el) return
    const rect = el.getBoundingClientRect()
    const frac = Math.min(1, Math.max(0, (clientX - rect.left) / rect.width))
    onChange(min + frac * (max - min))
  }

  function handlePointerDown(e: React.PointerEvent<HTMLDivElement>) {
    ;(e.target as HTMLElement).setPointerCapture(e.pointerId)
    setDragging(true)
    updateFromClientX(e.clientX)
  }

  function handlePointerMove(e: React.PointerEvent<HTMLDivElement>) {
    if (!dragging) return
    updateFromClientX(e.clientX)
  }

  function endDrag() {
    setDragging(false)
  }

  function handleKeyDown(e: React.KeyboardEvent<HTMLDivElement>) {
    const step = e.shiftKey ? 1 : 0.5
    if (e.key === 'ArrowRight' || e.key === 'ArrowUp') {
      e.preventDefault()
      onChange(Math.min(max, value + step))
    } else if (e.key === 'ArrowLeft' || e.key === 'ArrowDown') {
      e.preventDefault()
      onChange(Math.max(min, value - step))
    } else if (e.key === 'Home') {
      e.preventDefault()
      onChange(min)
    } else if (e.key === 'End') {
      e.preventDefault()
      onChange(max)
    }
  }

  const thumbCenter = `calc(${fraction * 100}% )`

  return (
    <div
      className="relative select-none"
      style={{ height: HEIGHT, touchAction: 'none' }}
    >
      {/* Track */}
      <div
        ref={trackRef}
        role="slider"
        tabIndex={0}
        aria-label="Mood score"
        aria-valuemin={min}
        aria-valuemax={max}
        aria-valuenow={Math.round(value)}
        onPointerDown={handlePointerDown}
        onPointerMove={handlePointerMove}
        onPointerUp={endDrag}
        onPointerCancel={endDrag}
        onKeyDown={handleKeyDown}
        className="absolute inset-x-0 cursor-pointer rounded-full"
        style={{
          top: (HEIGHT - TRACK_HEIGHT) / 2,
          height: TRACK_HEIGHT,
          backgroundColor: `${color}40`,
          transition: `background-color ${dragging ? '0ms' : 'var(--duration-short)'} var(--ease-standard)`,
        }}
      >
        <div
          className="h-full rounded-full"
          style={{
            width: `${fraction * 100}%`,
            backgroundColor: color,
          }}
        />
      </div>

      {/* Thumb */}
      <div
        className="pointer-events-none absolute rounded-full border-[3px]"
        style={{
          left: thumbCenter,
          top: (HEIGHT - THUMB_DIAMETER) / 2,
          width: THUMB_DIAMETER,
          height: THUMB_DIAMETER,
          marginLeft: -THUMB_DIAMETER / 2,
          backgroundColor: color,
          borderColor: 'var(--surface)',
          boxShadow: 'var(--shadow-elevated)',
          transform: `scale(${dragging ? 1.16 : 1})`,
          transition: dragging
            ? `transform var(--duration-short) var(--ease-standard), left 0ms`
            : `transform var(--duration-medium) var(--ease-wobbly), left 0ms`,
        }}
      />

      {/* Floating numeral bubble */}
      <div
        className="pointer-events-none absolute flex w-10 items-center justify-center rounded-xl px-2 py-1 text-sm font-bold"
        style={{
          left: thumbCenter,
          top: 0,
          marginLeft: -20,
          backgroundColor: color,
          color: 'var(--surface)',
          opacity: dragging ? 1 : 0,
          transition: `opacity var(--duration-micro) var(--ease-standard)`,
        }}
      >
        {Math.round(value)}
      </div>
    </div>
  )
}
