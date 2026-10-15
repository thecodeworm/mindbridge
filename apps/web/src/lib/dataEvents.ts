// Signals that the signed-in user's mood data changed (check-in, edit,
// delete) so mounted views can refetch. Mirrors mobile's core/app_events.dart.
const EVENT = 'mindbridge:mood-data-changed'

export function notifyMoodDataChanged() {
  window.dispatchEvent(new Event(EVENT))
}

export function onMoodDataChanged(handler: () => void): () => void {
  window.addEventListener(EVENT, handler)
  return () => window.removeEventListener(EVENT, handler)
}
