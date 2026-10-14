const PATHS = {
  check: 'm5 12 4 4L19 6',
  mail: 'M3 5h18v14H3z m0 0 9 7 9-7',
  lock: 'M5 10h14v11H5z M8 10V6a4 4 0 0 1 8 0v4',
  chart: 'M4 3v17h17 M7 14l4-5 4 3 5-7',
  waves: 'M3 7q3-4 6 0t6 0 6 0 M3 12q3-4 6 0t6 0 6 0 M3 17q3-4 6 0t6 0 6 0',
  sprout: 'M12 21V11 M12 15C4 15 3 10 3 5c6 0 9 3 9 10 M12 11c0-6 3-8 9-8 0 5-3 8-9 8',
  explore: 'M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18 M16 8l-3 5-5 3 3-5z',
  slider: 'M3 7h7 m4 0h7 M3 17h11 m4 0h3 M10 4v6 M18 14v6',
  tag: 'M3 3h8l10 10-8 8L3 11z M7 7h.01',
  bulb: 'M9 18h6 M9 21h6 M8 14a6 6 0 1 1 8 0l-1 4H9z',
  phone: 'M5 3h4l2 5-3 2a14 14 0 0 0 6 6l2-3 5 2v4c-9 3-20-8-16-16z',
  message: 'M3 3h18v14H8l-5 4z M7 7h10 M7 11h7',
} as const

export function NotebookIcon({ name }: { name: keyof typeof PATHS }) {
  return <svg viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round" className="shrink-0" aria-hidden><path d={PATHS[name]} /></svg>
}
