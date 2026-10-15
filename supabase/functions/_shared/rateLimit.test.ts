import { assertEquals } from 'jsr:@std/assert@1'
import type { SupabaseClient } from 'npm:@supabase/supabase-js@2'
import { isRateLimited, RATE_LIMIT_PER_HOUR } from './rateLimit.ts'

// Minimal fake mirroring the `.from().select().eq().gte()` chain isRateLimited
// calls — only `count` from the final result matters.
function fakeClient(count: number | null): SupabaseClient {
  const chain = {
    select: () => chain,
    eq: () => chain,
    gte: () => Promise.resolve({ count }),
  }
  return { from: () => chain } as unknown as SupabaseClient
}

Deno.test('isRateLimited - false when well under the limit', async () => {
  const result = await isRateLimited(fakeClient(0), 'user-1')
  assertEquals(result, false)
})

Deno.test('isRateLimited - false one call under the limit', async () => {
  const result = await isRateLimited(
    fakeClient(RATE_LIMIT_PER_HOUR - 1),
    'user-1',
  )
  assertEquals(result, false)
})

Deno.test('isRateLimited - true exactly at the limit', async () => {
  const result = await isRateLimited(fakeClient(RATE_LIMIT_PER_HOUR), 'user-1')
  assertEquals(result, true)
})

Deno.test('isRateLimited - true above the limit', async () => {
  const result = await isRateLimited(
    fakeClient(RATE_LIMIT_PER_HOUR + 5),
    'user-1',
  )
  assertEquals(result, true)
})

Deno.test('isRateLimited - false when count comes back null', async () => {
  const result = await isRateLimited(fakeClient(null), 'user-1')
  assertEquals(result, false)
})
