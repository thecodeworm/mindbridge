import { useEffect, useRef, useState } from 'react'
import type { CSSProperties } from 'react'
import { Link, useLocation, useNavigate } from 'react-router-dom'
import type { SuggestionResponse } from '../../../../shared/types'
import { generateSuggestion } from '../lib/suggestionService'
import { updateSuggestionFeedback } from '../lib/feedbackService'
import { CrisisChip } from '../components/CrisisChip'
import { BOOKMARK, FeedbackChip, THUMB_DOWN, THUMB_UP } from '../components/FeedbackChip'
import { BreathingCircle } from '../components/BreathingCircle'
import { moodColor } from '../lib/moodColor'

interface SuggestionLocationState {
  moodLogId: string
  userId: string
  moodScore?: number
}

export function SuggestionPage() {
  const location = useLocation()
  const navigate = useNavigate()
  const state = location.state as SuggestionLocationState | null

  const [suggestion, setSuggestion] = useState<SuggestionResponse | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [helpful, setHelpful] = useState<boolean | null>(null)
  const [saved, setSaved] = useState(false)
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
    if (!state) { navigate('/', { replace: true }); return }
    if (startedRef.current) return
    startedRef.current = true
    load(state.moodLogId, state.userId)
  }, [])

  async function toggleHelpful(value: boolean) {
    if (!state) return
    const next = helpful === value ? null : value
    setHelpful(next)
    await updateSuggestionFeedback(state.moodLogId, state.userId, { helpful: next })
  }

  async function toggleSaved() {
    if (!state) return
    const next = !saved
    setSaved(next)
    await updateSuggestionFeedback(state.moodLogId, state.userId, { saved: next })
  }

  if (!state) return null

  const tone = moodColor(state.moodScore ?? 5.5)
  const done = () => navigate('/', { replace: true })

  return (
    <div className="min-h-screen bg-cream">
      <div className="mx-auto flex w-full max-w-xl items-center justify-between px-4 pt-4 sm:px-6">
        <button
          type="button"
          onClick={done}
          aria-label="Close"
          className="flex h-10 w-10 items-center justify-center rounded-full text-ink hover:bg-surface"
        >
          <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden>
            <path d="M18 6 6 18M6 6l12 12" />
          </svg>
        </button>
        <CrisisChip inline />
      </div>

      <div className="mx-auto w-full max-w-xl px-4 pb-16 pt-4 sm:px-6">
        {loading && (
          <div className="flex min-h-[60vh] flex-col items-center justify-center text-center">
            <BreathingCircle
              colors={state.moodScore != null ? undefined : [moodColor(1), moodColor(5.5), moodColor(10)]}
              color={state.moodScore != null ? tone : undefined}
              size={180}
            />
            <h1 className="mt-8 text-2xl font-semibold text-ink">Breathe with the circle</h1>
            <p className="mt-2 text-lg text-muted">Finding one small thing that could help right now.</p>
          </div>
        )}

        {!loading && error && (
          <div className="pt-8">
            <h1 className="text-2xl font-semibold text-ink">Your check-in is saved</h1>
            <p className="mt-2 text-lg leading-relaxed text-muted">{error}</p>
            <div className="mt-8 flex flex-col gap-3 sm:flex-row">
              <button type="button" onClick={() => load(state.moodLogId, state.userId)} className="rounded-[10px] bg-blue-dark px-6 py-3 font-semibold text-on-accent hover:opacity-90">
                Try again
              </button>
              <button type="button" onClick={done} className="rounded-[10px] border border-border bg-card px-6 py-3 font-semibold text-ink hover:bg-blue-tint">
                Back to Today
              </button>
            </div>
          </div>
        )}

        {!loading && !error && suggestion && (
          <div className="animate-step-enter">
            {suggestion.show_crisis_resources && (
              <Link
                to="/help"
                className="mb-8 flex items-start gap-3 rounded-xl border border-terra bg-terra-tint p-4 text-terra-dark transition-colors hover:bg-terra-tint/70"
              >
                <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="mt-0.5 shrink-0" aria-hidden>
                  <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" />
                </svg>
                <span>
                  <span className="block font-semibold">You don't have to carry this alone</span>
                  <span className="block">Call or text 988 any time, or text HOME to 741741. Tap for more ways to reach someone now.</span>
                </span>
              </Link>
            )}

            <p className="label">Try this now</p>
            <h1 className="mt-2 text-4xl text-ink sm:text-5xl">
              <span className="hl" style={{ '--mark': tone } as CSSProperties}>{suggestion.technique_name}</span>
            </h1>
            <p className="mt-3 text-lg leading-relaxed text-muted">{suggestion.description}</p>

            <ol className="card mt-6 space-y-4 p-5 sm:p-6">
              {suggestion.steps.slice(0, 3).map((step, i) => (
                <li key={i} className="flex gap-3.5">
                  <span
                    className="tabular flex h-8 w-8 shrink-0 items-center justify-center rounded-[7px] bg-blue-dark font-bold text-on-accent"
                  >
                    {i + 1}
                  </span>
                  <span className="pt-1 text-lg leading-relaxed text-ink">{step}</span>
                </li>
              ))}
            </ol>

            <p className="label mt-8">Did this help?</p>
            <div className="mt-3 flex flex-wrap gap-2">
              <FeedbackChip active={helpful === true} onClick={() => toggleHelpful(true)} icon={THUMB_UP} label="Helpful" />
              <FeedbackChip active={helpful === false} onClick={() => toggleHelpful(false)} icon={THUMB_DOWN} label="Not for me" />
              <FeedbackChip active={saved} onClick={toggleSaved} icon={BOOKMARK} label={saved ? 'In your toolkit' : 'Save to toolkit'} />
            </div>

            <button type="button" onClick={done} className="mt-10 w-full rounded-[10px] bg-blue-dark px-6 py-3.5 font-display text-lg font-extrabold text-on-accent hover:opacity-90">
              Done
            </button>
          </div>
        )}
      </div>
    </div>
  )
}
