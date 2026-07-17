import { useEffect, useRef, useState } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'
import type { SuggestionResponse } from '../../../../shared/types'
import { generateSuggestion } from '../lib/suggestionService'

interface SuggestionLocationState {
  moodLogId: string
  userId: string
}

export function SuggestionPage() {
  const location = useLocation()
  const navigate = useNavigate()
  const state = location.state as SuggestionLocationState | null

  const [suggestion, setSuggestion] = useState<SuggestionResponse | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const startedRef = useRef(false)

  async function load(moodLogId: string, userId: string) {
    setLoading(true)
    setError(null)
    const { suggestion, error } = await generateSuggestion({ moodLogId, userId })
    setSuggestion(suggestion)
    setError(error)
    setLoading(false)
  }

  useEffect(() => {
    if (!state) {
      navigate('/', { replace: true })
      return
    }
    if (startedRef.current) return
    startedRef.current = true
    load(state.moodLogId, state.userId)
  }, [])

  if (!state) return null

  return (
    <div className="flex min-h-screen items-start justify-center bg-cream p-4 pt-12">
      <div className="w-full max-w-md space-y-4">
        {loading && (
          <div className="animate-pulse space-y-4 rounded-xl border border-border bg-surface p-8 shadow-sm">
            <div className="h-6 w-2/3 rounded bg-field" />
            <div className="space-y-2">
              <div className="h-4 w-full rounded bg-field" />
              <div className="h-4 w-5/6 rounded bg-field" />
            </div>
            <div className="space-y-2 pt-2">
              <div className="h-4 w-full rounded bg-border" />
              <div className="h-4 w-full rounded bg-border" />
              <div className="h-4 w-3/4 rounded bg-border" />
            </div>
          </div>
        )}

        {!loading && error && (
          <div className="space-y-4 rounded-xl border border-border bg-surface p-8 shadow-sm">
            <p className="rounded-lg bg-error-tint px-3 py-2 text-sm text-error">{error}</p>
            <p className="text-sm text-muted">
              Your mood was saved — you can try generating a suggestion again.
            </p>
            <div className="flex gap-3">
              <button
                type="button"
                onClick={() => navigate('/', { replace: true })}
                className="flex-1 rounded-lg border border-border bg-field px-3 py-2 font-medium text-ink transition-colors hover:bg-blue-tint"
              >
                Back home
              </button>
              <button
                type="button"
                onClick={() => load(state.moodLogId, state.userId)}
                className="flex-1 rounded-lg bg-blue-dark px-3 py-2 font-medium text-on-accent transition-opacity hover:opacity-90"
              >
                Try again
              </button>
            </div>
          </div>
        )}

        {!loading && !error && suggestion && (
          <>
            {suggestion.show_crisis_resources && (
              <div className="rounded-lg border border-terra bg-terra-tint px-4 py-3 text-sm text-terra-dark">
                If you're in crisis, you're not alone — call or text 988, or text HOME to 741741.
              </div>
            )}

            <div className="space-y-4 rounded-xl border border-border bg-surface p-8 shadow-sm">
              <h1 className="text-2xl font-bold text-ink">{suggestion.technique_name}</h1>
              <p className="text-muted">{suggestion.description}</p>
              <ol className="list-decimal space-y-2 pl-5 text-ink">
                {suggestion.steps.slice(0, 3).map((step, i) => (
                  <li key={i}>{step}</li>
                ))}
              </ol>
              <button
                type="button"
                onClick={() => navigate('/', { replace: true })}
                className="w-full rounded-lg bg-blue-dark px-3 py-2 font-medium text-on-accent transition-opacity hover:opacity-90"
              >
                Done
              </button>
            </div>
          </>
        )}
      </div>
    </div>
  )
}
