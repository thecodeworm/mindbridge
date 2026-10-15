import { assertEquals } from 'jsr:@std/assert@1'
import { buildCorsHeaders, makeJsonResponse } from './cors.ts'

Deno.test('buildCorsHeaders - echoes back a known dev origin', () => {
  const headers = buildCorsHeaders('http://localhost:5173')
  assertEquals(headers['Access-Control-Allow-Origin'], 'http://localhost:5173')
  assertEquals(headers['Vary'], 'Origin')
})

Deno.test('buildCorsHeaders - falls back to the default origin for an unknown origin', () => {
  const headers = buildCorsHeaders('https://evil.example.com')
  assertEquals(headers['Access-Control-Allow-Origin'], 'http://localhost:5173')
})

Deno.test('buildCorsHeaders - allows a matching Vercel preview deployment origin', () => {
  const headers = buildCorsHeaders('https://usemindbridge-abc123.vercel.app')
  assertEquals(
    headers['Access-Control-Allow-Origin'],
    'https://usemindbridge-abc123.vercel.app',
  )
})

Deno.test('buildCorsHeaders - allows the production Vercel origin with no hash suffix', () => {
  const headers = buildCorsHeaders('https://usemindbridge.vercel.app')
  assertEquals(
    headers['Access-Control-Allow-Origin'],
    'https://usemindbridge.vercel.app',
  )
})

Deno.test('buildCorsHeaders - rejects a non-vercel lookalike domain', () => {
  const headers = buildCorsHeaders('https://usemindbridge.vercel.app.evil.com')
  assertEquals(headers['Access-Control-Allow-Origin'], 'http://localhost:5173')
})

Deno.test('buildCorsHeaders - falls back to the default origin for a null origin', () => {
  const headers = buildCorsHeaders(null)
  assertEquals(headers['Access-Control-Allow-Origin'], 'http://localhost:5173')
})

Deno.test('makeJsonResponse - defaults to status 200', async () => {
  const json = makeJsonResponse({ 'X-Test': '1' })
  const res = json({ ok: true })
  assertEquals(res.status, 200)
  assertEquals(res.headers.get('Content-Type'), 'application/json')
  assertEquals(res.headers.get('X-Test'), '1')
  assertEquals(await res.json(), { ok: true })
})

Deno.test('makeJsonResponse - passes through a custom status', () => {
  const json = makeJsonResponse({})
  const res = json({ error: 'nope' }, 403)
  assertEquals(res.status, 403)
})
