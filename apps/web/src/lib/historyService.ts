import type { CopingSuggestion, JournalEntry, MoodLog, MoodTag } from '../../../../shared/types'
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
}

export async function getEntryDetail(
  moodLogId: string,
): Promise<{ detail: EntryDetail | null; error: string | null }> {
  const [moodLogRes, journalRes, suggestionRes] = await Promise.all([
    supabase
      .from('mood_logs')
      .select('id, user_id, mood_score, mood_tag, logged_at')
      .eq('id', moodLogId)
      .single(),
    supabase
      .from('journal_entries')
      .select('id, mood_log_id, user_id, body, created_at')
      .eq('mood_log_id', moodLogId)
      .maybeSingle(),
    supabase
      .from('coping_suggestions')
      .select('id, mood_log_id, user_id, technique_name, description, steps, model_used, generated_at')
      .eq('mood_log_id', moodLogId)
      .maybeSingle(),
  ])

  if (moodLogRes.error) return { detail: null, error: moodLogRes.error.message }

  return {
    detail: {
      moodLog: moodLogRes.data as MoodLog,
      journalEntry: (journalRes.data as JournalEntry | null) ?? null,
      copingSuggestion: (suggestionRes.data as CopingSuggestion | null) ?? null,
    },
    error: null,
  }
}

export async function deleteEntry(moodLogId: string): Promise<{ error: string | null }> {
  // journal_entries and coping_suggestions cascade-delete via their
  // mood_log_id FK — see 0001_init_schema.sql.
  const { error } = await supabase.from('mood_logs').delete().eq('id', moodLogId)
  return { error: error?.message ?? null }
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
  const { error: moodError } = await supabase
    .from('mood_logs')
    .update({ mood_score: moodScore, mood_tag: moodTag })
    .eq('id', moodLogId)
  if (moodError) return { error: moodError.message }

  const trimmed = journalBody.trim()

  // journal_entries.mood_log_id has no unique constraint (it's not 1:1 at
  // the schema level like coping_suggestions is), so there's no upsert
  // conflict target — look up the existing row by hand instead.
  const { data: existing, error: fetchError } = await supabase
    .from('journal_entries')
    .select('id')
    .eq('mood_log_id', moodLogId)
    .maybeSingle()
  if (fetchError) return { error: fetchError.message }

  if (trimmed) {
    const { error } = existing
      ? await supabase.from('journal_entries').update({ body: trimmed }).eq('id', existing.id)
      : await supabase
          .from('journal_entries')
          .insert({ mood_log_id: moodLogId, user_id: userId, body: trimmed })
    if (error) return { error: error.message }
  } else if (existing) {
    const { error } = await supabase.from('journal_entries').delete().eq('id', existing.id)
    if (error) return { error: error.message }
  }

  return { error: null }
}
