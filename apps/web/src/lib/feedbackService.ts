import { supabase } from './supabaseClient'

export async function updateSuggestionFeedback(
  moodLogId: string,
  userId: string,
  update: { helpful?: boolean | null; saved?: boolean },
): Promise<{ error: string | null }> {
  const { error } = await supabase
    .from('coping_suggestions')
    .update(update)
    .eq('mood_log_id', moodLogId)
    .eq('user_id', userId)

  return { error: error?.message ?? null }
}

export async function getSavedToolkit(
  userId: string,
): Promise<{
  techniques: Array<{
    id: string
    mood_log_id: string
    technique_name: string
    description: string
    steps: string[]
    generated_at: string
    helpful: boolean | null
    saved: boolean
  }>
  error: string | null
}> {
  const { data, error } = await supabase
    .from('coping_suggestions')
    .select('id, mood_log_id, technique_name, description, steps, generated_at, helpful, saved')
    .eq('user_id', userId)
    .eq('saved', true)
    .order('generated_at', { ascending: false })

  if (error) return { techniques: [], error: error.message }
  return { techniques: data ?? [], error: null }
}
