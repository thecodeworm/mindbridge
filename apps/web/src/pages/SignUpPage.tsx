import { useState, type FormEvent } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { CrisisChip } from '../components/CrisisChip'
import { consentMetadata, GOOGLE_CONSENT_NOTICE, SIGNUP_CONSENT_LABEL } from '../lib/privacyCopy'
import {
  MIN_PASSWORD_LENGTH,
  PASSWORD_HINT,
  validatePassword,
  validatePasswordConfirmation,
} from '../lib/validators'

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

export function SignUpPage() {
  const { signUp, signInWithGoogle } = useAuth()
  const navigate = useNavigate()
  const [displayName, setDisplayName] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [showConfirmPassword, setShowConfirmPassword] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [submitting, setSubmitting] = useState(false)
  const [consented, setConsented] = useState(false)

  async function handleSubmit(e: FormEvent) {
    e.preventDefault()
    if (!consented) {
      setError('Please confirm you are 13 or older and read the AI note to continue.')
      return
    }
    const passwordError = validatePassword(password) ?? validatePasswordConfirmation(password, confirmPassword)
    if (passwordError) {
      setError(passwordError)
      return
    }
    setError(null)
    setSubmitting(true)
    const { error } = await signUp(email, password, displayName, consentMetadata())
    setSubmitting(false)
    if (error) { setError(error); return }
    navigate('/')
  }

  async function handleGoogleSignIn() {
    setError(null)
    const { error } = await signInWithGoogle()
    if (error) setError(error)
  }

  return (
    <div className="flex min-h-screen flex-col items-center bg-cream px-6 pb-12 pt-5">
      <header className="mb-12 flex w-full max-w-md items-center gap-4">
        <span className="flex-1 font-display text-xl font-black tracking-tight text-ink">MindBridge</span>
        <CrisisChip inline />
      </header>
      <form
        onSubmit={handleSubmit}
        className="w-full max-w-md space-y-4"
      >
        <h1 className="text-4xl text-ink sm:text-5xl">Your space.<br /><span className="hl">Create your account.</span></h1>
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
          type="text"
          placeholder="Display name"
          value={displayName}
          onChange={(e) => setDisplayName(e.target.value)}
          required
          maxLength={60}
          autoComplete="name"
          className="w-full rounded-[10px] border border-border bg-field px-4 py-3 text-ink placeholder:text-faint"
        />
        <input
          type="email"
          placeholder="Email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          required
          autoComplete="email"
          className="w-full rounded-[10px] border border-border bg-field px-4 py-3 text-ink placeholder:text-faint"
        />
        <div className="space-y-1">
          <div className="relative">
            <input
              type={showPassword ? 'text' : 'password'}
              placeholder="Password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              minLength={MIN_PASSWORD_LENGTH}
              autoComplete="new-password"
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
          <p className="px-2 text-xs text-faint">{PASSWORD_HINT}</p>
        </div>
        <div className="relative">
          <input
            type={showConfirmPassword ? 'text' : 'password'}
            placeholder="Confirm password"
            value={confirmPassword}
            onChange={(e) => setConfirmPassword(e.target.value)}
            required
            autoComplete="new-password"
            className="w-full rounded-[10px] border border-border bg-field px-4 py-3 pr-11 text-ink placeholder:text-faint"
          />
          <button
            type="button"
            onClick={() => setShowConfirmPassword((v) => !v)}
            tabIndex={-1}
            aria-label={showConfirmPassword ? 'Hide password' : 'Show password'}
            className="absolute right-3 top-1/2 -translate-y-1/2 text-faint hover:text-muted"
          >
            {showConfirmPassword ? <EyeOffIcon /> : <EyeIcon />}
          </button>
        </div>
        <label className="flex items-start gap-3 text-sm text-muted">
          <input
            type="checkbox"
            checked={consented}
            onChange={(e) => setConsented(e.target.checked)}
            required
            className="mt-1 h-4 w-4 shrink-0"
          />
          <span>{SIGNUP_CONSENT_LABEL}</span>
        </label>
        <button
          type="submit"
          disabled={submitting}
          className="w-full rounded-[10px] bg-blue-dark px-4 py-3 font-display font-extrabold text-on-accent transition-opacity hover:opacity-90 disabled:opacity-50"
        >
          {submitting ? 'Creating account…' : 'Create account'}
        </button>
        <p className="text-center text-sm text-muted">
          Already have an account?{' '}
          <Link to="/login" className="font-medium text-blue-dark hover:underline">
            Log in
          </Link>
        </p>
      </form>

    </div>
  )
}
