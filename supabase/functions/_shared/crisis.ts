// Server-side floor for crisis detection. The model's own crisis_signal can be
// suppressed by prompt injection, so both Edge Functions also scan the user's
// journal text with this list. It only ever ADDS risk; it never lowers it.
//
// Matching is on normalized text (lowercase, curly apostrophes straightened,
// punctuation turned into spaces) with word boundaries, so "I can't go on."
// and "i cant go on" both match and "kms" does not match inside another word.
// It is a keyword floor, not a classifier: it will miss indirect phrasing.
const CRISIS_PHRASES = [
  'kill myself',
  'killing myself',
  'suicide',
  'suicidal',
  'end my life',
  'ending my life',
  'end it all',
  'take my own life',
  'taking my own life',
  'want to die',
  'wanna die',
  'want to be dead',
  'wish i was dead',
  'wish i were dead',
  'wish i was never born',
  'better off dead',
  'better off without me',
  'self harm',
  'hurt myself',
  'hurting myself',
  'harm myself',
  'harming myself',
  'cut myself',
  'cutting myself',
  'no reason to live',
  'no point in living',
  'not worth living',
  'dont want to live',
  'dont want to be here anymore',
  'cant go on',
  'kms',
  'unalive',
  'overdose',
]

export function normalizeForCrisis(text: string): string {
  return text
    .toLowerCase()
    .replace(/[‘’ʼ`]/g, "'")
    // "don't" and "dont" must match the same phrase.
    .replace(/'/g, '')
    .replace(/[^a-z0-9]+/g, ' ')
    .trim()
}

export function hasCrisisLanguage(text: string | null | undefined): boolean {
  if (!text) return false
  const haystack = ` ${normalizeForCrisis(text)} `
  return CRISIS_PHRASES.some((phrase) => haystack.includes(` ${phrase} `))
}
