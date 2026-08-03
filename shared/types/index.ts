export type MoodQuadrant = 'high-pleasant' | 'high-unpleasant' | 'low-pleasant' | 'low-unpleasant'

export type MoodTag =
  | 'excited' | 'happy' | 'energized' | 'proud' | 'grateful' | 'hopeful'
  | 'anxious' | 'angry' | 'stressed' | 'frustrated' | 'overwhelmed' | 'irritated'
  | 'calm' | 'content' | 'relaxed' | 'peaceful' | 'focused' | 'satisfied'
  | 'sad' | 'tired' | 'confused' | 'meh' | 'lonely' | 'bored'

export interface MoodTagEntry {
  quadrant: MoodQuadrant
  value: MoodTag
  emoji: string
  label: string
}

export const MOOD_TAGS: MoodTagEntry[] = [
  // High energy + pleasant
  { quadrant: 'high-pleasant', value: 'excited',     emoji: '🤩', label: 'Excited' },
  { quadrant: 'high-pleasant', value: 'happy',       emoji: '😊', label: 'Happy' },
  { quadrant: 'high-pleasant', value: 'energized',   emoji: '⚡', label: 'Energized' },
  { quadrant: 'high-pleasant', value: 'proud',       emoji: '💪', label: 'Proud' },
  { quadrant: 'high-pleasant', value: 'grateful',    emoji: '🙏', label: 'Grateful' },
  { quadrant: 'high-pleasant', value: 'hopeful',     emoji: '🌟', label: 'Hopeful' },
  // High energy + unpleasant
  { quadrant: 'high-unpleasant', value: 'anxious',     emoji: '😰', label: 'Anxious' },
  { quadrant: 'high-unpleasant', value: 'angry',       emoji: '😤', label: 'Angry' },
  { quadrant: 'high-unpleasant', value: 'stressed',    emoji: '😫', label: 'Stressed' },
  { quadrant: 'high-unpleasant', value: 'frustrated',  emoji: '😣', label: 'Frustrated' },
  { quadrant: 'high-unpleasant', value: 'overwhelmed', emoji: '🌀', label: 'Overwhelmed' },
  { quadrant: 'high-unpleasant', value: 'irritated',   emoji: '😒', label: 'Irritated' },
  // Low energy + pleasant
  { quadrant: 'low-pleasant', value: 'calm',        emoji: '😌', label: 'Calm' },
  { quadrant: 'low-pleasant', value: 'content',     emoji: '🙂', label: 'Content' },
  { quadrant: 'low-pleasant', value: 'relaxed',     emoji: '😮‍💨', label: 'Relaxed' },
  { quadrant: 'low-pleasant', value: 'peaceful',    emoji: '🕊️', label: 'Peaceful' },
  { quadrant: 'low-pleasant', value: 'focused',     emoji: '🎯', label: 'Focused' },
  { quadrant: 'low-pleasant', value: 'satisfied',   emoji: '✨', label: 'Satisfied' },
  // Low energy + unpleasant
  { quadrant: 'low-unpleasant', value: 'sad',       emoji: '😢', label: 'Sad' },
  { quadrant: 'low-unpleasant', value: 'tired',     emoji: '😴', label: 'Tired' },
  { quadrant: 'low-unpleasant', value: 'confused',  emoji: '🤔', label: 'Confused' },
  { quadrant: 'low-unpleasant', value: 'meh',       emoji: '😐', label: 'Meh' },
  { quadrant: 'low-unpleasant', value: 'lonely',    emoji: '🫂', label: 'Lonely' },
  { quadrant: 'low-unpleasant', value: 'bored',     emoji: '😑', label: 'Bored' },
]

export const MOOD_QUADRANTS: { value: MoodQuadrant; label: string; emoji: string }[] = [
  { value: 'high-pleasant',   label: 'Feeling good & activated', emoji: '✨' },
  { value: 'high-unpleasant', label: 'Activated but struggling', emoji: '⚡' },
  { value: 'low-pleasant',    label: 'Calm & at ease',           emoji: '🌿' },
  { value: 'low-unpleasant',  label: 'Low & drained',            emoji: '🌧️' },
]

export function moodTagInfo(value: string): MoodTagEntry | undefined {
  return MOOD_TAGS.find((t) => t.value === value)
}

export interface MoodLog {
  id: string
  user_id: string
  mood_score: number
  mood_tag: MoodTag
  logged_at: string
}

export interface JournalEntry {
  id: string
  mood_log_id: string
  user_id: string
  body: string
  created_at: string
}

export interface ActivityTag {
  id: string
  user_id: string | null
  slug: string
  label: string
  emoji: string
  created_at: string
}

export interface MoodLogActivity {
  mood_log_id: string
  activity_tag_id: string
  user_id: string
}

export interface CopingSuggestion {
  id: string
  mood_log_id: string
  user_id: string
  technique_name: string
  description: string
  steps: string[]
  model_used: string
  generated_at: string
  crisis_signal: boolean
  helpful: boolean | null
  saved: boolean
}

export interface AiCallLog {
  id: string
  user_id: string
  input_tokens: number
  output_tokens: number
  latency_ms: number
  called_at: string
}

export interface SuggestionResponse {
  technique_name: string
  description: string
  steps: string[]
  show_crisis_resources: boolean
}

export interface WeeklySummary {
  id: string
  user_id: string
  week_start: string
  summary: string
  highlights: string[]
  model_used: string
  generated_at: string
}
