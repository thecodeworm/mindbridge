import { Routes, Route } from 'react-router-dom'
import { ProtectedRoute } from './routes/ProtectedRoute'
import { RootRoute } from './routes/RootRoute'
import { OnboardingFlow } from './features/onboarding/OnboardingFlow'
import { SignUpPage } from './pages/SignUpPage'
import { LoginPage } from './pages/LoginPage'
import { ResetPasswordPage } from './pages/ResetPasswordPage'
import { MoodLogPage } from './pages/MoodLogPage'
import { SuggestionPage } from './pages/SuggestionPage'
import { EntryDetailPage } from './pages/EntryDetailPage'
import { SettingsPage } from './pages/SettingsPage'
import { HelpPage } from './pages/HelpPage'
import { ToolkitPage } from './pages/ToolkitPage'

function App() {
  return (
    <Routes>
      <Route path="/" element={<RootRoute />} />
      <Route path="/onboarding" element={<OnboardingFlow />} />
      <Route path="/signup" element={<SignUpPage />} />
      <Route path="/login" element={<LoginPage />} />
      <Route path="/reset-password" element={<ResetPasswordPage />} />
      <Route path="/help" element={<HelpPage />} />
      <Route element={<ProtectedRoute />}>
        <Route path="/log" element={<MoodLogPage />} />
        <Route path="/suggestion" element={<SuggestionPage />} />
        <Route path="/entry/:moodLogId" element={<EntryDetailPage />} />
        <Route path="/settings" element={<SettingsPage />} />
        <Route path="/toolkit" element={<ToolkitPage />} />
      </Route>
    </Routes>
  )
}

export default App
