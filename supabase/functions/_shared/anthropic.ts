// Edge Functions have their own wall-clock limit; fail well before it so the
// caller can answer the client instead of being killed mid-request.
const REQUEST_TIMEOUT_MS = 25_000

export interface CallClaudeParams {
  apiKey: string
  model: string
  maxTokens: number
  systemPrompt: string
  userMessage: string
  // Omit to skip Anthropic's structured-output mode (plain-text JSON,
  // relying on prompt instructions + the caller's own shape validation).
  // Structured output guarantees schema-valid JSON but adds latency from
  // constrained decoding -- generate-suggestion dropped it for that reason,
  // see docs/backend/generate-suggestion.md Part 1.
  responseSchema?: Record<string, unknown>
}

export type Usage = { input_tokens?: number; output_tokens?: number }

export type CallClaudeResult =
  | { ok: true; parsed: unknown; usage: Usage; latencyMs: number }
  | {
    ok: false
    reason: 'request_failed' | 'refusal' | 'malformed_json'
    usage: Usage
    latencyMs: number
  }

// Calls Claude with a JSON-schema-constrained response, and handles the
// request/refusal/parse failure cases every caller needs to check. Schema
// validation of the parsed shape is caller-specific and stays with the caller.
export async function callClaude(
  params: CallClaudeParams,
): Promise<CallClaudeResult> {
  const {
    apiKey,
    model,
    maxTokens,
    systemPrompt,
    userMessage,
    responseSchema,
  } = params
  const startedAt = Date.now()

  let res: Response
  try {
    res = await fetch('https://api.anthropic.com/v1/messages', {
      signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model,
        max_tokens: maxTokens,
        system: systemPrompt,
        messages: [{ role: 'user', content: userMessage }],
        ...(responseSchema
          ? {
            output_config: {
              format: { type: 'json_schema', schema: responseSchema },
            },
          }
          : {}),
      }),
    })
  } catch (err) {
    // Timeout or network failure: report it like any other failed request so
    // the caller still finishes its ai_call_logs reservation.
    console.error('Anthropic request threw:', err)
    return {
      ok: false,
      reason: 'request_failed',
      usage: {},
      latencyMs: Date.now() - startedAt,
    }
  }

  const latencyMs = Date.now() - startedAt

  if (!res.ok) {
    const errText = await res.text()
    console.error('Anthropic API error:', res.status, errText)
    return { ok: false, reason: 'request_failed', usage: {}, latencyMs }
  }

  const data = await res.json()

  if (data.stop_reason === 'refusal') {
    return { ok: false, reason: 'refusal', usage: data.usage ?? {}, latencyMs }
  }

  const textBlock = data.content?.find((b: { type: string }) =>
    b.type === 'text'
  )

  // Without structured-output mode, Claude occasionally wraps the JSON in a
  // markdown code fence despite being told not to -- strip one if present
  // before parsing. A no-op when structured output is used (responseSchema
  // set), since that mode never produces fences.
  const rawText = (textBlock?.text ?? '').trim()
  const fenced = rawText.match(/^```(?:json)?\s*([\s\S]*?)\s*```$/)
  const jsonText = fenced ? fenced[1] : rawText

  let parsed: unknown
  try {
    parsed = JSON.parse(jsonText)
  } catch {
    // Claude sometimes adds a sentence around the object (most often a
    // pointer to crisis resources when a journal mentions self-harm), so
    // fall back to the outermost {...} span before giving up.
    const start = jsonText.indexOf('{')
    const end = jsonText.lastIndexOf('}')
    if (start !== -1 && end > start) {
      try {
        parsed = JSON.parse(jsonText.slice(start, end + 1))
        return { ok: true, parsed, usage: data.usage ?? {}, latencyMs }
      } catch {
        // fall through to malformed_json
      }
    }
    return {
      ok: false,
      reason: 'malformed_json',
      usage: data.usage ?? {},
      latencyMs,
    }
  }

  return { ok: true, parsed, usage: data.usage ?? {}, latencyMs }
}
