const ALLOWED_ORIGINS = (Deno.env.get('ALLOWED_ORIGINS') ?? '')
  .split(',')
  .map((origin) => origin.trim())
  .filter(Boolean)

// Dev fallback so local Vite/Flutter-web runs keep working without an env var.
const DEV_ORIGINS = [
  'http://localhost:5173',
  'http://localhost:5174',
  'http://localhost:5175',
  'http://localhost:3000',
]

export function buildCorsHeaders(requestOrigin: string | null) {
  const allowed = [...ALLOWED_ORIGINS, ...DEV_ORIGINS]
  // Scoped to this project's own Vercel deployments only (production is
  // usemindbridge.vercel.app; preview deploys are usemindbridge-<hash>.vercel.app)
  // -- a bare `*.vercel.app` regex would allow any Vercel-hosted app, not just ours.
  const isVercelPreview = requestOrigin !== null &&
    /^https:\/\/usemindbridge(-[a-z0-9-]+)?\.vercel\.app$/.test(requestOrigin)
  const allowOrigin =
    requestOrigin && (allowed.includes(requestOrigin) || isVercelPreview)
      ? requestOrigin
      : allowed[0] ?? ''

  return {
    'Access-Control-Allow-Origin': allowOrigin,
    'Access-Control-Allow-Headers':
      'authorization, x-client-info, apikey, content-type',
    'Vary': 'Origin',
  }
}

export function makeJsonResponse(corsHeaders: Record<string, string>) {
  return (body: unknown, status = 200) =>
    new Response(JSON.stringify(body), {
      status,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
}
