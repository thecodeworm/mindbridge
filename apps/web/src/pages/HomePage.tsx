import { useEffect, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { getMoodLogsInRange } from '../lib/moodService'
import { getHistory } from '../lib/historyService'
import type { HistoryEntry } from '../lib/historyService'
import type { MoodLog } from '../../../../shared/types'
import { MOOD_TAGS } from '../../../../shared/types'
import { HistoryRow } from '../components/HistoryList'
import { StreakBadge } from '../components/StreakBadge'
import { moodColor, moodWord } from '../lib/moodColor'
import { onMoodDataChanged } from '../lib/dataEvents'
import { clearPendingCheckin, getPendingCheckin } from '../core/onboardingState'

const QUICK_SCORES = [2, 4, 6, 8, 10]

function greeting(): string {
  const h = new Date().getHours()
  if (h < 5) return 'Still up'
  if (h < 12) return 'Good morning'
  if (h < 17) return 'Good afternoon'
  if (h < 22) return 'Good evening'
  return 'Winding down'
}

function sameDay(a: Date, b: Date) {
  return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate()
}

/**
 * "Today": one clear job (check in), then a glance at the week and the last
 * few entries. Charts and analytics live on /insights. Mirrors
 * apps/mobile/lib/features/home/home_screen.dart.
 */
export function HomePage() {
  const { user } = useAuth()
  const navigate = useNavigate()
  const rawName: string | undefined = user?.user_metadata?.display_name
  const firstName = rawName?.trim() ? rawName.trim().split(' ')[0] : null

  const [logs, setLogs] = useState<MoodLog[]>([])
  const [recent, setRecent] = useState<HistoryEntry[]>([])
  const [loading, setLoading] = useState(true)
  const [showOnboardingNudge, setShowOnboardingNudge] = useState(false)
  const [version, setVersion] = useState(0)

  useEffect(() => onMoodDataChanged(() => setVersion((v) => v + 1)), [])

  useEffect(() => {
    if (!user) return
    let cancelled = false
    Promise.all([getMoodLogsInRange(user.id, 30), getHistory(user.id, { limit: 3 })]).then(
      ([logsRes, historyRes]) => {
        if (cancelled) return
        // Errors degrade to the first-run state rather than an error card.
        const nextLogs = logsRes.error ? [] : logsRes.logs
        setLogs(nextLogs)
        setRecent(historyRes.error ? [] : historyRes.entries)
        setLoading(false)
        setShowOnboardingNudge(nextLogs.length === 0 && getPendingCheckin() !== null)
      },
    )
    return () => {
      cancelled = true
    }
  }, [user, version])

  function saveOnboardingCheckin() {
    const pending = getPendingCheckin()
    if (!pending) return
    clearPendingCheckin()
    setShowOnboardingNudge(false)
    navigate('/log', { state: { initialScore: pending.score, initialTag: pending.tag } })
  }

  const now = new Date()
  const todays = logs
    .filter((l) => sameDay(new Date(l.logged_at), now))
    .sort((a, b) => b.logged_at.localeCompare(a.logged_at))[0]
  const todaysTechnique = todays && recent[0]?.id === todays.id ? recent[0].technique_name : null

  return (
    <div className="space-y-8">
      <div>
        <p className="text-muted">
          {now.toLocaleDateString(undefined, { weekday: 'long', month: 'long', day: 'numeric' })}
        </p>
        <h1 className="mt-1 text-3xl font-semibold text-ink sm:text-4xl">
          {firstName ? `${greeting()}, ${firstName}` : greeting()}
        </h1>
      </div>

      {showOnboardingNudge && (
        <div className="rounded-2xl bg-blue-tint p-4 sm:flex sm:items-center sm:gap-4">
          <div className="flex-1">
            <p className="font-semibold text-ink">Save the check-in from onboarding?</p>
            <p className="text-muted">We'll pre-fill it. It takes one tap.</p>
          </div>
          <div className="mt-3 flex justify-end gap-2 sm:mt-0">
            <button
              type="button"
              onClick={() => {
                clearPendingCheckin()
                setShowOnboardingNudge(false)
              }}
              className="rounded-full px-4 py-2 font-semibold text-muted hover:text-ink"
            >
              Not now
            </button>
            <button
              type="button"
              onClick={saveOnboardingCheckin}
              className="rounded-full bg-blue-dark px-4 py-2 font-semibold text-on-accent hover:opacity-90"
            >
              Save it
            </button>
          </div>
        </div>
      )}

      {loading ? (
        <div className="card h-56 animate-pulse rounded-[20px]" />
      ) : todays ? (
        <CheckedInCard log={todays} techniqueName={todaysTechnique} />
      ) : (
        <section className="card rounded-[20px] p-5 sm:p-7" aria-labelledby="checkin-heading">
          <h2 id="checkin-heading" className="text-2xl font-semibold text-ink">
            How are you, really?
          </h2>
          <p className="mt-1.5 max-w-md text-muted">
            Tap the closest feeling. You'll get one small thing to try, right away.
          </p>
          <div className="mt-6 flex justify-between gap-2 sm:justify-start sm:gap-6">
            {QUICK_SCORES.map((s) => (
              <button
                key={s}
                type="button"
                onClick={() => navigate('/log', { state: { initialScore: s } })}
                aria-label={`Check in feeling ${moodWord(s)}`}
                className="group flex flex-col items-center gap-1.5 rounded-2xl p-1"
              >
                <span
                  className="h-11 w-11 rounded-full transition-transform duration-200 group-hover:-translate-y-0.5 sm:h-12 sm:w-12"
                  style={{ backgroundColor: moodColor(s), boxShadow: `0 4px 10px ${moodColor(s)}59` }}
                />
                <span className="text-sm font-medium text-muted">{moodWord(s)}</span>
              </button>
            ))}
          </div>
          <button
            type="button"
            onClick={() => navigate('/log')}
            className="mt-6 flex w-full items-center justify-center gap-2 rounded-full bg-blue-dark px-6 py-3.5 font-semibold text-on-accent transition-opacity hover:opacity-90"
          >
            <span aria-hidden className="text-lg leading-none">+</span> Check in
          </button>
        </section>
      )}

      {!loading && (
        <section aria-labelledby="week-heading">
          <h2 id="week-heading" className="mb-3 font-body text-lg font-semibold text-ink">
            This week
          </h2>
          <div className="card space-y-4 p-4 sm:p-5">
            <WeekStrip logs={logs} />
            {logs.length > 0 && (
              <>
                <hr className="border-border" />
                <StreakBadge logs={logs} />
              </>
            )}
          </div>
        </section>
      )}

      {!loading && recent.length > 0 && (
        <section aria-labelledby="recent-heading">
          <div className="mb-3 flex items-center justify-between">
            <h2 id="recent-heading" className="font-body text-lg font-semibold text-ink">
              Recent
            </h2>
            <Link to="/journal" className="rounded-full px-3 py-1 font-semibold text-blue-dark hover:bg-blue-tint">
              See all
            </Link>
          </div>
          <div className="space-y-2.5">
            {recent.map((e) => (
              <HistoryRow key={e.id} entry={e} onClick={() => navigate(`/entry/${e.id}`)} />
            ))}
          </div>
        </section>
      )}
    </div>
  )
}

function CheckedInCard({ log, techniqueName }: { log: MoodLog; techniqueName: string | null }) {
  const navigate = useNavigate()
  const tag = MOOD_TAGS.find((t) => t.value === log.mood_tag)
  const color = moodColor(log.mood_score)
  return (
    <section className="card overflow-hidden rounded-[20px]">
      <div className="h-1.5" style={{ background: `linear-gradient(90deg, ${color}8c, ${color})` }} />
      <button
        type="button"
        onClick={() => navigate(`/entry/${log.id}`)}
        className="flex w-full items-center gap-4 px-5 py-5 text-left hover:bg-surface/50"
      >
        <span
          className="tabular flex h-14 w-14 shrink-0 items-center justify-center rounded-full font-display text-2xl font-semibold"
          style={{ backgroundColor: color, color: '#1C1917' }}
        >
          {log.mood_score}
        </span>
        <span className="min-w-0 flex-1">
          <span className="block text-sm text-muted">You checked in</span>
          <span className="block font-display text-2xl font-semibold text-ink">
            {tag ? `${tag.label} ${tag.emoji}` : moodWord(log.mood_score)}
          </span>
          <span className="block text-sm text-muted">
            {new Date(log.logged_at).toLocaleTimeString(undefined, { hour: 'numeric', minute: '2-digit' })}
          </span>
        </span>
      </button>
      {techniqueName && (
        <div className="mx-5 flex items-center gap-2.5 rounded-xl bg-surface px-4 py-3">
          <span className="text-blue-dark" aria-hidden>✦</span>
          <span className="truncate font-semibold text-ink">{techniqueName}</span>
        </div>
      )}
      <div className="px-3 pb-3 pt-2">
        <button
          type="button"
          onClick={() => navigate('/log')}
          className="rounded-full px-3 py-2 font-semibold text-blue-dark hover:bg-blue-tint"
        >
          + Check in again
        </button>
      </div>
    </section>
  )
}

function WeekStrip({ logs }: { logs: MoodLog[] }) {
  const today = new Date()
  const days = Array.from({ length: 7 }, (_, i) => {
    const d = new Date(today)
    d.setDate(today.getDate() - (6 - i))
    return d
  })
  return (
    <div className="flex justify-between">
      {days.map((d, i) => {
        const log = logs
          .filter((l) => sameDay(new Date(l.logged_at), d))
          .sort((a, b) => b.logged_at.localeCompare(a.logged_at))[0]
        const isToday = i === 6
        return (
          <div key={i} className="flex flex-col items-center gap-2">
            <span className={`text-xs ${isToday ? 'font-bold text-ink' : 'font-medium text-muted'}`}>
              {d.toLocaleDateString(undefined, { weekday: 'narrow' })}
            </span>
            <span
              className={`tabular flex h-9 w-9 items-center justify-center rounded-full text-sm font-semibold ${
                log ? '' : isToday ? 'border-2 border-blue-dark' : 'border-[1.5px] border-border'
              }`}
              style={log ? { backgroundColor: moodColor(log.mood_score), color: '#1C1917' } : undefined}
              title={log ? `${d.toLocaleDateString()}: ${log.mood_score}` : d.toLocaleDateString()}
            >
              {log?.mood_score}
            </span>
          </div>
        )
      })}
    </div>
  )
}
