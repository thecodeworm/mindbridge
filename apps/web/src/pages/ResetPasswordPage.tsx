import { useEffect, useRef, useState, type FormEvent } from 'react'
import { useNavigate } from 'react-router-dom'
import { supabase } from '../lib/supabaseClient'
import { useAuth } from '../context/AuthContext'
import { PASSWORD_HINT, validatePassword, validatePasswordConfirmation } from '../lib/validators'
import { CrisisChip } from '../components/CrisisChip'

type LinkState = 'pending' | 'ready' | 'expired'

export function ResetPasswordPage() {
  const navigate = useNavigate()
  const { loading, isRecoverySession, user } = useAuth()
  const [password, setPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [submitting, setSubmitting] = useState(false)
  const [done, setDone] = useState(false)
  const [showPassword, setShowPassword] = useState(false)

  const linkState: LinkState = loading ? 'pending' : isRecoverySession ? 'ready' : 'expired'

  const isGoogleOnly = linkState === 'ready' &&
    (user?.identities ?? []).every((i: { provider: string }) => i.provider !== 'email')

  // If the user navigates away mid-recovery without setting a new password,
  // don't leave the recovery session sitting around.
  const doneRef = useRef(done)
  doneRef.current = done
  const isRecoverySessionRef = useRef(isRecoverySession)
  isRecoverySessionRef.current = isRecoverySession

  useEffect(() => {
    return () => {
      if (isRecoverySessionRef.current && !doneRef.current) {
        supabase.auth.signOut()
      }
    }
  }, [])

  async function handleSubmit(e: FormEvent) {
    e.preventDefault()
    setError(null)

    const passwordError = validatePassword(password) ?? validatePasswordConfirmation(password, confirmPassword)
    if (passwordError) {
      setError(passwordError)
      return
    }

    setSubmitting(true)
    const { error } = await supabase.auth.updateUser({ password })
    setSubmitting(false)

    if (error) {
      setError(error.message)
      return
    }

    setDone(true)
    await supabase.auth.signOut()
  }

  const brandHeader = (
    <div className="mb-8 text-center">
      <div className="text-3xl font-bold text-blue-dark">MindBridge</div>
      <p className="mt-1 text-sm text-muted">Track your mood, grow your mind.</p>
    </div>
  )

  if (done) {
    return (
      <div className="flex min-h-screen flex-col items-center justify-center bg-cream p-4">
        {brandHeader}
        <div className="card-lg w-full max-w-sm space-y-4 p-8 text-center">
          <div className="text-4xl">✅</div>
          <p className="font-medium text-ink">Password updated</p>
          <p className="text-sm text-muted">You can log in with your new password now.</p>
          <button
            onClick={() => navigate('/login')}
            className="w-full rounded-full bg-blue-dark px-4 py-3 font-medium text-on-accent transition-opacity hover:opacity-90"
          >
            Back to log in
          </button>
        </div>
        <CrisisChip />
      </div>
    )
  }

  if (isGoogleOnly) {
    return (
      <div className="flex min-h-screen flex-col items-center justify-center bg-cream p-4">
        {brandHeader}
        <div className="card-lg w-full max-w-sm space-y-4 p-8 text-center">
          <p className="font-medium text-ink">You signed up with Google</p>
          <p className="text-sm text-muted">
            There's no password to reset — just use the Google button to sign in.
          </p>
          <button
            onClick={async () => { await supabase.auth.signOut(); navigate('/login') }}
            className="w-full rounded-full bg-blue-dark px-4 py-3 font-medium text-on-accent transition-opacity hover:opacity-90"
          >
            Back to log in
          </button>
        </div>
        <CrisisChip />
      </div>
    )
  }

  if (linkState === 'expired') {
    return (
      <div className="flex min-h-screen flex-col items-center justify-center bg-cream p-4">
        {brandHeader}
        <div className="card-lg w-full max-w-sm space-y-4 p-8 text-center">
          <p className="font-medium text-ink">This link has expired</p>
          <p className="text-sm text-muted">
            Reset links only work once and expire after a while. Request a new one from the log in page.
          </p>
          <button
            onClick={() => navigate('/login')}
            className="w-full rounded-full border border-border bg-field px-4 py-3 font-medium text-ink transition-colors hover:bg-blue-tint"
          >
            Request a new link
          </button>
        </div>
        <CrisisChip />
      </div>
    )
  }

  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-cream p-4">
      {brandHeader}
      <form
        onSubmit={handleSubmit}
        className="card-lg w-full max-w-sm space-y-4 p-8"
      >
        <h1 className="text-xl font-bold text-ink">Set a new password</h1>
        {error && (
          <p className="rounded-xl bg-error-tint px-4 py-2 text-sm text-error">{error}</p>
        )}
        <div className="space-y-1">
          <div className="relative">
            <input
              type={showPassword ? 'text' : 'password'}
              placeholder="New password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              autoComplete="new-password"
              disabled={linkState !== 'ready'}
              className="w-full rounded-full border border-border bg-field px-4 py-3 pr-11 text-ink placeholder:text-faint disabled:opacity-50"
            />
            <button
              type="button"
              onClick={() => setShowPassword((v) => !v)}
              tabIndex={-1}
              aria-label={showPassword ? 'Hide password' : 'Show password'}
              className="absolute right-3 top-1/2 -translate-y-1/2 text-faint hover:text-muted"
            >
              {showPassword ? (
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17.94 17.94A10.07 10.07 0 0112 20c-7 0-11-8-11-8a18.45 18.45 0 015.06-5.94M9.9 4.24A9.12 9.12 0 0112 4c7 0 11 8 11 8a18.5 18.5 0 01-2.16 3.19m-6.72-1.07a3 3 0 11-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
              ) : (
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
              )}
            </button>
          </div>
          <p className="px-2 text-xs text-faint">{PASSWORD_HINT}</p>
        </div>
        <div className="relative">
          <input
            type={showPassword ? 'text' : 'password'}
            placeholder="Confirm new password"
            value={confirmPassword}
            onChange={(e) => setConfirmPassword(e.target.value)}
            required
            autoComplete="new-password"
            disabled={linkState !== 'ready'}
            className="w-full rounded-full border border-border bg-field px-4 py-3 pr-11 text-ink placeholder:text-faint disabled:opacity-50"
          />
          <button
            type="button"
            onClick={() => setShowPassword((v) => !v)}
            tabIndex={-1}
            aria-label={showPassword ? 'Hide password' : 'Show password'}
            className="absolute right-3 top-1/2 -translate-y-1/2 text-faint hover:text-muted"
          >
            {showPassword ? (
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17.94 17.94A10.07 10.07 0 0112 20c-7 0-11-8-11-8a18.45 18.45 0 015.06-5.94M9.9 4.24A9.12 9.12 0 0112 4c7 0 11 8 11 8a18.5 18.5 0 01-2.16 3.19m-6.72-1.07a3 3 0 11-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
            ) : (
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
            )}
          </button>
        </div>
        <button
          type="submit"
          disabled={submitting || linkState !== 'ready'}
          className="w-full rounded-full bg-blue-dark px-4 py-3 font-medium text-on-accent transition-opacity hover:opacity-90 disabled:opacity-50"
        >
          {linkState === 'pending' ? 'Verifying link…' : submitting ? 'Saving…' : 'Save new password'}
        </button>
      </form>
      <CrisisChip />
    </div>
  )
}
