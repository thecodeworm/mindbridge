import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { MOOD_TAGS } from '../../../../shared/types'
import { getHistory } from '../lib/historyService'
import type { HistoryEntry } from '../lib/historyService'
import { moodColor } from '../lib/moodColor'

const PAGE_SIZE = 20

function tagInfo(tag: string) {
  return MOOD_TAGS.find((t) => t.value === tag)
}

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString(undefined, {
    weekday: 'short',
    month: 'short',
    day: 'numeric',
  })
}

function HistoryRow({ entry, onClick }: { entry: HistoryEntry; onClick: () => void }) {
  const tag = tagInfo(entry.mood_tag)

  return (
    <button
      type="button"
      onClick={onClick}
      className="flex w-full items-center gap-3 rounded-lg border border-border bg-field px-4 py-3 text-left transition-colors hover:bg-blue-tint"
    >
      <span
        className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full text-sm font-bold"
        style={{ backgroundColor: moodColor(entry.mood_score), color: '#1C1917' }}
      >
        {entry.mood_score}
      </span>
      <div className="min-w-0 flex-1">
        <div className="flex items-center gap-1.5">
          <span className="text-sm font-medium text-ink">{formatDate(entry.logged_at)}</span>
          {tag && <span className="text-sm">{tag.emoji}</span>}
        </div>
        <p className="truncate text-sm text-muted">
          {entry.technique_name ?? 'No suggestion saved'}
        </p>
      </div>
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

  useEffect(() => {
    let cancelled = false
    setLoading(true)
    getHistory(userId, { limit: PAGE_SIZE, offset: 0 }).then(({ entries, error }) => {
      if (cancelled) return
      setEntries(entries)
      setError(error)
      setHasMore(entries.length === PAGE_SIZE)
      setLoading(false)
    })
    return () => {
      cancelled = true
    }
  }, [userId])

  async function loadMore() {
    setLoadingMore(true)
    const { entries: next, error } = await getHistory(userId, {
      limit: PAGE_SIZE,
      offset: entries.length,
    })
    setEntries((prev) => [...prev, ...next])
    setError(error)
    setHasMore(next.length === PAGE_SIZE)
    setLoadingMore(false)
  }

  return (
    <div className="rounded-xl border border-border bg-surface p-4 shadow-sm sm:p-6">
      <h2 className="mb-4 text-lg font-bold text-ink">History</h2>

      {loading && (
        <div className="space-y-2">
          {[0, 1, 2].map((i) => (
            <div key={i} className="h-16 animate-pulse rounded-lg bg-field" />
          ))}
        </div>
      )}

      {!loading && error && (
        <p className="rounded-lg bg-error-tint px-3 py-2 text-sm text-error">{error}</p>
      )}

      {!loading && !error && entries.length === 0 && (
        <p className="py-8 text-center text-sm text-muted">
          No entries yet — log your first mood.
        </p>
      )}

      {!loading && entries.length > 0 && (
        <div className="space-y-2">
          {entries.map((entry) => (
            <HistoryRow key={entry.id} entry={entry} onClick={() => navigate(`/entry/${entry.id}`)} />
          ))}
        </div>
      )}

      {!loading && hasMore && entries.length > 0 && (
        <button
          type="button"
          onClick={loadMore}
          disabled={loadingMore}
          className="mt-4 w-full rounded-lg border border-border bg-field px-3 py-2 text-sm font-medium text-ink transition-colors hover:bg-blue-tint disabled:opacity-50"
        >
          {loadingMore ? 'Loading…' : 'Load more'}
        </button>
      )}
    </div>
  )
}
