import { assertEquals } from 'jsr:@std/assert@1'
import { stub } from 'jsr:@std/testing@1/mock'
import { authenticateUser } from './auth.ts'

const SUPABASE_URL = 'https://example.supabase.co'
const ANON_KEY = 'anon-key'

function req(headers: Record<string, string> = {}): Request {
  return new Request('https://edge-function.example/', { headers })
}

// Fakes the single GET /auth/v1/user call createClient(...).auth.getUser()
// makes internally, so this never touches the network for real.
function stubGetUser(body: unknown, status = 200) {
  return stub(
    globalThis,
    'fetch',
    () => Promise.resolve(new Response(JSON.stringify(body), { status })),
  )
}

Deno.test('authenticateUser - 401 when the Authorization header is missing', async () => {
  const result = await authenticateUser(req(), SUPABASE_URL, ANON_KEY, 'user-1')
  assertEquals(result, {
    ok: false,
    status: 401,
    error: 'Missing Authorization header',
  })
})

Deno.test('authenticateUser - 401 when the session is invalid or expired', async () => {
  using _fetch = stubGetUser({ msg: 'invalid token' }, 401)
  const result = await authenticateUser(
    req({ Authorization: 'Bearer bad-token' }),
    SUPABASE_URL,
    ANON_KEY,
    'user-1',
  )
  assertEquals(result.ok, false)
  if (!result.ok) {
    assertEquals(result.status, 401)
    assertEquals(result.error, 'Invalid or expired session')
  }
})

Deno.test('authenticateUser - 403 when the caller is a different user than claimed', async () => {
  using _fetch = stubGetUser({
    id: 'user-actual',
    email: 'a@b.com',
    aud: 'authenticated',
  })
  const result = await authenticateUser(
    req({ Authorization: 'Bearer good-token' }),
    SUPABASE_URL,
    ANON_KEY,
    'user-claimed',
  )
  assertEquals(result.ok, false)
  if (!result.ok) {
    assertEquals(result.status, 403)
    assertEquals(result.error, 'user_id does not match authenticated user')
  }
})

Deno.test('authenticateUser - uses a custom mismatch message when given one', async () => {
  using _fetch = stubGetUser({
    id: 'user-actual',
    email: 'a@b.com',
    aud: 'authenticated',
  })
  const result = await authenticateUser(
    req({ Authorization: 'Bearer good-token' }),
    SUPABASE_URL,
    ANON_KEY,
    'user-claimed',
    'nope, not you',
  )
  assertEquals(result.ok, false)
  if (!result.ok) {
    assertEquals(result.error, 'nope, not you')
  }
})

Deno.test('authenticateUser - ok when the token matches the claimed user_id', async () => {
  using _fetch = stubGetUser({
    id: 'user-1',
    email: 'a@b.com',
    aud: 'authenticated',
  })
  const result = await authenticateUser(
    req({ Authorization: 'Bearer good-token' }),
    SUPABASE_URL,
    ANON_KEY,
    'user-1',
  )
  assertEquals(result.ok, true)
  if (result.ok) {
    assertEquals(typeof result.userClient, 'object')
  }
})
