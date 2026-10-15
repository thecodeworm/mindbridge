// Maps raw backend/network error text to calm copy a teenager can act on.
// Mirrors apps/mobile/lib/core/app_exception.dart's friendlyErrorMessage().
// Plain sentences written by our own services pass through unchanged.
export function friendlyError(raw: string): string {
  const lower = raw.toLowerCase()
  if (lower.includes('jwt') || lower.includes('token') || lower.includes('session')) {
    return "We couldn't confirm you're signed in. Check your device's date and time, then sign out and back in."
  }
  if (
    lower.includes('failed to fetch') ||
    lower.includes('network') ||
    lower.includes('timed out') ||
    lower.includes('timeout') ||
    lower.includes('connection')
  ) {
    return "Can't reach MindBridge right now. Check your connection and try again."
  }
  if (lower.includes('rate') || lower.includes('429') || lower.includes('too many')) {
    return "You've checked in a lot this hour. Take a breather and try again a bit later."
  }
  const looksTechnical =
    lower.includes('exception') ||
    lower.includes('pgrst') ||
    lower.includes('violates') ||
    lower.includes('constraint') ||
    lower.includes('status') ||
    lower.includes('{') ||
    lower.includes('null') ||
    raw.trim() === ''
  if (looksTechnical) return 'Something went wrong on our end. Give it a moment and try again.'
  return raw
}
