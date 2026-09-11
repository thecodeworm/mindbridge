import type { SupabaseClient } from 'npm:@supabase/supabase-js@2'

export const RATE_LIMIT_PER_HOUR = 30

export async function isRateLimited(
  serviceClient: SupabaseClient,
  userId: string,
): Promise<boolean> {
  const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000).toISOString()
  const { count: recentCallCount } = await serviceClient
    .from('ai_call_logs')
    .select('id', { count: 'exact', head: true })
    .eq('user_id', userId)
    .gte('called_at', oneHourAgo)

  return recentCallCount !== null && recentCallCount >= RATE_LIMIT_PER_HOUR
}
