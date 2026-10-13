import { useState, type FormEvent } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { deleteAllUserData, updateDisplayName } from '../lib/settingsService'
import { getStoredTheme, setTheme } from '../lib/theme'
import type { ThemeMode } from '../lib/theme'
import { exportUserData } from '../lib/exportService'
import { CrisisChip } from '../components/CrisisChip'

const THEME_OPTIONS: { value: ThemeMode; label: string }[] = [
  { value: 'light', label: 'Light' },
  { value: 'dark', label: 'Dark' },
  { value: 'system', label: 'System' },
]

function chipClass(selected: boolean) {
  return [
    'flex items-center gap-1.5 rounded-lg border px-3 py-1.5 text-sm font-medium transition-colors',
    selected
      ? 'border-blue-dark bg-blue-tint text-blue-dark'
      : 'border-border bg-field text-ink hover:bg-blue-tint',
  ].join(' ')
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="card space-y-4 p-6">
      <h2 className="text-xl text-ink">{title}</h2>
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

  const [exporting, setExporting] = useState(false)
  const [exportError, setExportError] = useState<string | null>(null)

  // Notification permission state
  const [notifPermission, setNotifPermission] = useState<NotificationPermission | 'unsupported'>(() => {
    if (typeof Notification === 'undefined') return 'unsupported'
    return Notification.permission
  })

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

  async function handleExport() {
    if (!user) return
    setExporting(true)
    setExportError(null)
    const { error } = await exportUserData(user.id)
    setExporting(false)
    if (error) setExportError(error)
  }

  async function requestNotifications() {
    if (typeof Notification === 'undefined') return
    const permission = await Notification.requestPermission()
    setNotifPermission(permission)
  }

  return (
    <div className="min-h-screen bg-cream">
      <div className="mx-auto w-full max-w-xl space-y-4 px-4 pb-16 pt-4 sm:px-6">
        <div className="flex items-center gap-2">
          <button
            type="button"
            onClick={() => navigate('/')}
            aria-label="Back"
            className="flex h-10 w-10 items-center justify-center rounded-full text-ink hover:bg-surface"
          >
            <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
              <path d="m15 18-6-6 6-6" />
            </svg>
          </button>
          <h1 className="flex-1 text-2xl font-semibold text-ink">Settings</h1>
          <CrisisChip inline />
        </div>

        <Section title="Profile">
          <form onSubmit={handleSaveName} className="space-y-3">
            <label className="block text-sm font-medium text-muted" htmlFor="displayName">Display name</label>
            <input id="displayName" type="text" value={displayName} onChange={(e) => { setDisplayName(e.target.value); setNameSaved(false) }} maxLength={60} className="w-full rounded-[10px] border border-border bg-field px-4 py-2.5 text-ink placeholder:text-faint" />
            {nameError && <p className="rounded-lg bg-error-tint px-3 py-2 text-sm text-error">{nameError}</p>}
            {nameSaved && !nameError && <p className="text-sm text-success">Saved.</p>}
            <button type="submit" disabled={nameSaving} className="rounded-lg bg-blue-dark px-4 py-2 text-sm font-medium text-on-accent transition-opacity hover:opacity-90 disabled:opacity-50">
              {nameSaving ? 'Saving…' : 'Save name'}
            </button>
          </form>
        </Section>

        <Section title="Appearance">
          <div>
            <p className="mb-2 text-sm font-medium text-muted">Theme</p>
            <div className="flex flex-wrap gap-2">
              {THEME_OPTIONS.map((opt) => (
                <button key={opt.value} type="button" onClick={() => handleThemeChange(opt.value)} className={chipClass(themeMode === opt.value)}>{opt.label}</button>
              ))}
            </div>
          </div>
        </Section>

        <Section title="Reminders">
          {notifPermission === 'unsupported' && (
            <p className="text-sm text-muted">Browser notifications aren't supported. Use the mobile app for daily reminders.</p>
          )}
          {notifPermission === 'denied' && (
            <p className="text-sm text-muted">Notifications are blocked. Enable them in your browser settings, then return here.</p>
          )}
          {notifPermission === 'default' && (
            <div className="space-y-2">
              <p className="text-sm text-muted">Get a daily reminder to check in with your mood.</p>
              <button type="button" onClick={requestNotifications} className="rounded-lg border border-border bg-field px-4 py-2 text-sm font-medium text-ink transition-colors hover:bg-blue-tint">
                Enable reminders
              </button>
            </div>
          )}
          {notifPermission === 'granted' && (
            <p className="text-sm text-success">✓ Notifications enabled. Set your reminder time in the mobile app.</p>
          )}
        </Section>

        <Section title="Data">
          <div className="space-y-3">
            <p className="text-sm text-muted">Export all your mood logs, journal entries, and coping suggestions as JSON.</p>
            {exportError && <p className="rounded-lg bg-error-tint px-3 py-2 text-sm text-error">{exportError}</p>}
            <button type="button" onClick={handleExport} disabled={exporting} className="rounded-lg border border-border bg-field px-4 py-2.5 text-sm font-medium text-ink transition-colors hover:bg-blue-tint disabled:opacity-50">
              {exporting ? 'Exporting…' : 'Export my data'}
            </button>
          </div>
        </Section>

        <Section title="Help">
          <div className="space-y-2">
            <p className="text-sm text-muted">If you're struggling, confidential support is available 24/7.</p>
            <a href="/help" className="inline-block rounded-lg border border-terra bg-terra-tint px-4 py-2 text-sm font-medium text-terra-dark transition-colors hover:bg-terra">
              Crisis resources →
            </a>
          </div>
        </Section>

        <Section title="Account">
          <button type="button" onClick={() => signOut()} className="w-full rounded-lg border border-border bg-field px-4 py-2.5 text-left font-medium text-ink transition-colors hover:bg-blue-tint sm:w-auto">
            Sign out
          </button>

          <div className="space-y-3 border-t border-border pt-4">
            <div>
              <p className="font-medium text-ink">Delete my data</p>
              <p className="text-sm text-muted">Permanently deletes every mood log, journal entry, and coping suggestion. Your login stays active. This clears your data but doesn't close your account.</p>
            </div>
            {!confirmingDelete ? (
              <button type="button" onClick={() => setConfirmingDelete(true)} className="rounded-lg border border-error px-4 py-2 text-sm font-medium text-error transition-colors hover:bg-error-tint">Delete my data</button>
            ) : (
              <div className="space-y-3 rounded-lg border border-error bg-error-tint p-4">
                <p className="text-sm font-medium text-error">This can't be undone. Delete all mood data?</p>
                {deleteError && <p className="text-sm text-error">{deleteError}</p>}
                <div className="flex gap-3">
                  <button type="button" onClick={() => { setConfirmingDelete(false); setDeleteError(null) }} disabled={deleting} className="flex-1 rounded-lg border border-border bg-field px-3 py-2 text-sm font-medium text-ink transition-colors hover:bg-blue-tint disabled:opacity-50">Cancel</button>
                  <button type="button" onClick={handleConfirmDelete} disabled={deleting} className="flex-1 rounded-lg border border-error bg-field px-3 py-2 text-sm font-medium text-error transition-colors hover:bg-error-tint disabled:opacity-50">{deleting ? 'Deleting…' : 'Delete everything'}</button>
                </div>
              </div>
            )}
          </div>
        </Section>
      </div>
    </div>
  )
}
