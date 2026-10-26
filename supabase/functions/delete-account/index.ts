import { createClient } from 'npm:@supabase/supabase-js@2'
import { buildCorsHeaders, makeJsonResponse } from '../_shared/cors.ts'
import { authenticateUser } from '../_shared/auth.ts'
import { isUuid } from '../_shared/validate.ts'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

// Permanently deletes the signed-in user's login and, through the
// auth.users -> public.users ON DELETE CASCADE chain, every row they own
// (mood logs, journal entries, suggestions, summaries, tags, call logs).
//
// Only the caller's own account can be deleted: the id in the body must match
// the id in the verified JWT, and the body must carry the literal confirmation
// string so a stray request cannot trigger it.
Deno.serve(async (req) => {
  const corsHeaders = buildCorsHeaders(req.headers.get('Origin'))
  const jsonResponse = makeJsonResponse(corsHeaders)

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    let body: { user_id?: unknown; confirm?: unknown }
    try {
      body = await req.json()
    } catch {
      return jsonResponse({ error: 'Request body must be JSON' }, 400)
    }

    const { user_id, confirm } = body
    if (!isUuid(user_id) || confirm !== 'DELETE') {
      return jsonResponse(
        { error: 'user_id and confirm: "DELETE" are required' },
        400,
      )
    }

    const auth = await authenticateUser(
      req,
      SUPABASE_URL,
      SUPABASE_ANON_KEY,
      user_id,
      'user_id does not match authenticated user',
    )
    if (!auth.ok) {
      return jsonResponse({ error: auth.error }, auth.status)
    }

    const adminClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
      auth: { autoRefreshToken: false, persistSession: false },
    })
    const { error } = await adminClient.auth.admin.deleteUser(user_id)
    if (error) {
      console.error('Failed to delete user:', error)
      return jsonResponse({ error: 'Failed to delete account' }, 500)
    }

    return jsonResponse({ deleted: true })
  } catch (err) {
    console.error('Unhandled error in delete-account:', err)
    return jsonResponse({ error: 'Internal server error' }, 500)
  }
})
