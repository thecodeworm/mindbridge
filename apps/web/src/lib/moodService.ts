import { friendlyError } from './friendlyError'
import type { MoodLog, MoodTag } from '../../../../shared/types'
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

  if (error) return { moodLogId: null, error: friendlyError(error.message) }
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

  return { error: (error ? friendlyError(error.message) : null) }
}

export async function getMoodLogsInRange(
  userId: string,
  days: number,
): Promise<{ logs: MoodLog[]; error: string | null }> {
  const since = new Date()
  since.setDate(since.getDate() - days)

  const { data, error } = await supabase
    .from('mood_logs')
    .select('id, user_id, mood_score, mood_tag, logged_at')
    .eq('user_id', userId)
    .gte('logged_at', since.toISOString())
    .order('logged_at', { ascending: true })

  if (error) return { logs: [], error: friendlyError(error.message) }
  return { logs: (data ?? []) as MoodLog[], error: null }
}
