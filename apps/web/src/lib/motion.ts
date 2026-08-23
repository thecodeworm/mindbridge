// MindBridge motion tokens — durations (ms) + named easing curves, mirroring
// apps/mobile/lib/core/motion.dart's AppMotion and the CSS custom properties
// in index.css (--duration-*, --ease-*). This module exists for the handful
// of places that need the *numeric* values in JS (setTimeout delays,
// computed inline styles) rather than a CSS class — the CSS custom
// properties remain the source of truth for anything expressible in CSS.
//
// Never reach for a bare 200/300/etc ms literal or a plain 'ease' curve —
// use one of these. High-frequency interactions (slider drag ticks, chip
// taps — dozens of times per session) should stay at `instant` or skip
// animation entirely, per the Linear frequency rule in
// docs/research/00-design-direction.md §1.
export const duration = {
  instant: 80,
  micro: 180,
  short: 250,
  medium: 350,
  long: 500,
  extraLong: 850,
} as const

export const easing = {
  standard: 'cubic-bezier(0.2, 0, 0, 1)',
  standardDecelerate: 'cubic-bezier(0, 0, 0, 1)',
  standardAccelerate: 'cubic-bezier(0.3, 0, 1, 1)',
  emphasizedDecelerate: 'cubic-bezier(0.05, 0.7, 0.1, 1)', // hero entrances
  emphasizedAccelerate: 'cubic-bezier(0.3, 0, 0.8, 0.15)', // dismissals
  wobbly: 'cubic-bezier(0.34, 1.56, 0.64, 1)', // spring-like overshoot
} as const
