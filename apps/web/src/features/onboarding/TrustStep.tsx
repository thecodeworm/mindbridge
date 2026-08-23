/**
 * Onboarding screen 2 — trust/privacy. Ranked more important for a teen
 * mental-health app than a general wellness app (Wysa's anonymity-first
 * framing, per docs/research/00-design-direction.md §6.2). Mirrors
 * apps/mobile/lib/features/onboarding/steps/trust_step.dart.
 */
export function TrustStep({ onNext }: { onNext: () => void }) {
  return (
    <div className="flex flex-col items-center justify-center px-8 text-center">
      <div className="text-5xl">🔒</div>
      <h1 className="mt-6 font-display text-2xl font-bold text-ink">
        Your entries are private.
        <br />
        Only you can see them.
      </h1>
      <div className="card mt-6 p-4">
        <p className="text-sm text-muted">
          Nobody else — not friends, not family, not even MindBridge staff — can read
          your mood logs or journal entries. What you write here stays yours.
        </p>
      </div>
      <button
        type="button"
        onClick={onNext}
        className="mt-12 w-full max-w-xs rounded-full bg-blue-dark px-6 py-3 font-medium text-on-accent transition-opacity hover:opacity-90"
      >
        Next
      </button>
    </div>
  )
}
