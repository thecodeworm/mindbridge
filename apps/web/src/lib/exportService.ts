import { friendlyError } from './friendlyError'
import { supabase } from './supabaseClient'

export async function exportUserData(userId: string): Promise<{ error: string | null }> {
  const [moodRes, journalRes, suggestionRes] = await Promise.all([
    supabase
      .from('mood_logs')
      .select('id, mood_score, mood_tag, logged_at')
      .eq('user_id', userId)
      .order('logged_at', { ascending: false }),
    supabase
      .from('journal_entries')
      .select('id, mood_log_id, body, created_at')
      .eq('user_id', userId)
      .order('created_at', { ascending: false }),
    supabase
      .from('coping_suggestions')
      .select('id, mood_log_id, technique_name, description, steps, generated_at, helpful, saved')
      .eq('user_id', userId)
      .order('generated_at', { ascending: false }),
  ])

  if (moodRes.error) return { error: friendlyError(moodRes.error.message) }

  const payload = {
    exported_at: new Date().toISOString(),
    mood_logs: moodRes.data ?? [],
    journal_entries: journalRes.data ?? [],
    coping_suggestions: suggestionRes.data ?? [],
  }

  const blob = new Blob([JSON.stringify(payload, null, 2)], { type: 'application/json' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  const date = new Date().toISOString().slice(0, 10)
  a.download = `mindbridge-export-${date}.json`
  document.body.appendChild(a)
  a.click()
  document.body.removeChild(a)
  URL.revokeObjectURL(url)

  return { error: null }
}
