import { useState, type FormEvent } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { deleteAllUserData, updateDisplayName } from '../lib/settingsService'
import { getStoredTheme, setTheme } from '../lib/theme'
import type { ThemeMode } from '../lib/theme'

const THEME_OPTIONS: { value: ThemeMode; label: string }[] = [
  { value: 'light', label: 'Light' },
  { value: 'dark', label: 'Dark' },
  { value: 'system', label: 'System' },
]

function chipClass(selected: boolean) {
  return [
    'flex items-center gap-1.5 rounded-full border px-3 py-1.5 text-sm font-medium transition-colors',
    selected
      ? 'border-blue-dark bg-blue-tint text-blue-dark'
      : 'border-border bg-field text-ink hover:bg-blue-tint',
  ].join(' ')
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="space-y-4 rounded-xl border border-border bg-surface p-6 shadow-sm">
      <h2 className="text-sm font-bold uppercase tracking-wide text-muted">{title}</h2>
      {children}
    </div>
  )
}

export function SettingsPage() {
  const { user, signOut } = useAuth()
  const navigate = useNavigate()

  const [displayName, setDisplayName] = useState(user?.user_metadata?.display_name ?? '')
  const [nameSaving, setNameSaving] = useState(false)
  const [nameError, setNameError] = useState<string | null>(null)
  const [nameSaved, setNameSaved] = useState(false)

  const [themeMode, setThemeMode] = useState<ThemeMode>(getStoredTheme())

  const [confirmingDelete, setConfirmingDelete] = useState(false)
  const [deleting, setDeleting] = useState(false)
  const [deleteError, setDeleteError] = useState<string | null>(null)

  function handleThemeChange(mode: ThemeMode) {
    setThemeMode(mode)
    setTheme(mode)
  }

  async function handleSaveName(e: FormEvent) {
    e.preventDefault()
    if (!user) return
    setNameSaving(true)
    setNameError(null)
    setNameSaved(false)
    const { error } = await updateDisplayName(user.id, displayName)
    setNameSaving(false)
    if (error) { setNameError(error); return }
    setNameSaved(true)
  }

  async function handleConfirmDelete() {
    if (!user) return
    setDeleting(true)
    setDeleteError(null)
    const { error } = await deleteAllUserData(user.id)
    setDeleting(false)
    if (error) { setDeleteError(error); return }
    setConfirmingDelete(false)
    navigate('/')
  }

  return (
    <div className="min-h-screen bg-cream p-4 pb-24 sm:p-6">
      <div className="mx-auto w-full max-w-2xl space-y-6">
        <div className="flex items-center gap-3">
          <button
            type="button"
            onClick={() => navigate('/')}
            className="text-sm font-medium text-muted transition-colors hover:text-ink"
          >
            ← Back
          </button>
          <h1 className="text-2xl font-bold text-ink">Settings</h1>
        </div>

        <Section title="Profile">
          <form onSubmit={handleSaveName} className="space-y-3">
            <label className="block text-sm font-medium text-muted" htmlFor="displayName">
              Display name
            </label>
            <input
              id="displayName"
              type="text"
              value={displayName}
              onChange={(e) => { setDisplayName(e.target.value); setNameSaved(false) }}
              maxLength={60}
              className="w-full rounded-full border border-border bg-field px-4 py-2.5 text-ink placeholder:text-faint"
            />
            {nameError && (
              <p className="rounded-lg bg-error-tint px-3 py-2 text-sm text-error">{nameError}</p>
            )}
            {nameSaved && !nameError && (
              <p className="text-sm text-success">Saved.</p>
            )}
            <button
              type="submit"
              disabled={nameSaving}
              className="rounded-lg bg-blue-dark px-4 py-2 text-sm font-medium text-on-accent transition-opacity hover:opacity-90 disabled:opacity-50"
            >
              {nameSaving ? 'Saving…' : 'Save name'}
            </button>
          </form>
        </Section>

        <Section title="Appearance">
          <div>
            <p className="mb-2 text-sm font-medium text-muted">Theme</p>
            <div className="flex flex-wrap gap-2">
              {THEME_OPTIONS.map((opt) => (
                <button
                  key={opt.value}
                  type="button"
                  onClick={() => handleThemeChange(opt.value)}
                  className={chipClass(themeMode === opt.value)}
                >
                  {opt.label}
                </button>
              ))}
            </div>
          </div>
        </Section>

        <Section title="Account">
          <button
            type="button"
            onClick={() => signOut()}
            className="w-full rounded-lg border border-border bg-field px-4 py-2.5 text-left font-medium text-ink transition-colors hover:bg-blue-tint sm:w-auto"
          >
            Sign out
          </button>

          <div className="space-y-3 border-t border-border pt-4">
            <div>
              <p className="font-medium text-ink">Delete my data</p>
              <p className="text-sm text-muted">
                Permanently deletes every mood log, journal entry, and coping suggestion. Your
                login stays active — this clears your data, it doesn't close your account.
              </p>
            </div>

            {!confirmingDelete ? (
              <button
                type="button"
                onClick={() => setConfirmingDelete(true)}
                className="rounded-lg border border-error px-4 py-2 text-sm font-medium text-error transition-colors hover:bg-error-tint"
              >
                Delete my data
              </button>
            ) : (
              <div className="space-y-3 rounded-lg border border-error bg-error-tint p-4">
                <p className="text-sm font-medium text-error">
                  This can't be undone. Delete all mood data?
                </p>
                {deleteError && <p className="text-sm text-error">{deleteError}</p>}
                <div className="flex gap-3">
                  <button
                    type="button"
                    onClick={() => { setConfirmingDelete(false); setDeleteError(null) }}
                    disabled={deleting}
                    className="flex-1 rounded-lg border border-border bg-field px-3 py-2 text-sm font-medium text-ink transition-colors hover:bg-blue-tint disabled:opacity-50"
                  >
                    Cancel
                  </button>
                  <button
                    type="button"
                    onClick={handleConfirmDelete}
                    disabled={deleting}
                    className="flex-1 rounded-lg border border-error bg-field px-3 py-2 text-sm font-medium text-error transition-colors hover:bg-error-tint disabled:opacity-50"
                  >
                    {deleting ? 'Deleting…' : 'Delete everything'}
                  </button>
                </div>
              </div>
            )}
          </div>
        </Section>
      </div>
    </div>
  )
}
