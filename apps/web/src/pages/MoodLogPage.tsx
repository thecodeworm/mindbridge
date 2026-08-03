import { useEffect, useState } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { MOOD_TAGS, MOOD_QUADRANTS, moodTagInfo } from '../../../../shared/types'
import type { MoodTag, MoodQuadrant, ActivityTag } from '../../../../shared/types'
import { logMood, addJournalEntry } from '../lib/moodService'
import { updateEntry } from '../lib/historyService'
import type { EntryDetail } from '../lib/historyService'
import { moodColor } from '../lib/moodColor'
import { getActivityTags, setEntryActivities } from '../lib/activityService'
import { ActivityTagPicker } from '../components/ActivityTagPicker'
import { DistortionPicker } from '../components/DistortionPicker'
import { supabase } from '../lib/supabaseClient'

function tagsByQuadrant(q: MoodQuadrant) {
  return MOOD_TAGS.filter((t) => t.quadrant === q)
}

const chipClass = (selected: boolean) =>
  [
    'flex items-center gap-1.5 rounded-full border px-3 py-1.5 text-sm font-medium transition-colors',
    selected
      ? 'border-blue-dark bg-blue-tint text-blue-dark'
      : 'border-border bg-field text-ink hover:bg-blue-tint',
  ].join(' ')

export function MoodLogPage() {
  const { user } = useAuth()
  const navigate = useNavigate()
  const location = useLocation()

  const editing = (location.state as { editing?: EntryDetail } | null)?.editing ?? null

  const [score, setScore] = useState(editing?.moodLog.mood_score ?? 5)
  const [tag, setTag] = useState<MoodTag | null>(editing?.moodLog.mood_tag ?? null)
  const [quadrant, setQuadrant] = useState<MoodQuadrant | null>(() => {
    if (!editing?.moodLog.mood_tag) return null
    return moodTagInfo(editing.moodLog.mood_tag)?.quadrant ?? null
  })
  const [journal, setJournal] = useState(editing?.journalEntry?.body ?? '')
  const [activityTags, setActivityTags] = useState<ActivityTag[]>([])
  const [selectedActivities, setSelectedActivities] = useState<string[]>(
    editing?.activities?.map((a) => a.id) ?? [],
  )
  const [showDistortions, setShowDistortions] = useState(false)
  const [distortionsDone, setDistortionsDone] = useState(false)
  const [distortions, setDistortions] = useState<string[]>([])
  const [reframe, setReframe] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [submitting, setSubmitting] = useState(false)

  const color = moodColor(score)
  const roundedScore = Math.round(score)

  useEffect(() => {
    getActivityTags().then(({ tags }) => setActivityTags(tags))
    if (editing?.activities) setSelectedActivities(editing.activities.map((a) => a.id))
  }, [])

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    if (!tag) { setError('Pick a mood tag before submitting.'); return }
    if (!user) return

    setError(null)
    setSubmitting(true)

    if (editing) {
      const { error: updateError } = await updateEntry({
        moodLogId: editing.moodLog.id,
        userId: user.id,
        moodScore: roundedScore,
        moodTag: tag,
        journalBody: journal,
      })
      if (!updateError) {
        await setEntryActivities(editing.moodLog.id, user.id, selectedActivities)
        if (distortions.length > 0 && editing.journalEntry?.id) {
          await supabase
            .from('journal_entries')
            .update({ distortions, reframe: reframe || null })
            .eq('id', editing.journalEntry.id)
            .eq('user_id', user.id)
        }
      }
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
      // Save distortions if selected
      if (distortions.length > 0) {
        const { data: jEntry } = await supabase
          .from('journal_entries')
          .select('id')
          .eq('mood_log_id', moodLogId)
          .eq('user_id', user.id)
          .maybeSingle()
        if (jEntry) {
          await supabase
            .from('journal_entries')
            .update({ distortions, reframe: reframe || null })
            .eq('id', jEntry.id)
        }
      }
    }

    if (selectedActivities.length > 0) {
      await setEntryActivities(moodLogId, user.id, selectedActivities)
    }

    navigate('/suggestion', { state: { moodLogId, userId: user.id }, replace: true })
  }

  const tagsForQuadrant = quadrant ? tagsByQuadrant(quadrant) : []

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

        {/* Score */}
        <div className="space-y-2">
          <div className="flex items-center justify-between">
            <label className="text-sm font-medium text-muted">Mood score</label>
            <span className="text-2xl font-bold" style={{ color }}>{roundedScore}</span>
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

        {/* Two-step mood tag picker */}
        <div className="space-y-2">
          <p className="text-sm font-medium text-muted">How would you describe it?</p>
          {quadrant === null ? (
            <div className="grid grid-cols-2 gap-2">
              {MOOD_QUADRANTS.map((q) => (
                <button
                  key={q.value}
                  type="button"
                  onClick={() => { setQuadrant(q.value); setTag(null) }}
                  className="flex flex-col items-start gap-1 rounded-xl border border-border bg-field p-3 text-left transition-colors hover:bg-blue-tint"
                >
                  <span className="text-lg">{q.emoji}</span>
                  <span className="text-xs font-medium text-ink">{q.label}</span>
                </button>
              ))}
            </div>
          ) : (
            <div className="space-y-2">
              <button
                type="button"
                onClick={() => { setQuadrant(null); setTag(null) }}
                className="text-xs text-muted transition-colors hover:text-ink"
              >
                ← Change
              </button>
              <div className="flex flex-wrap gap-2">
                {tagsForQuadrant.map((t) => (
                  <button
                    key={t.value}
                    type="button"
                    onClick={() => setTag(t.value)}
                    className={chipClass(tag === t.value)}
                  >
                    <span>{t.emoji}</span>
                    <span>{t.label}</span>
                  </button>
                ))}
              </div>
            </div>
          )}
        </div>

        {/* Activity tags */}
        <ActivityTagPicker
          tags={activityTags}
          selected={selectedActivities}
          onChange={setSelectedActivities}
        />

        {/* Journal */}
        <div className="space-y-1">
          <label className="text-sm font-medium text-muted" htmlFor="journal">
            Journal <span className="font-normal text-faint">(optional)</span>
          </label>
          <textarea
            id="journal"
            value={journal}
            onChange={(e) => { setJournal(e.target.value); setDistortionsDone(false) }}
            maxLength={500}
            rows={4}
            placeholder="How are you feeling? (optional)"
            className="w-full resize-none rounded-lg border border-border bg-field px-3 py-2 text-ink placeholder:text-faint"
          />
          <p className="text-right text-xs text-faint">{journal.length} / 500</p>
        </div>

        {/* Cognitive distortion picker — shown when journal has text and not yet done */}
        {journal.trim().length > 0 && !distortionsDone && !showDistortions && (
          <button
            type="button"
            onClick={() => setShowDistortions(true)}
            className="text-sm text-muted transition-colors hover:text-ink"
          >
            ✦ Notice any thinking traps? (optional)
          </button>
        )}

        {showDistortions && !distortionsDone && (
          <DistortionPicker
            onDone={(d, r) => {
              setDistortions(d)
              setReframe(r)
              setDistortionsDone(true)
              setShowDistortions(false)
            }}
            onSkip={() => setShowDistortions(false)}
          />
        )}

        {distortionsDone && distortions.length > 0 && (
          <p className="text-xs text-success">
            ✓ Reframe saved ({distortions.length} thinking trap{distortions.length > 1 ? 's' : ''} noted)
          </p>
        )}

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
