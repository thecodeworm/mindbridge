import { Link } from 'react-router-dom'

/**
 * Persistent, always-visible crisis affordance, per
 * docs/research/00-design-direction.md §8 and CLAUDE.md: a soft-bordered
 * terracotta "Help" pill, never a red banner.
 *
 * `inline` renders it in flow (the app shell's header). Otherwise it pins to
 * the top-right corner on standalone pages; it used to sit bottom-right,
 * where it covered list content and bottom buttons.
 * Mirrors apps/mobile/lib/widgets/crisis_fab.dart's HelpChip.
 */
export function CrisisChip({ inline = false }: { inline?: boolean }) {
  return (
    <Link
      to="/help"
      aria-label="Crisis resources & help"
      title="Crisis resources & help"
      className={`crisis-chip inline-flex items-center gap-1.5 rounded-full py-1.5 pl-2.5 pr-3.5 text-sm font-semibold ${
        inline ? '' : 'fixed right-4 top-4 z-40'
      }`}
    >
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
        <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" />
      </svg>
      Help
    </Link>
  )
}
