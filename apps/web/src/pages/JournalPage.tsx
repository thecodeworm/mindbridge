import { useAuth } from '../context/AuthContext'
import { HistoryList } from '../components/HistoryList'

/** "Journal": every past check-in, newest first, grouped by month. */
export function JournalPage() {
  const { user } = useAuth()
  return (
    <div>
      <h1 className="mb-6 text-3xl font-semibold text-ink">Journal</h1>
      {user && <HistoryList userId={user.id} />}
    </div>
  )
}
