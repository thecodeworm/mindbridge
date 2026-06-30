# MindBridge

One in five teenagers in the United States experiences a significant mental health challenge every year. Most never get help — not because resources don't exist, but because the barriers do: stigma, cost, and a fundamental lack of self-awareness about their own emotional patterns.

MindBridge is a cross-platform mood tracker built specifically for teens. It gives users a private, two-minute daily check-in that logs how they feel, detects patterns over time, and delivers an immediate, evidence-based coping technique powered by AI. No therapist required. No data shared with parents by default. No friction.

---

## What It Does

A user opens the app, moves a slider to rate their mood from 1 to 10, selects an emotion tag, and optionally writes a short journal entry. They hit submit. Within two seconds, the app returns a named Cognitive Behavioral Therapy technique — a breathing exercise, a grounding method, a reframing practice — with a plain-language description and three actionable steps. Every entry is saved. Over time, a dashboard surfaces mood trends across 7 and 30-day windows, making invisible emotional patterns visible.

The entire interaction takes under two minutes. That is intentional. Habit formation requires low friction. MindBridge is designed to be opened every day, not occasionally.

---

## Architecture

MindBridge is a monorepo with two client apps sharing a single Supabase backend.

```
apps/mobile/     Flutter 3.x (iOS + Android)
apps/web/        React 18 + Vite (browser)
shared/types/    TypeScript types shared across web and edge functions
supabase/        Postgres schema, RLS policies, Edge Functions, migrations
```

**Backend: Supabase**

All data lives in a Postgres database hosted on Supabase. Five core tables — `users`, `mood_logs`, `journal_entries`, `coping_suggestions`, and `ai_call_logs` — each protected by Row Level Security policies that make cross-user data access structurally impossible. There is no application-layer authorization check that could be bypassed: the database enforces it at the query level.

**AI: Anthropic Claude Haiku via Edge Function**

The AI layer is a single Supabase Edge Function (`generate-suggestion`) running on Deno. When a user submits a mood log, the client calls this function — never the Anthropic API directly. The function fetches the mood data, constructs a CBT-focused prompt that handles both journal and no-journal cases, calls Claude Haiku, parses the structured JSON response, and writes the result to `coping_suggestions` and `ai_call_logs` before returning the suggestion to the client. The Anthropic API key exists only in the Edge Function's environment variables. It is never bundled into either client app.

**Mobile: Flutter**

The Flutter app is the primary demo platform. It uses `supabase_flutter` for auth and data, `fl_chart` for mood trend visualization, and `flutter_secure_storage` for session persistence. All business logic delegates to Supabase — the Flutter app is intentionally thin.

**Web: React**

The React app achieves full feature parity with the Flutter app. Built with Vite, Tailwind CSS, React Router v6, and Recharts for the dashboard. Auth and data access go through `@supabase/supabase-js`. Deployed to Vercel.

---

## Data Model

```sql
users              (id uuid, display_name text, created_at timestamptz)
mood_logs          (id, user_id, mood_score int 1–10, mood_tag, logged_at)
journal_entries    (id, mood_log_id, user_id, body text max 500 chars, created_at)
coping_suggestions (id, mood_log_id 1:1, user_id, technique_name, description, steps jsonb, model_used, generated_at)
ai_call_logs       (id, user_id, input_tokens, output_tokens, latency_ms, called_at)
```

All foreign keys are enforced. `user_id` is duplicated on `journal_entries` and `coping_suggestions` to simplify RLS policy authoring without requiring joins in policy definitions.

---

## Security and Privacy

- Row Level Security is enabled on all five tables. The RLS audit — attempting cross-user reads before submission — is a required milestone gate.
- The Anthropic API key never appears in client-side code or build artifacts.
- Journal entries are stored encrypted at rest via Supabase's Postgres encryption layer.
- No third-party analytics SDKs transmit journal text off-device.
- Account deletion cascades across all tables.
- If a user's mood score falls below 3 for three or more consecutive days, a static crisis resource banner displays the 988 Suicide and Crisis Lifeline. This trigger is rule-based, not AI-generated.

---

## Performance Targets

| Metric | Target |
|---|---|
| AI suggestion latency | < 2 seconds on LTE |
| Dashboard chart render | < 1 second for 90 days of data |
| Flutter cold start | < 3 seconds on mid-range Android |

---

## Status

Active development. Built for the **2026 Congressional App Challenge, Texas District 22**. Submission deadline: August 2026.
