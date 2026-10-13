import { useEffect, useState } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { moodTagInfo } from '../../../../shared/types'
import type { MoodTag, MoodQuadrant, ActivityTag } from '../../../../shared/types'
import { logMood, addJournalEntry } from '../lib/moodService'
import { updateEntry } from '../lib/historyService'
import type { EntryDetail } from '../lib/historyService'
import { moodColor, moodWord } from '../lib/moodColor'
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
    if (!tag) { setError("Pick the word that fits best, then you're set."); return }
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

    navigate('/suggestion', { state: { moodLogId, userId: user.id, moodScore: Math.round(score) }, replace: true })
  }

  const cancelTo = editing ? `/entry/${editing.moodLog.id}` : '/'

  return (
    <div className="min-h-screen bg-cream">
      <form onSubmit={handleSubmit} className="mx-auto w-full max-w-xl px-4 pb-32 sm:px-6">
        <div className="flex items-center gap-2 pt-4">
          <button
            type="button"
            onClick={() => navigate(cancelTo)}
            aria-label="Cancel"
            className="flex h-10 w-10 items-center justify-center rounded-full text-ink hover:bg-surface"
          >
            <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden>
              <path d="M18 6 6 18M6 6l12 12" />
            </svg>
          </button>
          <h1 className="flex-1 text-2xl font-semibold text-ink">{editing ? 'Edit entry' : 'Check in'}</h1>
          <CrisisChip inline />
        </div>

        {error && <p className="mt-4 rounded-2xl bg-error-tint px-4 py-3 text-ink">{error}</p>}

        {/* Score */}
        <section className="card mt-6 rounded-[20px] px-5 pb-4 pt-5 text-center">
          <p className="font-medium text-muted">How are you feeling?</p>
          <p className="mt-1 flex items-baseline justify-center gap-2.5">
            <span className="tabular font-display text-6xl font-semibold text-ink">{roundedScore}</span>
            <span className="font-display text-2xl" style={{ color: `color-mix(in srgb, ${color} 55%, var(--ink))` }}>
              {moodWord(score)}
            </span>
          </p>
          <div className="mt-3">
            <FeltMoodSlider value={score} onChange={setScore} />
          </div>
          <div className="flex justify-between text-sm text-muted">
            <span>Heavy</span>
            <span>Great</span>
          </div>
        </section>

        {/* Two-step mood tag picker */}
        <section className="mt-8 space-y-3">
          <h2 className="font-body text-lg font-semibold text-ink">Which word fits?</h2>
          <MoodTagPicker
            quadrant={quadrant}
            tag={tag}
            onQuadrantChange={(q) => { setQuadrant(q); setTag(null) }}
            onTagChange={(t) => { setTag(t); setError(null) }}
          />
        </section>

        {/* Activity tags */}
        <section className="mt-8 space-y-3">
          <div>
            <h2 className="font-body text-lg font-semibold text-ink">What were you up to?</h2>
            <p className="text-muted">Optional. Helps spot patterns over time.</p>
          </div>
          <ActivityTagPicker
            tags={activityTags}
            selected={selectedActivities}
            onChange={setSelectedActivities}
          />
        </section>

        {tag && score <= 3 && (
          <div className="mt-8 flex flex-col items-center gap-2 text-center">
            <BreathingCircle color={color} size={72} />
            <p className="text-muted">Take a breath before you write, if that helps.</p>
          </div>
        )}

        {/* Journal */}
        <section className="mt-8 space-y-3">
          <div>
            <label className="font-body text-lg font-semibold text-ink" htmlFor="journal">
              What's on your mind?
            </label>
            <p className="text-muted">Optional. Only you can see this.</p>
          </div>
          <textarea
            id="journal"
            value={journal}
            onChange={(e) => { setJournal(e.target.value); setDistortionsDone(false) }}
            maxLength={500}
            rows={4}
            placeholder="A sentence or two is plenty."
            className="w-full resize-none rounded-2xl border border-border bg-field px-4 py-3 text-ink placeholder:text-faint focus:border-blue-dark"
          />
          <p className="tabular text-right text-sm text-faint">{journal.length} / 500</p>

          {/* Cognitive distortion picker — shown when journal has text and not yet done */}
          {journal.trim().length > 0 && !distortionsDone && !showDistortions && (
            <button
              type="button"
              onClick={() => setShowDistortions(true)}
              className="rounded-full border border-border bg-card px-4 py-2 font-semibold text-ink hover:bg-blue-tint"
            >
              Notice any thinking traps? (optional)
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
            <p className="text-sm text-success">
              ✓ Reframe saved ({distortions.length} thinking trap{distortions.length > 1 ? 's' : ''} noted)
            </p>
          )}
        </section>

        <div className="fixed inset-x-0 bottom-0 z-20 border-t border-border bg-cream/95 pb-[env(safe-area-inset-bottom)] backdrop-blur">
          <div className="mx-auto max-w-xl px-4 py-3 sm:px-6">
            <button
              type="submit"
              disabled={submitting}
              className="w-full rounded-full bg-blue-dark px-6 py-3.5 font-semibold text-on-accent transition-opacity hover:opacity-90 disabled:opacity-50"
            >
              {submitting ? 'Saving…' : editing ? 'Save changes' : 'Get my technique'}
            </button>
          </div>
        </div>
      </form>
    </div>
  )
}
