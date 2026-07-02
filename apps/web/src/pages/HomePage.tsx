import { useAuth } from '../context/AuthContext'

export function HomePage() {
  const { user, signOut } = useAuth()
  const displayName = user?.user_metadata?.display_name ?? 'there'

  return (
    <div className="flex min-h-screen flex-col items-center justify-center gap-4 bg-gray-50">
      <h1 className="text-3xl font-bold text-gray-900">
        Welcome, {displayName}
      </h1>
      <button
        type="button"
        onClick={() => signOut()}
        className="rounded bg-gray-200 px-4 py-2 font-medium text-gray-800"
      >
        Log out
      </button>
    </div>
  )
}
