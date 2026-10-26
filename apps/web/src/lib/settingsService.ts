import { friendlyError } from './friendlyError'
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
  if (metaError) return { error: friendlyError(metaError.message) }

  const { error: dbError } = await supabase
    .from('users')
    .update({ display_name: trimmed })
    .eq('id', userId)
  if (dbError) return { error: friendlyError(dbError.message) }

  return { error: null }
}

export async function deleteAllUserData(): Promise<{ error: string | null }> {
  // One server-side call removes everything derived from the user's content:
  // mood logs (which cascade to journal entries, suggestions and activity
  // links), weekly AI summaries, custom activity tags and archived duplicates.
  // The login itself stays; use deleteAccount() to remove that too.
  const { error } = await supabase.rpc('delete_my_data')
  return { error: (error ? friendlyError(error.message) : null) }
}

export async function deleteAccount(userId: string): Promise<{ error: string | null }> {
  // The delete-account Edge Function removes the auth user with the service
  // role; every table cascades from it. Afterwards the local session is
  // cleared without a server round trip, since the server user is gone.
  const { error } = await supabase.functions.invoke('delete-account', {
    body: { user_id: userId, confirm: 'DELETE' },
  })
  if (error) {
    return { error: "We couldn't delete your account just now. Nothing was removed. Please try again in a moment." }
  }
  await supabase.auth.signOut({ scope: 'local' })
  return { error: null }
}
