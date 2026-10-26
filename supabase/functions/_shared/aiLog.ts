import type { SupabaseClient } from 'npm:@supabase/supabase-js@2'

// Finishes the ai_call_logs row that reserveAiCall() wrote before the model
// call, filling in real token usage and latency. Called on every outcome
// (success, refusal, malformed output) so the row is never left at zeros.
export function makeAiCallLogger(
  serviceClient: SupabaseClient,
  reservationId: string,
) {
  return async (
    usage: { input_tokens?: number; output_tokens?: number },
    latencyMs: number,
  ) => {
    const { error } = await serviceClient
      .from('ai_call_logs')
      .update({
        input_tokens: usage.input_tokens ?? 0,
        output_tokens: usage.output_tokens ?? 0,
        latency_ms: latencyMs,
      })
      .eq('id', reservationId)
    if (error) {
      console.error('Failed to update ai_call_log:', error)
    }
  }
}
