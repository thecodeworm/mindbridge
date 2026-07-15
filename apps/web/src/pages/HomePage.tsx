import { useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'

export function HomePage() {
  const { user, signOut } = useAuth()
  const navigate = useNavigate()
  const displayName = user?.user_metadata?.display_name ?? 'there'

  return (
    <div className="flex min-h-screen flex-col items-center justify-center gap-4 bg-cream p-4">
      <h1 className="text-3xl font-bold text-ink">
        Welcome, {displayName}
      </h1>
      <button
        type="button"
        onClick={() => navigate('/log')}
        className="rounded-lg bg-blue-dark px-6 py-3 font-medium text-on-accent transition-opacity hover:opacity-90"
      >
        Log today's mood
      </button>
      <button
        type="button"
        onClick={() => signOut()}
        className="rounded-lg border border-border bg-surface px-4 py-2 font-medium text-ink transition-colors hover:bg-blue-tint"
      >
        Log out
      </button>
    </div>
  )
}
