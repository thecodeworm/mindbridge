import { createClient } from 'npm:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
}

const ANTHROPIC_API_KEY = Deno.env.get('ANTHROPIC_API_KEY')!
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

const MODEL = 'claude-haiku-4-5'

const SYSTEM_PROMPT = `You are a warm, supportive guide inside MindBridge, a mood-tracking app for teens. After a user logs their mood, you generate ONE simple CBT (Cognitive Behavioral Therapy) coping technique tailored to how they're feeling.

Rules:
- This is self-help guidance, not therapy or a clinical diagnosis. Never claim to diagnose or treat a condition.
- Keep the tone warm, direct, and age-appropriate for teens. No clinical jargon.
- Always return exactly 3 short, concrete steps the user can do right now — each one sentence.
- If the user included a journal entry, ground the technique in what they wrote. If they only gave a mood score and tag, choose a technique well-suited to that mood level — a score alone should still produce a genuinely useful suggestion.
- Set crisis_signal to true only if the journal entry suggests thoughts of self-harm, suicide, or being in crisis. Still provide a gentle, relevant technique in this case — never leave the response empty.
- Respond only with the requested JSON object.`

const RESPONSE_SCHEMA = {
  type: 'object',
  properties: {
    technique_name: { type: 'string' },
    description: { type: 'string' },
    steps: { type: 'array', items: { type: 'string' } },
    crisis_signal: { type: 'boolean' },
  },
  required: ['technique_name', 'description', 'steps', 'crisis_signal'],
  additionalProperties: false,
}

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { mood_log_id, user_id } = await req.json()
    if (!mood_log_id || !user_id) {
      return jsonResponse({ error: 'mood_log_id and user_id are required' }, 400)
    }

    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return jsonResponse({ error: 'Missing Authorization header' }, 401)
    }

    // User-JWT client — RLS scopes every read to the caller's own rows.
    const userClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: authHeader } },
    })

    const {
      data: { user },
      error: authError,
    } = await userClient.auth.getUser()

    if (authError || !user) {
      return jsonResponse({ error: 'Invalid or expired session' }, 401)
    }
    if (user.id !== user_id) {
      return jsonResponse({ error: 'user_id does not match authenticated user' }, 403)
    }

    // Service-role client — coping_suggestions/ai_call_logs have SELECT-only
    // RLS policies, so writes (and the idempotency read below) bypass RLS here.
    const serviceClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

    const { data: moodLog, error: moodLogError } = await userClient
      .from('mood_logs')
      .select('id, mood_score, mood_tag')
      .eq('id', mood_log_id)
      .single()

    if (moodLogError || !moodLog) {
      // RLS silently returns no rows for a mood log that isn't the caller's own.
      return jsonResponse({ error: 'Mood log not found' }, 404)
    }

    const { data: journalEntry } = await userClient
      .from('journal_entries')
      .select('body')
      .eq('mood_log_id', mood_log_id)
      .maybeSingle()

    // Idempotent: a mood log has at most one coping_suggestion (1:1, UNIQUE).
    const { data: existing } = await serviceClient
      .from('coping_suggestions')
      .select('technique_name, description, steps')
      .eq('mood_log_id', mood_log_id)
      .maybeSingle()

    if (existing) {
      return jsonResponse({
        technique_name: existing.technique_name,
        description: existing.description,
        steps: existing.steps,
        show_crisis_resources: moodLog.mood_score <= 2,
      })
    }

    const userMessage = `Mood score: ${moodLog.mood_score}/10
Mood tag: ${moodLog.mood_tag}
Journal entry: ${journalEntry?.body ? journalEntry.body : '(none provided)'}`

    const startedAt = Date.now()

    const anthropicRes = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        'x-api-key': ANTHROPIC_API_KEY,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: MODEL,
        max_tokens: 1024,
        system: SYSTEM_PROMPT,
        messages: [{ role: 'user', content: userMessage }],
        output_config: {
          format: { type: 'json_schema', schema: RESPONSE_SCHEMA },
        },
      }),
    })

    const latencyMs = Date.now() - startedAt

    if (!anthropicRes.ok) {
      const errText = await anthropicRes.text()
      console.error('Anthropic API error:', anthropicRes.status, errText)
      return jsonResponse({ error: 'Failed to generate suggestion' }, 502)
    }

    const anthropicData = await anthropicRes.json()
    const textBlock = anthropicData.content?.find((b: { type: string }) => b.type === 'text')

    let parsed: {
      technique_name: string
      description: string
      steps: string[]
      crisis_signal: boolean
    }
    try {
      parsed = JSON.parse(textBlock?.text ?? '')
    } catch {
      return jsonResponse({ error: 'Malformed suggestion response' }, 502)
    }

    if (
      !parsed.technique_name ||
      !parsed.description ||
      !Array.isArray(parsed.steps) ||
      parsed.steps.length !== 3
    ) {
      return jsonResponse({ error: 'Malformed suggestion response' }, 502)
    }

    const showCrisisResources = moodLog.mood_score <= 2 || parsed.crisis_signal === true

    const { error: insertSuggestionError } = await serviceClient
      .from('coping_suggestions')
      .insert({
        mood_log_id,
        user_id,
        technique_name: parsed.technique_name,
        description: parsed.description,
        steps: parsed.steps,
        model_used: MODEL,
      })

    if (insertSuggestionError) {
      console.error('Failed to insert coping_suggestion:', insertSuggestionError)
      return jsonResponse({ error: 'Failed to save suggestion' }, 500)
    }

    const usage = anthropicData.usage ?? {}
    const { error: insertLogError } = await serviceClient.from('ai_call_logs').insert({
      user_id,
      input_tokens: usage.input_tokens ?? 0,
      output_tokens: usage.output_tokens ?? 0,
      latency_ms: latencyMs,
    })

    if (insertLogError) {
      // Non-fatal — the suggestion was saved successfully; only the usage log failed.
      console.error('Failed to insert ai_call_log:', insertLogError)
    }

    return jsonResponse({
      technique_name: parsed.technique_name,
      description: parsed.description,
      steps: parsed.steps,
      show_crisis_resources: showCrisisResources,
    })
  } catch (err) {
    console.error('Unhandled error in generate-suggestion:', err)
    return jsonResponse({ error: 'Internal server error' }, 500)
  }
})
