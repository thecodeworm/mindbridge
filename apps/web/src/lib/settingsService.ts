import { supabase } from './supabaseClient'

export async function updateDisplayName(
  userId: string,
  displayName: string,
): Promise<{ error: string | null }> {
  const trimmed = displayName.trim()
  if (!trimmed) return { error: 'Display name cannot be empty.' }

  // Kept in sync in two places: auth user_metadata (what the dashboard
  // greeting reads — see HomePage.tsx) and public.users.display_name (the
  // DB column, source of truth for any future server-side read).
  const { error: metaError } = await supabase.auth.updateUser({
    data: { display_name: trimmed },
  })
  if (metaError) return { error: metaError.message }

  const { error: dbError } = await supabase
    .from('users')
    .update({ display_name: trimmed })
    .eq('id', userId)
  if (dbError) return { error: dbError.message }

  return { error: null }
}

export async function deleteAllUserData(userId: string): Promise<{ error: string | null }> {
  // journal_entries and coping_suggestions cascade-delete via their
  // mood_log_id FK — see 0001_init_schema.sql. This clears all mood data
  // but does not close the login itself (that needs the admin API, which
  // requires a service-role Edge Function — not built yet).
  const { error } = await supabase.from('mood_logs').delete().eq('user_id', userId)
  return { error: error?.message ?? null }
}
