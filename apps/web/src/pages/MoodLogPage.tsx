import { useEffect, useState } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { moodTagInfo } from '../../../../shared/types'
import type { MoodTag, MoodQuadrant, ActivityTag } from '../../../../shared/types'
import { logMood, addJournalEntry } from '../lib/moodService'
import { updateEntry } from '../lib/historyService'
import type { EntryDetail } from '../lib/historyService'
import { moodColor } from '../lib/moodColor'
import { getActivityTags, setEntryActivities } from '../lib/activityService'
import { ActivityTagPicker } from '../components/ActivityTagPicker'
import { DistortionPicker } from '../components/DistortionPicker'
import { FeltMoodSlider } from '../components/FeltMoodSlider'
import { MoodTagPicker } from '../components/MoodTagPicker'
import { CrisisChip } from '../components/CrisisChip'
import { BreathingCircle } from '../components/BreathingCircle'
import { supabase } from '../lib/supabaseClient'

interface MoodLogLocationState {
  editing?: EntryDetail
  /** Pre-fills a new entry (e.g. the mood picked during onboarding). Ignored when `editing` is set. */
  initialScore?: number
  initialTag?: MoodTag
}

export function MoodLogPage() {
  const { user } = useAuth()
  const navigate = useNavigate()
  const location = useLocation()

  const state = (location.state as MoodLogLocationState | null) ?? null
  const editing = state?.editing ?? null

  const [score, setScore] = useState(
    editing?.moodLog.mood_score ?? state?.initialScore ?? 5,
  )
  const [tag, setTag] = useState<MoodTag | null>(
    editing?.moodLog.mood_tag ?? state?.initialTag ?? null,
  )
  const [quadrant, setQuadrant] = useState<MoodQuadrant | null>(() => {
    const seedTag = editing?.moodLog.mood_tag ?? state?.initialTag
    if (!seedTag) return null
    return moodTagInfo(seedTag)?.quadrant ?? null
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

  return (
    <div className="flex min-h-screen items-start justify-center bg-cream p-4 pt-12">
      <form
        onSubmit={handleSubmit}
        className="card-lg w-full max-w-md space-y-6 p-8"
      >
        <h1 className="text-2xl font-bold text-ink">
          {editing ? 'Edit entry' : 'How are you feeling?'}
        </h1>

        {error && (
          <p className="rounded-lg bg-error-tint px-3 py-2 text-sm text-error">{error}</p>
        )}

        {/* Score */}
        <div className="space-y-1">
          <div className="flex items-center justify-between">
            <label className="text-sm font-medium text-muted">Mood score</label>
            <span className="text-2xl font-bold tabular-nums" style={{ color }}>{roundedScore}</span>
          </div>
          <FeltMoodSlider value={score} onChange={setScore} />
          <div className="flex justify-between text-xs text-faint">
            <span>1</span>
            <span>10</span>
          </div>
        </div>

        {/* Two-step mood tag picker */}
        <div className="space-y-2">
          <p className="text-sm font-medium text-muted">How would you describe it?</p>
          <MoodTagPicker
            quadrant={quadrant}
            tag={tag}
            onQuadrantChange={(q) => { setQuadrant(q); setTag(null) }}
            onTagChange={setTag}
          />
        </div>

        {/* Activity tags */}
        <ActivityTagPicker
          tags={activityTags}
          selected={selectedActivities}
          onChange={setSelectedActivities}
        />

        {tag && score <= 3 && (
          <div className="flex flex-col items-center gap-2 py-2 text-center">
            <BreathingCircle color={color} size={72} />
            <p className="text-sm text-muted">Take a breath before you write, if that helps.</p>
          </div>
        )}

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
      <CrisisChip />
    </div>
  )
}
