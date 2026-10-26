import type { SupabaseClient } from 'npm:@supabase/supabase-js@2'

export const RATE_LIMIT_PER_HOUR = 30
export const RATE_LIMIT_PER_DAY = 100
// Spend ceiling across ALL users for the rolling 24h. Override with the
// DAILY_GLOBAL_AI_CAP secret; a missing or malformed value uses this default.
export const DEFAULT_GLOBAL_DAILY_CAP = 1500

const HOUR_MS = 60 * 60 * 1000
const DAY_MS = 24 * HOUR_MS

export type RejectReason =
  | 'user_hourly'
  | 'user_daily'
  | 'global_daily'
  | 'error'

export type Reservation =
  | { ok: true; id: string }
  | { ok: false; reason: RejectReason }

// A cap must be a positive whole number; anything else (unset, "abc", 0, -5)
// falls back to the default instead of silently disabling the limit.
export function parseCap(
  raw: string | null | undefined,
  fallback: number,
): number {
  if (raw === null || raw === undefined) return fallback
  if (!/^\d+$/.test(raw.trim())) return fallback
  const n = Number(raw.trim())
  return Number.isSafeInteger(n) && n > 0 ? n : fallback
}

async function countSince(
  serviceClient: SupabaseClient,
  sinceMs: number,
  userId?: string,
): Promise<number | null> {
  let query = serviceClient
    .from('ai_call_logs')
    .select('id', { count: 'exact', head: true })
    .gte('called_at', new Date(Date.now() - sinceMs).toISOString())
  if (userId) query = query.eq('user_id', userId)
  const { count, error } = await query
  return error ? null : count
}

// Reserve-then-call. The reservation row is written BEFORE the Anthropic call
// and counted together with every other row, so N parallel requests cannot all
// slip under the cap the way a count-then-call check allows (the old logger
// only wrote its row after the model answered, seconds later). A request that
// finds itself over a cap deletes its own reservation and is refused. Any
// database error fails closed.
export async function reserveAiCall(
  serviceClient: SupabaseClient,
  userId: string,
  globalDailyCap: number = DEFAULT_GLOBAL_DAILY_CAP,
): Promise<Reservation> {
  const { data, error } = await serviceClient
    .from('ai_call_logs')
    .insert({
      user_id: userId,
      input_tokens: 0,
      output_tokens: 0,
      latency_ms: 0,
    })
    .select('id')
    .single()

  if (error || !data) {
    console.error('Failed to reserve ai_call_log:', error)
    return { ok: false, reason: 'error' }
  }

  const reservationId: string = data.id

  const refuse = async (reason: RejectReason): Promise<Reservation> => {
    const { error: deleteError } = await serviceClient
      .from('ai_call_logs')
      .delete()
      .eq('id', reservationId)
    if (deleteError) {
      // Left in place: it keeps counting, which errs on the safe side.
      console.error('Failed to release ai_call_log reservation:', deleteError)
    }
    return { ok: false, reason }
  }

  const [hourly, daily, global] = await Promise.all([
    countSince(serviceClient, HOUR_MS, userId),
    countSince(serviceClient, DAY_MS, userId),
    countSince(serviceClient, DAY_MS),
  ])

  if (hourly === null || daily === null || global === null) {
    return refuse('error')
  }
  // Counts include this request's own reservation, hence strictly greater.
  if (hourly > RATE_LIMIT_PER_HOUR) return refuse('user_hourly')
  if (daily > RATE_LIMIT_PER_DAY) return refuse('user_daily')
  if (global > globalDailyCap) return refuse('global_daily')

  return { ok: true, id: reservationId }
}

export function rejectionResponse(
  reason: RejectReason,
): { status: number; error: string } {
  switch (reason) {
    case 'user_hourly':
    case 'user_daily':
      return {
        status: 429,
        error: 'Rate limit exceeded. Please try again later.',
      }
    case 'global_daily':
      return {
        status: 503,
        error: 'MindBridge is very busy right now. Please try again later.',
      }
    default:
      return { status: 500, error: 'Internal server error' }
  }
}
