import { useEffect, useState } from 'react'
import { LOADING_TIPS } from '../lib/loadingTips'

interface Props {
  /** Tips to rotate through. Defaults to the shared list. */
  tips?: readonly string[]
  /** Time each tip stays on screen before the next one. */
  intervalMs?: number
  /** Index of the first tip. Defaults to a random one; tests pin it. */
  startIndex?: number
}

/**
 * A quiet "QUICK TIP" card shown under the breathing circle while the AI
 * suggestion loads. Starts on a random tip, then advances (wrapping) every
 * `intervalMs`. The new tip fades in (`.animate-tip-fade`, disabled under
 * prefers-reduced-motion, where it just swaps). The card keeps a fixed min
 * height so tips of different lengths never make the layout jump.
 * Mirrors apps/mobile/lib/widgets/loading_tip.dart.
 */
export function LoadingTip({ tips = LOADING_TIPS, intervalMs = 4000, startIndex }: Props) {
  const count = tips.length
  const [index, setIndex] = useState(() =>
    startIndex ?? Math.floor(Math.random() * Math.max(count, 1)),
  )

  useEffect(() => {
    if (count < 2) return
    const id = setInterval(() => setIndex((i) => (i + 1) % count), intervalMs)
    return () => clearInterval(id)
  }, [count, intervalMs])

  if (count === 0) return null

  return (
    <div className="card mt-8 w-full max-w-[22rem] p-4">
      <p className="label">Quick tip</p>
      {/* 3 lines of leading-relaxed text at 16px (26px each) fits the longest tip at 390px wide. */}
      <p aria-live="polite" className="mt-2 min-h-[4.875rem] text-base leading-relaxed text-ink">
        <span key={index} className="animate-tip-fade block">
          {tips[index % count]}
        </span>
      </p>
    </div>
  )
}
