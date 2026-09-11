import type { SupabaseClient } from 'npm:@supabase/supabase-js@2'

export function makeAiCallLogger(
  serviceClient: SupabaseClient,
  userId: string,
) {
  return async (
    usage: { input_tokens?: number; output_tokens?: number },
    latencyMs: number,
  ) => {
    const { error } = await serviceClient.from('ai_call_logs').insert({
      user_id: userId,
      input_tokens: usage.input_tokens ?? 0,
      output_tokens: usage.output_tokens ?? 0,
      latency_ms: latencyMs,
    })
    if (error) {
      console.error('Failed to insert ai_call_log:', error)
    }
  }
}
