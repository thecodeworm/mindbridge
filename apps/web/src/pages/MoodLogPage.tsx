import { useState } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { MOOD_TAGS } from '../../../../shared/types'
import type { MoodTag } from '../../../../shared/types'
import { logMood, addJournalEntry } from '../lib/moodService'
import { updateEntry } from '../lib/historyService'
import type { EntryDetail } from '../lib/historyService'
import { moodColor } from '../lib/moodColor'

export function MoodLogPage() {
  const { user } = useAuth()
  const navigate = useNavigate()
  const location = useLocation()

  const editing = (location.state as { editing?: EntryDetail } | null)?.editing ?? null

  const [score, setScore] = useState(editing?.moodLog.mood_score ?? 5)
  const [tag, setTag] = useState<MoodTag | null>(editing?.moodLog.mood_tag ?? null)
  const [journal, setJournal] = useState(editing?.journalEntry?.body ?? '')
  const [error, setError] = useState<string | null>(null)
  const [submitting, setSubmitting] = useState(false)

  const color = moodColor(score)
  const roundedScore = Math.round(score)

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    if (!tag) { setError('Pick a mood tag before submitting.'); return }
    if (!user) return

    setError(null)
    setSubmitting(true)

    if (editing) {
      // The coping_suggestions row is 1:1 on mood_log_id and already
      // exists for this entry — editing doesn't regenerate it.
      const { error: updateError } = await updateEntry({
        moodLogId: editing.moodLog.id,
        userId: user.id,
        moodScore: roundedScore,
        moodTag: tag,
        journalBody: journal,
      })
      setSubmitting(false)
      if (updateError) { setError(updateError); return }
      navigate(`/entry/${editing.moodLog.id}`, { replace: true })
      return
    }

    const { moodLogId, error: logError } = await logMood({
      userId: user.id,
      moodScore: roundedScore,
      moodTag: tag,
    })

    if (logError || !moodLogId) {
      setError(logError ?? 'Something went wrong.')
      setSubmitting(false)
      return
    }

    if (journal.trim()) {
      const { error: journalError } = await addJournalEntry({
        moodLogId,
        userId: user.id,
        body: journal.trim(),
      })
      if (journalError) {
        setError(journalError)
        setSubmitting(false)
        return
      }
    }

    navigate('/suggestion', { state: { moodLogId, userId: user.id }, replace: true })
  }

  return (
    <div className="flex min-h-screen items-start justify-center bg-cream p-4 pt-12">
      <form
        onSubmit={handleSubmit}
        className="w-full max-w-md space-y-6 rounded-xl border border-border bg-surface p-8 shadow-sm"
      >
        <h1 className="text-2xl font-bold text-ink">
          {editing ? 'Edit entry' : 'How are you feeling?'}
        </h1>

        {error && (
          <p className="rounded-lg bg-error-tint px-3 py-2 text-sm text-error">{error}</p>
        )}

        {/* Score slider */}
        <div className="space-y-2">
          <div className="flex items-center justify-between">
            <label className="text-sm font-medium text-muted">Mood score</label>
            <span
              className="text-2xl font-bold"
              style={{ color }}
            >
              {roundedScore}
            </span>
          </div>
          <input
            type="range"
            min={1}
            max={10}
            step={0.01}
            value={score}
            onChange={(e) => setScore(Number(e.target.value))}
            className="mood-slider w-full"
          />
          <div className="flex justify-between text-xs text-faint">
            <span>1</span>
            <span>10</span>
          </div>
        </div>

        {/* Tag picker */}
        <div className="space-y-2">
          <p className="text-sm font-medium text-muted">Pick a tag</p>
          <div className="flex flex-wrap gap-2">
            {MOOD_TAGS.map((t) => (
              <button
                key={t.value}
                type="button"
                onClick={() => setTag(t.value)}
                className={[
                  'flex items-center gap-1.5 rounded-full border px-3 py-1.5 text-sm font-medium transition-colors',
                  tag === t.value
                    ? 'border-blue-dark bg-blue-tint text-blue-dark'
                    : 'border-border bg-field text-ink hover:bg-blue-tint',
                ].join(' ')}
              >
                <span>{t.emoji}</span>
                <span>{t.label}</span>
              </button>
            ))}
          </div>
        </div>

        {/* Journal */}
        <div className="space-y-1">
          <label className="text-sm font-medium text-muted" htmlFor="journal">
            Journal <span className="font-normal text-faint">(optional)</span>
          </label>
          <textarea
            id="journal"
            value={journal}
            onChange={(e) => setJournal(e.target.value)}
            maxLength={500}
            rows={4}
            placeholder="How are you feeling? (optional)"
            className="w-full resize-none rounded-lg border border-border bg-field px-3 py-2 text-ink placeholder:text-faint"
          />
          <p className="text-right text-xs text-faint">{journal.length} / 500</p>
        </div>

        <div className="flex gap-3">
          <button
            type="button"
            onClick={() => navigate(editing ? `/entry/${editing.moodLog.id}` : '/')}
            className="flex-1 rounded-lg border border-border bg-field px-3 py-2 font-medium text-ink transition-colors hover:bg-blue-tint"
          >
            Cancel
          </button>
          <button
            type="submit"
            disabled={submitting}
            className="flex-1 rounded-lg bg-blue-dark px-3 py-2 font-medium text-on-accent transition-opacity hover:opacity-90 disabled:opacity-50"
          >
            {submitting ? 'Saving…' : editing ? 'Save changes' : 'Save'}
          </button>
        </div>
      </form>
    </div>
  )
}
