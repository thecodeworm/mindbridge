import type { ActivityTag, CopingSuggestion, JournalEntry, MoodLog, MoodTag } from '../../../../shared/types'
import { supabase } from './supabaseClient'

export interface HistoryEntry {
  id: string
  mood_score: number
  mood_tag: MoodTag
  logged_at: string
  technique_name: string | null
}

export async function getHistory(
  userId: string,
  { limit = 20, offset = 0 }: { limit?: number; offset?: number } = {},
): Promise<{ entries: HistoryEntry[]; error: string | null }> {
  const { data, error } = await supabase
    .from('mood_logs')
    .select('id, mood_score, mood_tag, logged_at, coping_suggestions(technique_name)')
    .eq('user_id', userId)
    .order('logged_at', { ascending: false })
    .range(offset, offset + limit - 1)

  if (error) return { entries: [], error: error.message }

  const entries: HistoryEntry[] = (data ?? []).map((row) => {
    const suggestion = row.coping_suggestions as unknown as { technique_name: string } | null
    return {
      id: row.id,
      mood_score: row.mood_score,
      mood_tag: row.mood_tag as MoodTag,
      logged_at: row.logged_at,
      technique_name: suggestion?.technique_name ?? null,
    }
  })

  return { entries, error: null }
}

export interface EntryDetail {
  moodLog: MoodLog
  journalEntry: JournalEntry | null
  copingSuggestion: CopingSuggestion | null
  activities: ActivityTag[]
}

// Every query filters on user_id as well as row id — RLS enforces this
// server-side; the explicit filter degrades a policy regression to "not found".
export async function getEntryDetail(
  moodLogId: string,
  userId: string,
): Promise<{ detail: EntryDetail | null; error: string | null }> {
  const [moodLogRes, journalRes, suggestionRes, activityRes] = await Promise.all([
    supabase
      .from('mood_logs')
      .select('id, user_id, mood_score, mood_tag, logged_at')
      .eq('id', moodLogId)
      .eq('user_id', userId)
      .single(),
    supabase
      .from('journal_entries')
      .select('id, mood_log_id, user_id, body, created_at')
      .eq('mood_log_id', moodLogId)
      .eq('user_id', userId)
      .maybeSingle(),
    supabase
      .from('coping_suggestions')
      .select(
        'id, mood_log_id, user_id, technique_name, description, steps, model_used, generated_at, crisis_signal, helpful, saved',
      )
      .eq('mood_log_id', moodLogId)
      .eq('user_id', userId)
      .maybeSingle(),
    supabase
      .from('mood_log_activities')
      .select('activity_tag_id, activity_tags(id, user_id, slug, label, emoji, created_at)')
      .eq('mood_log_id', moodLogId)
      .eq('user_id', userId),
  ])

  if (moodLogRes.error) return { detail: null, error: moodLogRes.error.message }

  const activities = ((activityRes.data ?? []) as unknown as Array<{ activity_tags: ActivityTag | null }>)
    .map((r) => r.activity_tags)
    .filter((t): t is ActivityTag => t != null)

  return {
    detail: {
      moodLog: moodLogRes.data as MoodLog,
      journalEntry: (journalRes.data as JournalEntry | null) ?? null,
      copingSuggestion: (suggestionRes.data as CopingSuggestion | null) ?? null,
      activities,
    },
    error: null,
  }
}

const NOT_FOUND = "We couldn't find that entry. It may have already been deleted."

export async function deleteEntry(
  moodLogId: string,
  userId: string,
): Promise<{ error: string | null }> {
  const { data, error } = await supabase
    .from('mood_logs')
    .delete()
    .eq('id', moodLogId)
    .eq('user_id', userId)
    .select('id')

  if (error) return { error: error.message }
  if (!data || data.length === 0) return { error: NOT_FOUND }
  return { error: null }
}

export async function updateEntry({
  moodLogId,
  userId,
  moodScore,
  moodTag,
  journalBody,
}: {
  moodLogId: string
  userId: string
  moodScore: number
  moodTag: MoodTag
  journalBody: string
}): Promise<{ error: string | null }> {
  const { data: updatedMood, error: moodError } = await supabase
    .from('mood_logs')
    .update({ mood_score: moodScore, mood_tag: moodTag })
    .eq('id', moodLogId)
    .eq('user_id', userId)
    .select('id')
  if (moodError) return { error: moodError.message }
  if (!updatedMood || updatedMood.length === 0) return { error: NOT_FOUND }

  const trimmed = journalBody.trim()
  const { data: existing, error: fetchError } = await supabase
    .from('journal_entries')
    .select('id')
    .eq('mood_log_id', moodLogId)
    .eq('user_id', userId)
    .maybeSingle()
  if (fetchError) return { error: fetchError.message }

  if (trimmed) {
    const { data, error } = existing
      ? await supabase
          .from('journal_entries')
          .update({ body: trimmed })
          .eq('id', existing.id)
          .eq('user_id', userId)
          .select('id')
      : await supabase
          .from('journal_entries')
          .insert({ mood_log_id: moodLogId, user_id: userId, body: trimmed })
          .select('id')
    if (error) return { error: error.message }
    if (!data || data.length === 0) return { error: NOT_FOUND }
  } else if (existing) {
    const { data, error } = await supabase
      .from('journal_entries')
      .delete()
      .eq('id', existing.id)
      .eq('user_id', userId)
      .select('id')
    if (error) return { error: error.message }
    if (!data || data.length === 0) return { error: NOT_FOUND }
  }

  return { error: null }
}
