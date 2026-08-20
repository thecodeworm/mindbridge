import { useEffect, useState } from 'react'

interface Props {
  /** Single fixed tone. Provide this OR `colors`, not both. */
  color?: string
  /** A palette to slowly cycle through (e.g. the full mood ramp). Runs on
   * its own independent, slower loop so a color change never reads as
   * "one color per breath." */
  colors?: string[]
  size?: number
  /** Duration of one inhale OR exhale leg — a full breath is twice this. */
  cycleSeconds?: number
}

/**
 * MindBridge's signature breathing-circle: a soft glow that expands and
 * contracts on a real breath cadence, reused as the AI-suggestion
 * "thinking" state and the onboarding welcome/first-check-in screens.
 * Mirrors apps/mobile/lib/widgets/breathing_circle.dart.
 */
export function BreathingCircle({ color, colors, size = 96, cycleSeconds = 4 }: Props) {
  const [tick, setTick] = useState(0)

  const cycling = colors && colors.length > 1
  useEffect(() => {
    if (!cycling) return
    const id = setInterval(() => setTick((t) => t + 1), cycleSeconds * 2000)
    return () => clearInterval(id)
  }, [cycling, cycleSeconds])

  const currentColor = (() => {
    if (!colors || colors.length === 0) return color ?? '#C97B52'
    if (colors.length === 1) return colors[0]
    return colors[tick % colors.length]
  })()

  return (
    <div
      className="animate-breathe pointer-events-none rounded-full"
      style={{
        width: size,
        height: size,
        background: `radial-gradient(circle, ${currentColor}59 0%, ${currentColor}00 70%)`,
        transition: cycling ? `background ${cycleSeconds}s linear` : undefined,
        animationDuration: `${cycleSeconds}s`,
      }}
    />
  )
}
