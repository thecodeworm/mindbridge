// Mood scale as highlighter-pen colors (the "Notebook" direction), heavy to
// great. Matches CLAUDE.md § Mood Scale Stops and mobile core/mood_color.dart.
// Still a temperature ramp: no red, no green, nothing that reads as "bad day".
const MOOD_COLORS: [number, string][] = [
  [1, '#B9B3F2'],
  [2.5, '#9ED3F5'],
  [4.5, '#F2E58A'],
  [6.5, '#FFC07A'],
  [8.5, '#FF9FCB'],
]

/**
 * Notebook mood colors are five solid highlighter shades, one per band of two
 * scores (1-2, 3-4, 5-6, 7-8, 9-10). No blending: mixing sky blue into
 * butter yellow produces a green, and green would read as "good".
 */
export function moodColor(score: number): string {
  for (let i = MOOD_COLORS.length - 1; i >= 0; i--) {
    if (score >= MOOD_COLORS[i][0]) return MOOD_COLORS[i][1]
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
