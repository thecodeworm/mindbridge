import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { getSavedToolkit } from '../lib/feedbackService'
import { updateSuggestionFeedback } from '../lib/feedbackService'

interface Technique {
  id: string
  mood_log_id: string
  technique_name: string
  description: string
  steps: string[]
  generated_at: string
  helpful: boolean | null
  saved: boolean
}

export function ToolkitPage() {
  const { user } = useAuth()
  const navigate = useNavigate()
  const [techniques, setTechniques] = useState<Technique[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!user) return
    getSavedToolkit(user.id).then(({ techniques, error }) => {
      setTechniques(techniques)
      setError(error)
      setLoading(false)
    })
  }, [user])

  async function unsave(moodLogId: string) {
    if (!user) return
    setTechniques((prev) => prev.filter((t) => t.mood_log_id !== moodLogId))
    await updateSuggestionFeedback(moodLogId, user.id, { saved: false })
  }

  return (
    <div>
      <h1 className="mb-6 text-3xl font-semibold text-ink">Toolkit</h1>
      <div className="space-y-3">
        {loading &&
          [0, 1, 2].map((i) => <div key={i} className="card h-28 animate-pulse" />)}

        {!loading && error && <p className="rounded-xl bg-error-tint px-4 py-3 text-ink">{error}</p>}

        {!loading && !error && techniques.length === 0 && (
          <div className="card px-6 py-12 text-center">
            <h2 className="text-xl text-ink">Keep what works</h2>
            <p className="mx-auto mt-1 max-w-sm text-muted">
              Save a technique after a check-in and it lands here, ready for the next hard moment.
            </p>
            <button
              type="button"
              onClick={() => navigate('/log')}
              className="mt-5 rounded-[10px] bg-blue-dark px-6 py-2.5 font-semibold text-on-accent hover:opacity-90"
            >
              Check in
            </button>
          </div>
        )}

        {techniques.map((t) => (
          <details key={t.id} className="card group p-5 sm:p-6">
            <summary className="flex cursor-pointer list-none items-start justify-between gap-3">
              <span className="min-w-0">
                <span className="block font-display text-xl font-black tracking-tight text-ink">{t.technique_name}</span>
                <span className="mt-1 block text-muted group-open:hidden line-clamp-2">{t.description}</span>
              </span>
              <button
                type="button"
                onClick={(e) => {
                  e.preventDefault()
                  unsave(t.mood_log_id)
                }}
                aria-label="Remove from toolkit"
                title="Remove from toolkit"
                className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full text-blue-dark hover:bg-blue-tint"
              >
                <svg viewBox="0 0 24 24" width="18" height="18" fill="currentColor" aria-hidden>
                  <path d="M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2Z" />
                </svg>
              </button>
            </summary>
            <p className="mt-1 hidden text-muted group-open:block">{t.description}</p>
            <ol className="mt-4 space-y-2.5">
              {t.steps.map((step, i) => (
                <li key={i} className="flex gap-3 text-ink">
                  <span className="tabular flex h-6 w-6 shrink-0 items-center justify-center rounded-[6px] bg-blue-dark text-xs font-bold text-on-accent">
                    {i + 1}
                  </span>
                  <span>{step}</span>
                </li>
              ))}
            </ol>
            <button
              type="button"
              onClick={() => navigate(`/entry/${t.mood_log_id}`)}
              className="mt-3 rounded-[10px] px-2 py-1 font-semibold text-blue-dark hover:bg-blue-tint"
            >
              See the check-in
            </button>
          </details>
        ))}
      </div>
    </div>
  )
}
