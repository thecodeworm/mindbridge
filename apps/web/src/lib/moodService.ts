import type { MoodTag } from '../../../../shared/types'
import { supabase } from './supabaseClient'

export async function logMood({
  userId,
  moodScore,
  moodTag,
}: {
  userId: string
  moodScore: number
  moodTag: MoodTag
}): Promise<{ moodLogId: string | null; error: string | null }> {
  const { data, error } = await supabase
    .from('mood_logs')
    .insert({ user_id: userId, mood_score: moodScore, mood_tag: moodTag })
    .select('id')
    .single()

  if (error) return { moodLogId: null, error: error.message }
  return { moodLogId: data.id, error: null }
}

export async function addJournalEntry({
  moodLogId,
  userId,
  body,
}: {
  moodLogId: string
  userId: string
  body: string
}): Promise<{ error: string | null }> {
  const { error } = await supabase
    .from('journal_entries')
    .insert({ mood_log_id: moodLogId, user_id: userId, body })

  return { error: error?.message ?? null }
}
