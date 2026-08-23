import { Link } from 'react-router-dom'

/**
 * Persistent, always-visible crisis affordance (Wysa's SOS-button pattern),
 * per docs/research/00-design-direction.md §8 — not confined to
 * entry-detail. Small and unobtrusive by design: terra-tint chip, never a
 * red banner, per CLAUDE.md's crisis-affordance design rule. Fixed to the
 * bottom-right corner on every route that carries it, mirroring
 * apps/mobile/lib/widgets/crisis_fab.dart's placement on ~10 Flutter screens.
 */
export function CrisisChip() {
  return (
    <Link
      to="/help"
      aria-label="Crisis resources & help"
      title="Crisis resources & help"
      className="crisis-chip fixed bottom-4 right-4 z-40 flex h-12 w-12 items-center justify-center rounded-full"
    >
      <svg
        xmlns="http://www.w3.org/2000/svg"
        viewBox="0 0 24 24"
        width="22"
        height="22"
        fill="none"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      >
        <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" />
      </svg>
    </Link>
  )
}
