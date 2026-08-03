import type { ActivityTag } from '../../../../shared/types'
import { supabase } from './supabaseClient'

export async function getActivityTags(): Promise<{ tags: ActivityTag[]; error: string | null }> {
  const { data, error } = await supabase
    .from('activity_tags')
    .select('id, user_id, slug, label, emoji, created_at')
    .order('label', { ascending: true })

  if (error) return { tags: [], error: error.message }
  return { tags: (data ?? []) as ActivityTag[], error: null }
}

export async function setEntryActivities(
  moodLogId: string,
  userId: string,
  tagIds: string[],
): Promise<{ error: string | null }> {
  const { error: deleteError } = await supabase
    .from('mood_log_activities')
    .delete()
    .eq('mood_log_id', moodLogId)
    .eq('user_id', userId)

  if (deleteError) return { error: deleteError.message }

  if (tagIds.length === 0) return { error: null }

  const { error: insertError } = await supabase
    .from('mood_log_activities')
    .insert(tagIds.map((id) => ({ mood_log_id: moodLogId, activity_tag_id: id, user_id: userId })))

  return { error: insertError?.message ?? null }
}

export async function getEntryActivities(
  moodLogId: string,
  userId: string,
): Promise<{ tags: ActivityTag[]; error: string | null }> {
  const { data, error } = await supabase
    .from('mood_log_activities')
    .select('activity_tag_id, activity_tags(id, user_id, slug, label, emoji, created_at)')
    .eq('mood_log_id', moodLogId)
    .eq('user_id', userId)

  if (error) return { tags: [], error: error.message }

  const tags = (data ?? [])
    .map((row) => (row as unknown as { activity_tags: ActivityTag | null }).activity_tags)
    .filter((t): t is ActivityTag => t != null)

  return { tags, error: null }
}

export interface LogWithActivities {
  moodLogId: string
  moodScore: number
  loggedAt: string
  activities: ActivityTag[]
}

export async function getLogsWithActivities(
  userId: string,
  days: number,
): Promise<{ entries: LogWithActivities[]; error: string | null }> {
  const since = new Date()
  since.setDate(since.getDate() - days)

  const { data, error } = await supabase
    .from('mood_logs')
    .select(
      'id, mood_score, logged_at, mood_log_activities(activity_tag_id, activity_tags(id, user_id, slug, label, emoji, created_at))',
    )
    .eq('user_id', userId)
    .gte('logged_at', since.toISOString())
    .order('logged_at', { ascending: true })

  if (error) return { entries: [], error: error.message }

  const entries: LogWithActivities[] = (data ?? []).map((row) => {
    const actRows = (row.mood_log_activities ?? []) as unknown as Array<{ activity_tags: ActivityTag | null }>
    const activities = actRows
      .map((a) => a.activity_tags)
      .filter((t): t is ActivityTag => t != null)
    return { moodLogId: row.id, moodScore: row.mood_score, loggedAt: row.logged_at, activities }
  })

  return { entries, error: null }
}
