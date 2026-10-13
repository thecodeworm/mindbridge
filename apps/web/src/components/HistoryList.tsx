import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { MOOD_TAGS } from '../../../../shared/types'
import { getHistory } from '../lib/historyService'
import type { HistoryEntry } from '../lib/historyService'
import { moodColor, moodWord } from '../lib/moodColor'
import { onMoodDataChanged } from '../lib/dataEvents'

const PAGE_SIZE = 20

function tagInfo(tag: string) {
  return MOOD_TAGS.find((t) => t.value === tag)
}

function formatDate(iso: string): string {
  const d = new Date(iso)
  const day = d.toLocaleDateString(undefined, { weekday: 'short', month: 'short', day: 'numeric' })
  const time = d.toLocaleTimeString(undefined, { hour: 'numeric', minute: '2-digit' })
  return `${day} · ${time}`
}

function monthLabel(iso: string): string {
  return new Date(iso).toLocaleDateString(undefined, { month: 'long', year: 'numeric' })
}

export function HistoryRow({ entry, onClick }: { entry: HistoryEntry; onClick: () => void }) {
  const tag = tagInfo(entry.mood_tag)

  return (
    <button
      type="button"
      onClick={onClick}
      className="card flex w-full items-center gap-3.5 px-4 py-3.5 text-left transition-shadow hover:shadow-[var(--shadow-elevated)]"
    >
      <span
        className="tabular flex h-11 w-11 shrink-0 items-center justify-center rounded-full font-semibold"
        style={{ backgroundColor: moodColor(entry.mood_score), color: '#1C1917' }}
      >
        {entry.mood_score}
      </span>
      <div className="min-w-0 flex-1">
        <p className="font-semibold text-ink">
          {tag ? `${tag.label} ${tag.emoji}` : moodWord(entry.mood_score)}
        </p>
        {entry.technique_name && <p className="truncate text-muted">{entry.technique_name}</p>}
        <p className="text-sm text-muted">{formatDate(entry.logged_at)}</p>
      </div>
      <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="shrink-0 text-muted" aria-hidden>
        <path d="m9 18 6-6-6-6" />
      </svg>
    </button>
  )
}

export function HistoryList({ userId }: { userId: string }) {
  const navigate = useNavigate()
  const [entries, setEntries] = useState<HistoryEntry[]>([])
  const [loading, setLoading] = useState(true)
  const [loadingMore, setLoadingMore] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [hasMore, setHasMore] = useState(true)
  const [version, setVersion] = useState(0)

  useEffect(() => onMoodDataChanged(() => setVersion((v) => v + 1)), [])

  useEffect(() => {
    let cancelled = false
    getHistory(userId, { limit: PAGE_SIZE + 1, offset: 0 }).then(({ entries, error }) => {
      if (cancelled) return
      setHasMore(entries.length > PAGE_SIZE)
      setEntries(entries.slice(0, PAGE_SIZE))
      setError(error)
      setLoading(false)
    })
    return () => {
      cancelled = true
    }
  }, [userId, version])

  async function loadMore() {
    setLoadingMore(true)
    const { entries: next, error } = await getHistory(userId, {
      limit: PAGE_SIZE + 1,
      offset: entries.length,
    })
    setHasMore(next.length > PAGE_SIZE)
    setEntries((prev) => [...prev, ...next.slice(0, PAGE_SIZE)])
    setError(error)
    setLoadingMore(false)
  }

  if (loading) {
    return (
      <div className="space-y-2.5">
        {[0, 1, 2, 3].map((i) => (
          <div key={i} className="card h-[76px] animate-pulse" />
        ))}
      </div>
    )
  }

  if (error) {
    return (
      <div className="flex items-center gap-3 rounded-2xl bg-error-tint px-4 py-3.5">
        <p className="flex-1 text-ink">{error}</p>
        <button type="button" onClick={() => setVersion((v) => v + 1)} className="rounded-full px-3 py-1.5 font-semibold text-blue-dark hover:bg-blue-tint">
          Retry
        </button>
      </div>
    )
  }

  if (entries.length === 0) {
    return (
      <div className="card px-6 py-12 text-center">
        <h2 className="text-xl text-ink">Your journal starts here</h2>
        <p className="mx-auto mt-1 max-w-sm text-muted">Every check-in lands here, with the technique you got.</p>
        <button
          type="button"
          onClick={() => navigate('/log')}
          className="mt-5 rounded-full bg-blue-dark px-6 py-2.5 font-semibold text-on-accent hover:opacity-90"
        >
          Check in
        </button>
      </div>
    )
  }

  let lastMonth = ''
  return (
    <div>
      {entries.map((entry, i) => {
        const month = monthLabel(entry.logged_at)
        const header = month !== lastMonth
        lastMonth = month
        return (
          <div key={entry.id}>
            {header && (
              <h2 className={`mb-2.5 px-1 font-body text-sm font-semibold text-muted ${i === 0 ? '' : 'mt-6'}`}>{month}</h2>
            )}
            <div className="mb-2.5">
              <HistoryRow entry={entry} onClick={() => navigate(`/entry/${entry.id}`)} />
            </div>
          </div>
        )
      })}

      {hasMore && (
        <button
          type="button"
          onClick={loadMore}
          disabled={loadingMore}
          className="mt-2 w-full rounded-full border border-border bg-card px-4 py-2.5 font-semibold text-ink transition-colors hover:bg-blue-tint disabled:opacity-50"
        >
          {loadingMore ? 'Loading…' : 'Show older entries'}
        </button>
      )}
    </div>
  )
}
