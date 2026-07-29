import { useEffect, useRef, useState, type FormEvent } from 'react'
import { useNavigate } from 'react-router-dom'
import { supabase } from '../lib/supabaseClient'
import { useAuth } from '../context/AuthContext'
import { PASSWORD_HINT, validatePassword, validatePasswordConfirmation } from '../lib/validators'

type LinkState = 'pending' | 'ready' | 'expired'

export function ResetPasswordPage() {
  const navigate = useNavigate()
  const { loading, isRecoverySession, user } = useAuth()
  const [password, setPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [submitting, setSubmitting] = useState(false)
  const [done, setDone] = useState(false)

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
        <div className="w-full max-w-sm space-y-4 rounded-2xl border border-border bg-surface p-8 text-center shadow-sm">
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
      </div>
    )
  }

  if (isGoogleOnly) {
    return (
      <div className="flex min-h-screen flex-col items-center justify-center bg-cream p-4">
        {brandHeader}
        <div className="w-full max-w-sm space-y-4 rounded-2xl border border-border bg-surface p-8 text-center shadow-sm">
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
      </div>
    )
  }

  if (linkState === 'expired') {
    return (
      <div className="flex min-h-screen flex-col items-center justify-center bg-cream p-4">
        {brandHeader}
        <div className="w-full max-w-sm space-y-4 rounded-2xl border border-border bg-surface p-8 text-center shadow-sm">
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
      </div>
    )
  }

  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-cream p-4">
      {brandHeader}
      <form
        onSubmit={handleSubmit}
        className="w-full max-w-sm space-y-4 rounded-2xl border border-border bg-surface p-8 shadow-sm"
      >
        <h1 className="text-xl font-bold text-ink">Set a new password</h1>
        {error && (
          <p className="rounded-xl bg-error-tint px-4 py-2 text-sm text-error">{error}</p>
        )}
        <div className="space-y-1">
          <input
            type="password"
            placeholder="New password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
            autoComplete="new-password"
            disabled={linkState !== 'ready'}
            className="w-full rounded-full border border-border bg-field px-4 py-3 text-ink placeholder:text-faint disabled:opacity-50"
          />
          <p className="px-2 text-xs text-faint">{PASSWORD_HINT}</p>
        </div>
        <input
          type="password"
          placeholder="Confirm new password"
          value={confirmPassword}
          onChange={(e) => setConfirmPassword(e.target.value)}
          required
          autoComplete="new-password"
          disabled={linkState !== 'ready'}
          className="w-full rounded-full border border-border bg-field px-4 py-3 text-ink placeholder:text-faint disabled:opacity-50"
        />
        <button
          type="submit"
          disabled={submitting || linkState !== 'ready'}
          className="w-full rounded-full bg-blue-dark px-4 py-3 font-medium text-on-accent transition-opacity hover:opacity-90 disabled:opacity-50"
        >
          {linkState === 'pending' ? 'Verifying link…' : submitting ? 'Saving…' : 'Save new password'}
        </button>
      </form>
    </div>
  )
}
