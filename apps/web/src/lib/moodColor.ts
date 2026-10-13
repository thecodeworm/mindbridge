// Mood scale color stops — matches CLAUDE.md § Mood Scale Stops.
// Temperature ramp (slate -> gold), never red -> green.
const MOOD_COLORS: [number, string][] = [
  [1, '#7C8BA8'],
  [3, '#96A9C1'],
  [5, '#C4BCA9'],
  [7, '#DFB05E'],
  [10, '#DD955A'],
]

function lerpHex(a: string, b: string, t: number): string {
  const parse = (h: string) => [
    parseInt(h.slice(1, 3), 16),
    parseInt(h.slice(3, 5), 16),
    parseInt(h.slice(5, 7), 16),
  ]
  const [ar, ag, ab] = parse(a)
  const [br, bg, bb] = parse(b)
  const r = Math.round(ar + (br - ar) * t)
  const g = Math.round(ag + (bg - ag) * t)
  const bv = Math.round(ab + (bb - ab) * t)
  return `#${r.toString(16).padStart(2, '0')}${g.toString(16).padStart(2, '0')}${bv.toString(16).padStart(2, '0')}`
}

export function moodColor(score: number): string {
  for (let i = MOOD_COLORS.length - 1; i >= 0; i--) {
    if (score >= MOOD_COLORS[i][0]) {
      const [lo, loColor] = MOOD_COLORS[i]
      const [hi, hiColor] = MOOD_COLORS[i + 1] ?? MOOD_COLORS[i]
      if (lo === hi) return loColor
      const t = (score - lo) / (hi - lo)
      return lerpHex(loColor, hiColor, t)
    }
  }
  return MOOD_COLORS[0][1]
}

/** One plain word for a 1–10 score; gentle at the low end, never "bad". */
export function moodWord(score: number): string {
  const s = Math.round(score)
  if (s <= 2) return 'Heavy'
  if (s <= 4) return 'Low'
  if (s <= 6) return 'Okay'
  if (s <= 8) return 'Good'
  return 'Great'
}
