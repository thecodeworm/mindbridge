import { assertEquals } from 'jsr:@std/assert@1'
import { stub } from 'jsr:@std/testing@1/mock'
import { callClaude } from './anthropic.ts'

const BASE_PARAMS = {
  apiKey: 'test-key',
  model: 'claude-haiku-test',
  maxTokens: 256,
  systemPrompt: 'system',
  userMessage: 'user',
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status })
}

Deno.test('callClaude - parses a clean JSON text response on success', async () => {
  using _fetch = stub(
    globalThis,
    'fetch',
    () =>
      Promise.resolve(
        jsonResponse({
          content: [{
            type: 'text',
            text: '{"technique_name":"Box breathing"}',
          }],
          usage: { input_tokens: 10, output_tokens: 20 },
        }),
      ),
  )

  const result = await callClaude(BASE_PARAMS)

  assertEquals(result.ok, true)
  if (result.ok) {
    assertEquals(result.parsed, { technique_name: 'Box breathing' })
    assertEquals(result.usage, { input_tokens: 10, output_tokens: 20 })
  }
})

Deno.test('callClaude - strips a markdown JSON fence before parsing', async () => {
  using _fetch = stub(
    globalThis,
    'fetch',
    () =>
      Promise.resolve(
        jsonResponse({
          content: [{
            type: 'text',
            text: '```json\n{"technique_name":"Grounding"}\n```',
          }],
          usage: {},
        }),
      ),
  )

  const result = await callClaude(BASE_PARAMS)

  assertEquals(result.ok, true)
  if (result.ok) {
    assertEquals(result.parsed, { technique_name: 'Grounding' })
  }
})

Deno.test('callClaude - maps stop_reason "refusal" to a refusal failure', async () => {
  using _fetch = stub(
    globalThis,
    'fetch',
    () =>
      Promise.resolve(
        jsonResponse({
          stop_reason: 'refusal',
          usage: { input_tokens: 5, output_tokens: 0 },
        }),
      ),
  )

  const result = await callClaude(BASE_PARAMS)

  assertEquals(result.ok, false)
  if (!result.ok) {
    assertEquals(result.reason, 'refusal')
    assertEquals(result.usage, { input_tokens: 5, output_tokens: 0 })
  }
})

Deno.test('callClaude - maps a non-ok HTTP response to a request_failed failure', async () => {
  using _fetch = stub(
    globalThis,
    'fetch',
    () => Promise.resolve(new Response('server error', { status: 500 })),
  )

  const result = await callClaude(BASE_PARAMS)

  assertEquals(result.ok, false)
  if (!result.ok) {
    assertEquals(result.reason, 'request_failed')
    assertEquals(result.usage, {})
  }
})

Deno.test('callClaude - maps unparseable text to a malformed_json failure', async () => {
  using _fetch = stub(
    globalThis,
    'fetch',
    () =>
      Promise.resolve(
        jsonResponse({
          content: [{ type: 'text', text: 'not json at all' }],
          usage: {},
        }),
      ),
  )

  const result = await callClaude(BASE_PARAMS)

  assertEquals(result.ok, false)
  if (!result.ok) {
    assertEquals(result.reason, 'malformed_json')
  }
})

Deno.test('callClaude - latencyMs is populated on both success and failure paths', async () => {
  using _fetch = stub(
    globalThis,
    'fetch',
    () => Promise.resolve(new Response('nope', { status: 500 })),
  )

  const result = await callClaude(BASE_PARAMS)
  assertEquals(typeof result.latencyMs, 'number')
})

Deno.test('callClaude - extracts the JSON object when Claude adds text around it', async () => {
  using _fetch = stub(
    globalThis,
    'fetch',
    () =>
      Promise.resolve(
        jsonResponse({
          content: [{
            type: 'text',
            text:
              'I hear you.\n{"technique_name":"Grounding"}\nPlease reach out to 988.',
          }],
          usage: {},
        }),
      ),
  )

  const result = await callClaude(BASE_PARAMS)

  assertEquals(result.ok, true)
  if (result.ok) {
    assertEquals(result.parsed, { technique_name: 'Grounding' })
  }
})
