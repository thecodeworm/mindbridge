const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

export function isUuid(value: unknown): value is string {
  return typeof value === 'string' && UUID_RE.test(value)
}

const DAY_MS = 24 * 60 * 60 * 1000
const MAX_WEEK_AGE_DAYS = 400

// week_start arrives from the client and is interpolated into a model prompt,
// so it has to be exactly YYYY-MM-DD. `new Date()` alone is not enough:
// V8 accepts "2026-10-12 (any text here" and rolls "2026-02-30" over to March.
// Returns the date string when valid, otherwise null. It must be a real
// calendar date, a Monday (UTC), not meaningfully in the future (one day of
// slack for clients ahead of UTC) and not older than ~13 months.
export function parseWeekStart(
  value: unknown,
  now: Date = new Date(),
): string | null {
  if (typeof value !== 'string') return null
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value)
  if (!match) return null

  const [, y, m, d] = match
  const date = new Date(Date.UTC(Number(y), Number(m) - 1, Number(d)))
  const roundTrips = date.getUTCFullYear() === Number(y) &&
    date.getUTCMonth() === Number(m) - 1 &&
    date.getUTCDate() === Number(d)
  if (!roundTrips) return null
  if (date.getUTCDay() !== 1) return null // Monday

  const t = date.getTime()
  if (t > now.getTime() + DAY_MS) return null
  if (t < now.getTime() - MAX_WEEK_AGE_DAYS * DAY_MS) return null

  return value
}

// Journal text is wrapped in <journal_entry> tags inside the prompt. Strip
// angle brackets so an entry cannot close the tag and impersonate instructions.
export function stripAngleBrackets(text: string): string {
  return text.replace(/[<>]/g, '')
}
