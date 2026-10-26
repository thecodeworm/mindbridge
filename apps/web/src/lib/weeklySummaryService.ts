import { supabase } from './supabaseClient'

function getWeekStart(date: Date): string {
  const d = new Date(date)
  const day = d.getDay()
  // Week starts Monday
  const diff = (day === 0 ? -6 : 1 - day)
  d.setDate(d.getDate() + diff)
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const dd = String(d.getDate()).padStart(2, '0')
  return `${y}-${m}-${dd}`
}

export function getCurrentWeekStart(): string {
  return getWeekStart(new Date())
}

export function getPreviousWeekStart(): string {
  const last = new Date()
  last.setDate(last.getDate() - 7)
  return getWeekStart(last)
}

export interface WeeklySummaryResult {
  summary: string
  highlights: string[]
  generated_at: string
  // True when the week's journals contained crisis language; the card then
  // points to the Help page. Absent on summaries cached before this existed.
  crisis_signal?: boolean
}

export async function getOrGenerateWeeklySummary(
  userId: string,
  weekStart: string,
  accessToken: string,
): Promise<{ summary: WeeklySummaryResult | null; error: string | null }> {
  // Check cache first
  const { data: cached } = await supabase
    .from('weekly_summaries')
    .select('summary, highlights, generated_at, crisis_signal')
    .eq('user_id', userId)
    .eq('week_start', weekStart)
    .maybeSingle()

  if (cached) {
    return {
      summary: {
        summary: cached.summary ?? '',
        highlights: (cached.highlights ?? []) as string[],
        generated_at: cached.generated_at,
        crisis_signal: cached.crisis_signal === true,
      },
      error: null,
    }
  }

  // Generate via edge function
  const supabaseUrl = import.meta.env.VITE_SUPABASE_URL as string
  const res = await fetch(`${supabaseUrl}/functions/v1/generate-weekly-summary`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${accessToken}`,
    },
    body: JSON.stringify({ user_id: userId, week_start: weekStart }),
  })

  if (!res.ok) {
    const body = await res.json().catch(() => ({}))
    return { summary: null, error: (body as { error?: string }).error ?? 'Failed to generate summary' }
  }

  const data = await res.json() as WeeklySummaryResult
  return { summary: data, error: null }
}
