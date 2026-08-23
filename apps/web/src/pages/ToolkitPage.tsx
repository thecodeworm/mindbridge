import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { getSavedToolkit } from '../lib/feedbackService'
import { updateSuggestionFeedback } from '../lib/feedbackService'
import { CrisisChip } from '../components/CrisisChip'

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
    <div className="min-h-screen bg-cream p-4 pb-24 sm:p-6">
      <div className="mx-auto w-full max-w-2xl space-y-6">
        <div className="flex items-center gap-3">
          <button
            type="button"
            onClick={() => navigate('/')}
            className="text-sm font-medium text-muted transition-colors hover:text-ink"
          >
            ← Back
          </button>
          <h1 className="text-2xl font-bold text-ink">My toolkit</h1>
        </div>

        {loading && (
          <div className="space-y-3">
            {[0, 1, 2].map((i) => (
              <div key={i} className="h-28 animate-pulse rounded-xl border border-border bg-surface" />
            ))}
          </div>
        )}

        {!loading && error && (
          <p className="rounded-lg bg-error-tint px-3 py-2 text-sm text-error">{error}</p>
        )}

        {!loading && !error && techniques.length === 0 && (
          <div className="card p-8 text-center">
            <p className="text-muted">No saved techniques yet.</p>
            <p className="mt-1 text-sm text-faint">
              Bookmark techniques from your coping suggestions to build your toolkit.
            </p>
          </div>
        )}

        {techniques.map((t) => (
          <div key={t.id} className="card space-y-3 p-6">
            <div className="flex items-start justify-between gap-3">
              <h2 className="text-lg font-bold text-ink">{t.technique_name}</h2>
              <button
                type="button"
                onClick={() => unsave(t.mood_log_id)}
                title="Remove from toolkit"
                className="shrink-0 text-xl text-caution transition-opacity hover:opacity-70"
              >
                🔖
              </button>
            </div>
            <p className="text-sm text-muted">{t.description}</p>
            <ol className="list-decimal space-y-1.5 pl-5 text-sm text-ink">
              {t.steps.map((step, i) => <li key={i}>{step}</li>)}
            </ol>
            <button
              type="button"
              onClick={() => navigate(`/entry/${t.mood_log_id}`)}
              className="text-xs text-muted transition-colors hover:text-ink"
            >
              View original entry →
            </button>
          </div>
        ))}
      </div>
      <CrisisChip />
    </div>
  )
}
