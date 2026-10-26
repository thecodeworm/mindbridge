import { NotebookIcon } from '../components/NotebookIcon'
import { useState, type FormEvent } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { CrisisChip } from '../components/CrisisChip'
import { GOOGLE_CONSENT_NOTICE } from '../lib/privacyCopy'

function GoogleIcon() {
  return (
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="18" height="18">
      <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" />
      <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" />
      <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" />
      <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" />
    </svg>
  )
}

function EyeIcon() {
  return (
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" />
      <circle cx="12" cy="12" r="3" />
    </svg>
  )
}

function EyeOffIcon() {
  return (
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M17.94 17.94A10.07 10.07 0 0112 20c-7 0-11-8-11-8a18.45 18.45 0 015.06-5.94M9.9 4.24A9.12 9.12 0 0112 4c7 0 11 8 11 8a18.5 18.5 0 01-2.16 3.19m-6.72-1.07a3 3 0 11-4.24-4.24" />
      <line x1="1" y1="1" x2="23" y2="23" />
    </svg>
  )
}

export function LoginPage() {
  const { signIn, signInWithGoogle, resetPassword } = useAuth()
  const navigate = useNavigate()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [submitting, setSubmitting] = useState(false)
  const [forgotMode, setForgotMode] = useState(false)
  const [resetSent, setResetSent] = useState(false)

  async function handleSubmit(e: FormEvent) {
    e.preventDefault()
    setError(null)
    setSubmitting(true)
    const { error } = await signIn(email, password)
    setSubmitting(false)
    if (error) { setError(error); return }
    navigate('/')
  }

  async function handleGoogleSignIn() {
    setError(null)
    const { error } = await signInWithGoogle()
    if (error) setError(error)
  }

  async function handleForgotPassword(e: FormEvent) {
    e.preventDefault()
    setError(null)
    setSubmitting(true)
    const { error } = await resetPassword(email)
    setSubmitting(false)
    if (error) { setError(error); return }
    setResetSent(true)
  }

  const brandHeader = (
    <header className="mb-12 flex w-full max-w-md items-center gap-4">
      <span className="flex-1 font-display text-xl font-black tracking-tight text-ink">MindBridge</span>
      <CrisisChip inline />
    </header>
  )

  if (forgotMode) {
    if (resetSent) {
      return (
        <div className="flex min-h-screen flex-col items-center bg-cream px-6 pb-12 pt-5">
          {brandHeader}
          <div className="w-full max-w-md space-y-4 text-left">
            <NotebookIcon name="mail" />
            <h1 className="text-4xl text-ink"><span className="hl">Check your inbox</span></h1>
            <p className="text-sm text-muted">
              We sent a reset link to <span className="text-ink">{email}</span>.
            </p>
            <button
              onClick={() => { setForgotMode(false); setResetSent(false) }}
              className="text-sm font-medium text-blue-dark hover:underline"
            >
              Back to log in
            </button>
          </div>

        </div>
      )
    }

    return (
      <div className="flex min-h-screen flex-col items-center bg-cream px-6 pb-12 pt-5">
        {brandHeader}
        <form
          onSubmit={handleForgotPassword}
          className="w-full max-w-md space-y-4"
        >
          <h1 className="text-4xl text-ink sm:text-5xl"><span className="hl">Reset your password.</span></h1>
          <p className="text-sm text-muted">Enter your email and we'll send you a reset link.</p>
          <p className="text-xs text-faint">Signed up with Google? Use the Google button on the log in page instead.</p>
          {error && (
            <p className="rounded-[10px] bg-error-tint px-4 py-2 text-sm text-error">{error}</p>
          )}
          <input
            type="email"
            placeholder="Email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
            autoComplete="email"
            className="w-full rounded-[10px] border border-border bg-field px-4 py-3 text-ink placeholder:text-faint"
          />
          <button
            type="submit"
            disabled={submitting}
            className="w-full rounded-[10px] bg-blue-dark px-4 py-3 font-display font-extrabold text-on-accent transition-opacity hover:opacity-90 disabled:opacity-50"
          >
            {submitting ? 'Sending…' : 'Send reset link'}
          </button>
          <button
            type="button"
            onClick={() => { setForgotMode(false); setError(null) }}
            className="w-full text-center text-sm font-medium text-blue-dark hover:underline"
          >
            Back to log in
          </button>
        </form>

      </div>
    )
  }

  return (
    <div className="flex min-h-screen flex-col items-center bg-cream px-6 pb-12 pt-5">
      {brandHeader}
      <form
        onSubmit={handleSubmit}
        className="w-full max-w-md space-y-4"
      >
        <h1 className="text-4xl text-ink sm:text-5xl">Welcome back.<br /><span className="hl">Log in.</span></h1>
        {error && (
          <p className="rounded-[10px] bg-error-tint px-4 py-2 text-sm text-error">{error}</p>
        )}
        <button
          type="button"
          onClick={handleGoogleSignIn}
          className="flex w-full items-center justify-center gap-2 rounded-[10px] border border-border bg-field px-4 py-3 font-medium text-ink transition-colors hover:bg-blue-tint"
        >
          <GoogleIcon />
          Continue with Google
        </button>
        <p className="px-1 text-xs text-faint">{GOOGLE_CONSENT_NOTICE}</p>
        <div className="relative">
          <div className="absolute inset-0 flex items-center">
            <div className="w-full border-t border-border" />
          </div>
          <div className="relative flex justify-center text-sm">
            <span className="bg-cream px-2 text-muted">or</span>
          </div>
        </div>
        <input
          type="email"
          placeholder="Email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          required
          autoComplete="email"
          className="w-full rounded-[10px] border border-border bg-field px-4 py-3 text-ink placeholder:text-faint"
        />
        <div className="relative">
          <input
            type={showPassword ? 'text' : 'password'}
            placeholder="Password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
            autoComplete="current-password"
            className="w-full rounded-[10px] border border-border bg-field px-4 py-3 pr-11 text-ink placeholder:text-faint"
          />
          <button
            type="button"
            onClick={() => setShowPassword((v) => !v)}
            tabIndex={-1}
            aria-label={showPassword ? 'Hide password' : 'Show password'}
            className="absolute right-3 top-1/2 -translate-y-1/2 text-faint hover:text-muted"
          >
            {showPassword ? <EyeOffIcon /> : <EyeIcon />}
          </button>
        </div>
        <div className="flex justify-end -mt-2">
          <button
            type="button"
            onClick={() => { setForgotMode(true); setError(null) }}
            className="text-sm font-medium text-blue-dark hover:underline"
          >
            Forgot?
          </button>
        </div>
        <button
          type="submit"
          disabled={submitting}
          className="w-full rounded-[10px] bg-blue-dark px-4 py-3 font-display font-extrabold text-on-accent transition-opacity hover:opacity-90 disabled:opacity-50"
        >
          {submitting ? 'Logging in…' : 'Log in'}
        </button>
        <p className="text-center text-sm text-muted">
          Need an account?{' '}
          <Link to="/signup" className="font-medium text-blue-dark hover:underline">
            Sign up
          </Link>
        </p>
      </form>

    </div>
  )
}
