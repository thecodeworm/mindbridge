import { useEffect, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { moodTagInfo } from '../../../../shared/types'
import { useAuth } from '../context/AuthContext'
import { deleteEntry, getEntryDetail } from '../lib/historyService'
import type { EntryDetail } from '../lib/historyService'
import { moodColor } from '../lib/moodColor'
import { updateSuggestionFeedback } from '../lib/feedbackService'
import { CrisisChip } from '../components/CrisisChip'

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString(undefined, {
    weekday: 'long',
    month: 'long',
    day: 'numeric',
    year: 'numeric',
  })
}

export function EntryDetailPage() {
  const { moodLogId } = useParams<{ moodLogId: string }>()
  const { user } = useAuth()
  const navigate = useNavigate()

  const [detail, setDetail] = useState<EntryDetail | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [menuOpen, setMenuOpen] = useState(false)
  const [confirmingDelete, setConfirmingDelete] = useState(false)
  const [deleting, setDeleting] = useState(false)
  const [deleteError, setDeleteError] = useState<string | null>(null)
  // Optimistic feedback state
  const [helpful, setHelpful] = useState<boolean | null>(null)
  const [saved, setSaved] = useState(false)

  useEffect(() => {
    if (!moodLogId || !user) return
    let cancelled = false
    setLoading(true)
    getEntryDetail(moodLogId, user.id).then(({ detail, error }) => {
      if (cancelled) return
      setDetail(detail)
      setError(error)
      setHelpful(detail?.copingSuggestion?.helpful ?? null)
      setSaved(detail?.copingSuggestion?.saved ?? false)
      setLoading(false)
    })
    return () => { cancelled = true }
  }, [moodLogId, user])

  function handleEdit() {
    setMenuOpen(false)
    navigate('/log', { state: { editing: detail } })
  }

  async function handleConfirmDelete() {
    if (!moodLogId || !user) return
    setDeleting(true)
    setDeleteError(null)
    const { error } = await deleteEntry(moodLogId, user.id)
    if (error) { setDeleting(false); setDeleteError(error); return }
    navigate('/')
  }

  async function toggleHelpful(value: boolean) {
    if (!moodLogId || !user) return
    const next = helpful === value ? null : value
    setHelpful(next)
    await updateSuggestionFeedback(moodLogId, user.id, { helpful: next })
  }

  async function toggleSaved() {
    if (!moodLogId || !user) return
    const next = !saved
    setSaved(next)
    await updateSuggestionFeedback(moodLogId, user.id, { saved: next })
  }

  const suggestion = detail?.copingSuggestion
  const showCrisis = suggestion && (suggestion.crisis_signal || (detail?.moodLog.mood_score ?? 11) <= 2)

  return (
    <div className="flex min-h-screen items-start justify-center bg-cream p-4 pt-12">
      <div className="w-full max-w-md space-y-4">
        <div className="flex items-center justify-between">
          <button
            type="button"
            onClick={() => navigate('/')}
            className="text-sm font-medium text-muted transition-colors hover:text-ink"
          >
            ← Back to history
          </button>

          {!loading && !error && detail && (
            <div className="relative">
              <button
                type="button"
                onClick={() => setMenuOpen((v) => !v)}
                aria-label="Entry options"
                aria-expanded={menuOpen}
                className="flex h-8 w-8 items-center justify-center rounded-full text-lg font-bold text-muted transition-colors hover:bg-blue-tint hover:text-ink"
              >
                ⋮
              </button>
              {menuOpen && (
                <>
                  <button type="button" aria-label="Close menu" onClick={() => setMenuOpen(false)} className="fixed inset-0 z-10 cursor-default" />
                  <div className="absolute right-0 z-20 mt-1 w-36 overflow-hidden rounded-lg border border-border bg-surface shadow-md">
                    <button type="button" onClick={handleEdit} className="block w-full px-4 py-2 text-left text-sm font-medium text-ink transition-colors hover:bg-blue-tint">Edit</button>
                    <button type="button" onClick={() => { setMenuOpen(false); setConfirmingDelete(true) }} className="block w-full px-4 py-2 text-left text-sm font-medium text-error transition-colors hover:bg-error-tint">Delete</button>
                  </div>
                </>
              )}
            </div>
          )}
        </div>

        {confirmingDelete && (
          <div className="space-y-3 rounded-xl border border-border bg-surface p-4 shadow-sm">
            <p className="text-sm font-medium text-ink">Delete this entry?</p>
            <p className="text-sm text-muted">This removes the mood log, journal entry, and coping suggestion. This can't be undone.</p>
            {deleteError && <p className="rounded-lg bg-error-tint px-3 py-2 text-sm text-error">{deleteError}</p>}
            <div className="flex gap-3">
              <button type="button" onClick={() => { setConfirmingDelete(false); setDeleteError(null) }} disabled={deleting} className="flex-1 rounded-lg border border-border bg-field px-3 py-2 text-sm font-medium text-ink transition-colors hover:bg-blue-tint disabled:opacity-50">Cancel</button>
              <button type="button" onClick={handleConfirmDelete} disabled={deleting} className="flex-1 rounded-lg border border-error px-3 py-2 text-sm font-medium text-error transition-colors hover:bg-error-tint disabled:opacity-50">{deleting ? 'Deleting…' : 'Delete'}</button>
            </div>
          </div>
        )}

        {loading && (
          <div className="animate-pulse space-y-4 card p-8">
            <div className="h-6 w-2/3 rounded bg-field" />
            <div className="space-y-2"><div className="h-4 w-full rounded bg-field" /><div className="h-4 w-5/6 rounded bg-field" /></div>
          </div>
        )}

        {!loading && error && (
          <div className="card p-8">
            <p className="rounded-lg bg-error-tint px-3 py-2 text-sm text-error">{error}</p>
          </div>
        )}

        {!loading && !error && detail && (
          <>
            <div className="space-y-4 card p-8">
              <div className="flex items-center gap-3">
                <span className="flex h-12 w-12 shrink-0 items-center justify-center rounded-full text-lg font-bold" style={{ backgroundColor: moodColor(detail.moodLog.mood_score), color: '#1C1917' }}>
                  {detail.moodLog.mood_score}
                </span>
                <div>
                  <p className="font-medium text-ink">
                    {moodTagInfo(detail.moodLog.mood_tag)?.emoji} {moodTagInfo(detail.moodLog.mood_tag)?.label}
                  </p>
                  <p className="text-sm text-muted">{formatDate(detail.moodLog.logged_at)}</p>
                </div>
              </div>

              {detail.activities.length > 0 && (
                <div className="flex flex-wrap gap-1.5">
                  {detail.activities.map((a) => (
                    <span key={a.id} className="rounded-full border border-border bg-field px-2.5 py-1 text-xs text-muted">
                      {a.emoji} {a.label}
                    </span>
                  ))}
                </div>
              )}

              {detail.journalEntry && (
                <div className="space-y-1 border-t border-border pt-4">
                  <p className="text-sm font-medium text-muted">Journal</p>
                  <p className="whitespace-pre-wrap text-ink">{detail.journalEntry.body}</p>
                </div>
              )}
            </div>

            {showCrisis && (
              <a
                href="/help"
                className="block rounded-lg border border-terra bg-terra-tint px-4 py-3 text-sm text-terra-dark transition-colors hover:bg-terra"
              >
                If you're in crisis, you're not alone — call or text 988, or text HOME to 741741. →
              </a>
            )}

            {suggestion && (
              <div className="space-y-4 card p-8">
                <div className="flex items-start justify-between gap-3">
                  <h1 className="text-2xl font-bold text-ink">{suggestion.technique_name}</h1>
                  <button type="button" onClick={toggleSaved} title={saved ? 'Remove from toolkit' : 'Save to toolkit'} className="shrink-0 text-xl transition-opacity hover:opacity-70">
                    {saved ? '🔖' : '🏷️'}
                  </button>
                </div>
                <p className="text-muted">{suggestion.description}</p>
                <ol className="list-decimal space-y-2 pl-5 text-ink">
                  {suggestion.steps.slice(0, 3).map((step, i) => <li key={i}>{step}</li>)}
                </ol>

                <div className="flex items-center gap-3 border-t border-border pt-4">
                  <p className="text-sm text-muted">Was this helpful?</p>
                  <button type="button" onClick={() => toggleHelpful(true)} className={`rounded-lg border px-3 py-1.5 text-sm transition-colors ${helpful === true ? 'border-success bg-success-tint text-success' : 'border-border bg-field text-ink hover:bg-blue-tint'}`}>
                    👍 Yes
                  </button>
                  <button type="button" onClick={() => toggleHelpful(false)} className={`rounded-lg border px-3 py-1.5 text-sm transition-colors ${helpful === false ? 'border-error bg-error-tint text-error' : 'border-border bg-field text-ink hover:bg-blue-tint'}`}>
                    👎 No
                  </button>
                </div>
              </div>
            )}

            {!suggestion && (
              <div className="card p-8">
                <p className="text-sm text-muted">No coping suggestion was saved for this entry.</p>
              </div>
            )}
          </>
        )}
      </div>
      <CrisisChip />
    </div>
  )
}
