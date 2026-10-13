import type { CSSProperties } from 'react'
import { useEffect, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { moodTagInfo } from '../../../../shared/types'
import { useAuth } from '../context/AuthContext'
import { deleteEntry, getEntryDetail } from '../lib/historyService'
import type { EntryDetail } from '../lib/historyService'
import { moodColor } from '../lib/moodColor'
import { updateSuggestionFeedback } from '../lib/feedbackService'
import { CrisisChip } from '../components/CrisisChip'
import { BOOKMARK, FeedbackChip, THUMB_DOWN, THUMB_UP } from '../components/FeedbackChip'

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
    <div className="min-h-screen bg-cream">
      <div className="mx-auto w-full max-w-xl space-y-4 px-4 pb-16 pt-4 sm:px-6">
        <div className="flex items-center gap-2">
          <button
            type="button"
            onClick={() => (window.history.length > 1 ? navigate(-1) : navigate('/journal'))}
            aria-label="Back"
            className="flex h-10 w-10 items-center justify-center rounded-full text-ink hover:bg-surface"
          >
            <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
              <path d="m15 18-6-6 6-6" />
            </svg>
          </button>
          <p className="flex-1 font-display text-2xl font-semibold text-ink">Entry</p>
          <CrisisChip inline />

          {!loading && !error && detail && (
            <div className="relative">
              <button
                type="button"
                onClick={() => setMenuOpen((v) => !v)}
                aria-label="Entry options"
                aria-expanded={menuOpen}
                className="flex h-10 w-10 items-center justify-center rounded-full text-lg font-bold text-muted transition-colors hover:bg-surface hover:text-ink"
              >
                ⋮
              </button>
              {menuOpen && (
                <>
                  <button type="button" aria-label="Close menu" onClick={() => setMenuOpen(false)} className="fixed inset-0 z-10 cursor-default" />
                  <div className="card-elevated absolute right-0 z-20 mt-1 w-40 overflow-hidden">
                    <button type="button" onClick={handleEdit} className="block w-full px-4 py-2 text-left text-sm font-medium text-ink transition-colors hover:bg-blue-tint">Edit</button>
                    <button type="button" onClick={() => { setMenuOpen(false); setConfirmingDelete(true) }} className="block w-full px-4 py-2 text-left text-sm font-medium text-error transition-colors hover:bg-error-tint">Delete</button>
                  </div>
                </>
              )}
            </div>
          )}
        </div>

        {confirmingDelete && (
          <div className="card space-y-3 p-5">
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
          <div className="card animate-pulse space-y-4 p-6">
            <div className="h-6 w-2/3 rounded bg-surface" />
            <div className="space-y-2"><div className="h-4 w-full rounded bg-surface" /><div className="h-4 w-5/6 rounded bg-surface" /></div>
          </div>
        )}

        {!loading && error && (
          <p className="rounded-2xl bg-error-tint px-4 py-3.5 text-ink">{error}</p>
        )}

        {!loading && !error && detail && (
          <>
            <div className="card space-y-4 p-5 sm:p-6">
              <div className="flex items-center gap-4">
                <span className="tabular flex h-14 w-14 shrink-0 items-center justify-center rounded-[10px] font-display text-2xl font-semibold" style={{ backgroundColor: moodColor(detail.moodLog.mood_score), color: '#1C1917' }}>
                  {detail.moodLog.mood_score}
                </span>
                <div>
                  <p className="font-display text-2xl font-black tracking-tight">
                    <span className="hl" style={{ '--mark': moodColor(detail.moodLog.mood_score) } as CSSProperties}>
                      {moodTagInfo(detail.moodLog.mood_tag)?.label}
                    </span>
                  </p>
                  <p className="text-sm text-muted">{formatDate(detail.moodLog.logged_at)}</p>
                </div>
              </div>

              {detail.activities.length > 0 && (
                <div className="flex flex-wrap gap-1.5">
                  {detail.activities.map((a) => (
                    <span key={a.id} className="rounded-lg bg-surface px-3 py-1 text-sm text-ink">
                      {a.emoji} {a.label}
                    </span>
                  ))}
                </div>
              )}

              {detail.journalEntry && (
                <div className="space-y-1 border-t border-border pt-4">
                  <p className="label">Journal</p>
                  <p className="whitespace-pre-wrap text-lg leading-relaxed text-ink">{detail.journalEntry.body}</p>
                </div>
              )}
            </div>

            {showCrisis && (
              <Link
                to="/help"
                className="block rounded-xl border border-terra bg-terra-tint px-4 py-3.5 text-terra-dark transition-colors hover:bg-terra-tint/70"
              >
                You don't have to carry this alone. Call or text 988, or text HOME to 741741. Tap for more.
              </Link>
            )}

            {suggestion && (
              <div className="card space-y-4 p-5 sm:p-6">
                <h1 className="text-3xl text-ink">{suggestion.technique_name}</h1>
                <p className="leading-relaxed text-muted">{suggestion.description}</p>
                <ol className="space-y-3">
                  {suggestion.steps.slice(0, 3).map((step, i) => (
                    <li key={i} className="flex gap-3">
                      <span className="tabular flex h-7 w-7 shrink-0 items-center justify-center rounded-[7px] bg-blue-dark text-sm font-bold text-on-accent">
                        {i + 1}
                      </span>
                      <span className="pt-0.5 leading-relaxed text-ink">{step}</span>
                    </li>
                  ))}
                </ol>
                <div className="flex flex-wrap gap-2 pt-2">
                  <FeedbackChip active={helpful === true} onClick={() => toggleHelpful(true)} icon={THUMB_UP} label="Helpful" />
                  <FeedbackChip active={helpful === false} onClick={() => toggleHelpful(false)} icon={THUMB_DOWN} label="Not for me" />
                  <FeedbackChip active={saved} onClick={toggleSaved} icon={BOOKMARK} label={saved ? 'In your toolkit' : 'Save to toolkit'} />
                </div>
              </div>
            )}

            {!suggestion && (
              <div className="card p-6">
                <p className="text-muted">No coping suggestion was saved for this entry.</p>
              </div>
            )}
          </>
        )}
      </div>
    </div>
  )
}
