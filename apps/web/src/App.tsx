import { lazy, Suspense } from 'react'
import { Routes, Route } from 'react-router-dom'
import { ProtectedRoute } from './routes/ProtectedRoute'
import { RootRoute } from './routes/RootRoute'
import { AppShell } from './components/shell/AppShell'
import { SignUpPage } from './pages/SignUpPage'
import { LoginPage } from './pages/LoginPage'

// Everything behind sign-in (and the onboarding flow) is split into its own
// chunk, so a first-time visitor on the landing page doesn't download the
// Recharts dashboard, settings, etc. up front.
const OnboardingFlow = lazy(() => import('./features/onboarding/OnboardingFlow').then((m) => ({ default: m.OnboardingFlow })))
const ResetPasswordPage = lazy(() => import('./pages/ResetPasswordPage').then((m) => ({ default: m.ResetPasswordPage })))
const HelpPage = lazy(() => import('./pages/HelpPage').then((m) => ({ default: m.HelpPage })))
const MoodLogPage = lazy(() => import('./pages/MoodLogPage').then((m) => ({ default: m.MoodLogPage })))
const SuggestionPage = lazy(() => import('./pages/SuggestionPage').then((m) => ({ default: m.SuggestionPage })))
const EntryDetailPage = lazy(() => import('./pages/EntryDetailPage').then((m) => ({ default: m.EntryDetailPage })))
const SettingsPage = lazy(() => import('./pages/SettingsPage').then((m) => ({ default: m.SettingsPage })))
const ToolkitPage = lazy(() => import('./pages/ToolkitPage').then((m) => ({ default: m.ToolkitPage })))
const JournalPage = lazy(() => import('./pages/JournalPage').then((m) => ({ default: m.JournalPage })))
const InsightsPage = lazy(() => import('./pages/InsightsPage').then((m) => ({ default: m.InsightsPage })))

function RouteFallback() {
  return (
    <div className="flex min-h-[50vh] items-center justify-center">
      <p className="text-muted">Loading…</p>
    </div>
  )
}

function App() {
  return (
    <Suspense fallback={<RouteFallback />}>
      <Routes>
        <Route path="/" element={<RootRoute />} />
        <Route path="/onboarding" element={<OnboardingFlow />} />
        <Route path="/signup" element={<SignUpPage />} />
        <Route path="/login" element={<LoginPage />} />
        <Route path="/reset-password" element={<ResetPasswordPage />} />
        <Route path="/help" element={<HelpPage />} />
        <Route element={<ProtectedRoute />}>
          <Route element={<AppShell />}>
            <Route path="/journal" element={<JournalPage />} />
            <Route path="/insights" element={<InsightsPage />} />
            <Route path="/toolkit" element={<ToolkitPage />} />
          </Route>
          <Route path="/log" element={<MoodLogPage />} />
          <Route path="/suggestion" element={<SuggestionPage />} />
          <Route path="/entry/:moodLogId" element={<EntryDetailPage />} />
          <Route path="/settings" element={<SettingsPage />} />
        </Route>
      </Routes>
    </Suspense>
  )
}

export default App
