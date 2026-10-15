import { createClient, type SupabaseClient } from 'npm:@supabase/supabase-js@2'

export type AuthResult =
  | { ok: true; userClient: SupabaseClient }
  | { ok: false; status: number; error: string }

// Verifies the caller's JWT and that it matches the user_id the client claims
// to be acting as. Returns a user-scoped client (RLS applies) on success.
export async function authenticateUser(
  req: Request,
  supabaseUrl: string,
  anonKey: string,
  bodyUserId: string,
  idMismatchMessage = 'user_id does not match authenticated user',
): Promise<AuthResult> {
  const authHeader = req.headers.get('Authorization')
  if (!authHeader) {
    return { ok: false, status: 401, error: 'Missing Authorization header' }
  }

  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  })

  const { data: { user }, error: authError } = await userClient.auth.getUser()

  if (authError || !user) {
    return { ok: false, status: 401, error: 'Invalid or expired session' }
  }
  if (user.id !== bodyUserId) {
    return { ok: false, status: 403, error: idMismatchMessage }
  }

  return { ok: true, userClient }
}
