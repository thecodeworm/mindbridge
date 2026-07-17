import { Routes, Route } from 'react-router-dom'
import { ProtectedRoute } from './routes/ProtectedRoute'
import { SignUpPage } from './pages/SignUpPage'
import { LoginPage } from './pages/LoginPage'
import { HomePage } from './pages/HomePage'
import { MoodLogPage } from './pages/MoodLogPage'
import { SuggestionPage } from './pages/SuggestionPage'

function App() {
  return (
    <Routes>
      <Route path="/signup" element={<SignUpPage />} />
      <Route path="/login" element={<LoginPage />} />
      <Route element={<ProtectedRoute />}>
        <Route path="/" element={<HomePage />} />
        <Route path="/log" element={<MoodLogPage />} />
        <Route path="/suggestion" element={<SuggestionPage />} />
      </Route>
    </Routes>
  )
}

export default App
