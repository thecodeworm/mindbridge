import type { ReactNode } from 'react'
import { Link, NavLink, Outlet } from 'react-router-dom'
import { CrisisChip } from '../CrisisChip'

const TABS = [
  { to: '/', label: 'Today', icon: 'M12 3v2m0 14v2M5.6 5.6l1.4 1.4m10 10 1.4 1.4M3 12h2m14 0h2M5.6 18.4 7 17M17 7l1.4-1.4M16 12a4 4 0 1 1-8 0 4 4 0 0 1 8 0Z' },
  { to: '/journal', label: 'Journal', icon: 'M4 19.5V5a2 2 0 0 1 2-2h13v16H6.5A2.5 2.5 0 0 0 4 21.5Zm0 0A2.5 2.5 0 0 1 6.5 17H19M8 7h7' },
  { to: '/insights', label: 'Insights', icon: 'M3 3v18h18M7 15l4-4 3 3 5-6' },
  { to: '/toolkit', label: 'Toolkit', icon: 'M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2Z' },
] as const

function TabIcon({ d }: { d: string }) {
  return (
    <svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
      <path d={d} />
    </svg>
  )
}

/**
 * Signed-in frame: header (wordmark, desktop tabs, Help, Settings) and a
 * bottom tab bar on phone widths. Mirrors apps/mobile's MainShell tabs:
 * Today / Journal / Insights / Toolkit.
 */
export function AppShell({ children }: { children?: ReactNode }) {
  return (
    <div className="min-h-screen bg-cream">
      <header className="sticky top-0 z-30 border-b border-border bg-cream/90 backdrop-blur">
        <div className="mx-auto flex h-16 max-w-3xl items-center gap-4 px-4 sm:px-6">
          <Link to="/" className="font-display text-xl font-semibold text-blue-dark">
            MindBridge
          </Link>
          <nav aria-label="Main" className="ml-4 hidden flex-1 gap-1 sm:flex">
            {TABS.map((t) => (
              <NavLink
                key={t.to}
                to={t.to}
                end={t.to === '/'}
                className={({ isActive }) =>
                  `rounded-full px-3.5 py-1.5 text-sm font-semibold transition-colors ${
                    isActive ? 'bg-blue-tint text-blue-dark' : 'text-muted hover:text-ink'
                  }`
                }
              >
                {t.label}
              </NavLink>
            ))}
          </nav>
          <div className="ml-auto flex items-center gap-1.5">
            <CrisisChip inline />
            <Link
              to="/settings"
              aria-label="Settings"
              title="Settings"
              className="flex h-10 w-10 items-center justify-center rounded-full text-ink transition-colors hover:bg-surface"
            >
              <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
                <circle cx="12" cy="12" r="3" />
                <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z" />
              </svg>
            </Link>
          </div>
        </div>
      </header>

      <main className="mx-auto max-w-3xl px-4 pb-28 pt-6 sm:px-6 sm:pb-16">{children ?? <Outlet />}</main>

      <nav
        aria-label="Main"
        className="fixed inset-x-0 bottom-0 z-30 border-t border-border bg-card pb-[env(safe-area-inset-bottom)] sm:hidden"
      >
        <div className="grid grid-cols-4">
          {TABS.map((t) => (
            <NavLink
              key={t.to}
              to={t.to}
              end={t.to === '/'}
              className={({ isActive }) =>
                `flex flex-col items-center gap-1 py-2.5 text-xs font-semibold ${isActive ? 'text-blue-dark' : 'text-muted'}`
              }
            >
              {({ isActive }) => (
                <>
                  <span className={`rounded-full px-4 py-1 ${isActive ? 'bg-blue-tint' : ''}`}>
                    <TabIcon d={t.icon} />
                  </span>
                  {t.label}
                </>
              )}
            </NavLink>
          ))}
        </div>
      </nav>
    </div>
  )
}
