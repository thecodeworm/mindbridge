import { assert, assertEquals } from 'jsr:@std/assert@1'
import type { SupabaseClient } from 'npm:@supabase/supabase-js@2'
import {
  DEFAULT_GLOBAL_DAILY_CAP,
  parseCap,
  RATE_LIMIT_PER_DAY,
  RATE_LIMIT_PER_HOUR,
  rejectionResponse,
  reserveAiCall,
} from './rateLimit.ts'

type Row = { id: string; user_id: string; called_at: number }

// In-memory stand-in for the ai_call_logs table. Every operation yields to the
// event loop first, so Promise.all() over many reservations interleaves their
// inserts and counts the way real concurrent requests do.
function fakeDb(opts: { failCount?: boolean; failInsert?: boolean } = {}) {
  const rows: Row[] = []
  let nextId = 1
  const tick = () => new Promise<void>((r) => setTimeout(r, 0))

  const client = {
    from: (_table: string) => ({
      insert: (row: { user_id: string }) => ({
        select: () => ({
          single: async () => {
            await tick()
            if (opts.failInsert) {
              return { data: null, error: { message: 'boom' } }
            }
            const created = {
              id: String(nextId++),
              user_id: row.user_id,
              called_at: Date.now(),
            }
            rows.push(created)
            return { data: { id: created.id }, error: null }
          },
        }),
      }),
      select: () => {
        let since = 0
        let userId: string | null = null
        const builder = {
          gte: (_col: string, iso: string) => {
            since = new Date(iso).getTime()
            return builder
          },
          eq: (_col: string, value: string) => {
            userId = value
            return builder
          },
          then: (resolve: (v: unknown) => void) => {
            tick().then(() => {
              if (opts.failCount) {
                return resolve({ count: null, error: { message: 'boom' } })
              }
              const count = rows.filter((r) =>
                r.called_at >= since &&
                (userId === null || r.user_id === userId)
              ).length
              resolve({ count, error: null })
            })
          },
        }
        return builder
      },
      delete: () => ({
        eq: async (_col: string, id: string) => {
          await tick()
          const i = rows.findIndex((r) => r.id === id)
          if (i >= 0) rows.splice(i, 1)
          return { error: null }
        },
      }),
    }),
  }
  return { client: client as unknown as SupabaseClient, rows }
}

Deno.test('reserveAiCall - allows a first call and keeps the reservation', async () => {
  const { client, rows } = fakeDb()
  const r = await reserveAiCall(client, 'u1')
  assertEquals(r.ok, true)
  assertEquals(rows.length, 1)
})

Deno.test('reserveAiCall - refuses call 31 within the hour and releases its row', async () => {
  const { client, rows } = fakeDb()
  for (let i = 0; i < RATE_LIMIT_PER_HOUR; i++) {
    assertEquals((await reserveAiCall(client, 'u1')).ok, true)
  }
  const over = await reserveAiCall(client, 'u1')
  assertEquals(over, { ok: false, reason: 'user_hourly' })
  assertEquals(rows.length, RATE_LIMIT_PER_HOUR)
})

Deno.test('reserveAiCall - parallel burst cannot exceed the hourly cap', async () => {
  const { client, rows } = fakeDb()
  const results = await Promise.all(
    Array.from(
      { length: RATE_LIMIT_PER_HOUR + 15 },
      () => reserveAiCall(client, 'u1'),
    ),
  )
  const passed = results.filter((r) => r.ok).length
  assert(passed <= RATE_LIMIT_PER_HOUR, `${passed} parallel calls passed`)
  // Whatever passed is exactly what is still counted.
  assertEquals(rows.length, passed)
})

Deno.test("reserveAiCall - one user does not consume another user's quota", async () => {
  const { client } = fakeDb()
  for (let i = 0; i < RATE_LIMIT_PER_HOUR; i++) {
    await reserveAiCall(client, 'u1')
  }
  assertEquals((await reserveAiCall(client, 'u2')).ok, true)
})

Deno.test('reserveAiCall - global daily cap applies across users', async () => {
  const { client } = fakeDb()
  assertEquals((await reserveAiCall(client, 'a', 2)).ok, true)
  assertEquals((await reserveAiCall(client, 'b', 2)).ok, true)
  assertEquals(await reserveAiCall(client, 'c', 2), {
    ok: false,
    reason: 'global_daily',
  })
})

Deno.test('reserveAiCall - fails closed when counting errors', async () => {
  const { client, rows } = fakeDb({ failCount: true })
  assertEquals(await reserveAiCall(client, 'u1'), {
    ok: false,
    reason: 'error',
  })
  assertEquals(rows.length, 0)
})

Deno.test('reserveAiCall - fails closed when the reservation insert errors', async () => {
  const { client } = fakeDb({ failInsert: true })
  assertEquals(await reserveAiCall(client, 'u1'), {
    ok: false,
    reason: 'error',
  })
})

Deno.test('parseCap - only positive whole numbers are accepted', () => {
  assertEquals(parseCap('250', 10), 250)
  assertEquals(parseCap(' 40 ', 10), 40)
  assertEquals(parseCap(undefined, 10), 10)
  assertEquals(parseCap(null, 10), 10)
  assertEquals(parseCap('abc', 10), 10)
  assertEquals(parseCap('0', 10), 10)
  assertEquals(parseCap('-5', 10), 10)
  assertEquals(parseCap('1.5', 10), 10)
  assertEquals(parseCap('', DEFAULT_GLOBAL_DAILY_CAP), DEFAULT_GLOBAL_DAILY_CAP)
})

Deno.test('rejectionResponse - status codes', () => {
  assertEquals(rejectionResponse('user_hourly').status, 429)
  assertEquals(rejectionResponse('user_daily').status, 429)
  assertEquals(rejectionResponse('global_daily').status, 503)
  assertEquals(rejectionResponse('error').status, 500)
  assert(RATE_LIMIT_PER_DAY > RATE_LIMIT_PER_HOUR)
})
