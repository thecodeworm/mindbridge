export type MoodTag =
  | 'happy'
  | 'sad'
  | 'anxious'
  | 'angry'
  | 'tired'
  | 'calm'
  | 'confused'
  | 'meh'

export const MOOD_TAGS: { value: MoodTag; emoji: string; label: string }[] = [
  { value: 'happy',   emoji: '😊', label: 'Happy' },
  { value: 'calm',    emoji: '😌', label: 'Calm' },
  { value: 'meh',     emoji: '😐', label: 'Meh' },
  { value: 'sad',     emoji: '😢', label: 'Sad' },
  { value: 'anxious', emoji: '😰', label: 'Anxious' },
  { value: 'angry',   emoji: '😤', label: 'Angry' },
  { value: 'tired',   emoji: '😴', label: 'Tired' },
  { value: 'confused',emoji: '🤔', label: 'Confused' },
]

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

export interface CopingSuggestion {
  id: string
  mood_log_id: string
  user_id: string
  technique_name: string
  description: string
  steps: string[]
  model_used: string
  generated_at: string
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
