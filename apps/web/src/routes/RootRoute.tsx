import { Navigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { LandingPage } from '../pages/LandingPage'
import { HomePage } from '../pages/HomePage'
import { AppShell } from '../components/shell/AppShell'

/**
 * `/` itself — the one route whose content depends on auth state rather
 * than being purely public or purely protected: signed-out visitors get the
 * public LandingPage (the app's front door), signed-in users get the
 * dashboard. Mirrors ProtectedRoute's recovery-session handling so a
 * password-reset link landing on `/` still redirects correctly.
 */
export function RootRoute() {
  const { session, loading, isRecoverySession } = useAuth()

  if (loading) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-cream">
        <p className="text-muted">Loading…</p>
      </div>
    )
  }

  if (isRecoverySession) {
    return <Navigate to="/reset-password" replace />
  }

  if (!session) {
    return <LandingPage />
  }

  return (
    <AppShell>
      <HomePage />
    </AppShell>
  )
}
