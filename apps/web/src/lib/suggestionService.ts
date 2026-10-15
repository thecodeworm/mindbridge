import { supabase } from './supabaseClient'
import type { SuggestionResponse } from '../../../../shared/types'

export async function generateSuggestion({
  moodLogId,
  userId,
}: {
  moodLogId: string
  userId: string
}): Promise<{ suggestion: SuggestionResponse | null; error: string | null }> {
  const { data, error } = await supabase.functions.invoke('generate-suggestion', {
    body: { mood_log_id: moodLogId, user_id: userId },
  })
  if (error) {
    // FunctionsHttpError carries the server body in error.context (a Response).
    // Keep the user-facing message generic + retryable; log details for debugging.
    return { suggestion: null, error: "We couldn't put together a technique this time. Your check-in is saved, so try again in a moment." }
  }
  return { suggestion: data as SuggestionResponse, error: null }
}
