# MindBridge

MindBridge is a mood tracker for teenagers. You rate how you feel, pick a word for it, and write a few lines if you want to. The app gives you back one coping technique from cognitive behavioral therapy (CBT), picked for what you just told it. Over time it shows how your mood moves through the week and which activities seem to help.

I built it for the 2026 Congressional App Challenge in Texas's 22nd district (TX-22).

Live web app: https://usemindbridge.vercel.app

## Contents

1. [Why I built it](#why-i-built-it)
2. [Who it's for](#who-its-for)
3. [Features](#features)
4. [How it's built](#how-its-built)
5. [Repository layout](#repository-layout)
6. [A first session](#a-first-session)
7. [Database](#database)
8. [Security and privacy](#security-and-privacy)
9. [Testing](#testing)
10. [Known limitations](#known-limitations)

## Why I built it

Roughly one in five US teenagers deals with a serious mental health issue in a given year, and many never get help. Part of it is stigma and cost. Part of it is not noticing your own patterns until things are already bad.

Most mental health apps are made for adults. They feel clinical or ask for a lot up front, like long questionnaires, a subscription, or a parent's sign-off. I wanted one where you open it, say how you feel, and get something useful back.

It doesn't replace a therapist or a school counselor. I see it as a low-pressure way to check in with yourself each day, pick up a coping skill, and notice if things start sliding so you can ask for help sooner.

## Who it's for

Teenagers, roughly 13 to 19, who want a private place to track their mood. That shaped a few decisions:

- Nothing is sent to parents or schools.
- The tone is warm and plain. Errors never use red, and no color labels a day as good or bad.
- A check-in takes under two minutes, so it's easy to do every day.
- Crisis resources (988 Suicide and Crisis Lifeline, Crisis Text Line, The Trevor Project) are one tap away through the pink Help chip. They don't show up as a warning banner.

## Features

**Landing and onboarding.** New visitors see a landing page that explains the app before asking for an email. Onboarding is five short steps: welcome, what's private, a couple of optional personalization questions, how check-ins work, and a first check-in. The suggestion shown there is a sample written ahead of time, not one from Claude, so you can see what the app does before making an account.

**Check-ins.** Rate your mood from 1 to 10 on a slider and pick an emotion word from a Mood Meter style picker (24 words across four quadrants of energy and pleasantness). Optionally you can tag what you were doing (12 built-in tags like school, exercise, or poor sleep, plus your own), write up to 500 characters in a ruled journal, and flag a thinking trap you noticed, like catastrophizing or mind reading, with a short reframe.

**AI coping suggestion.** When you submit, a Supabase Edge Function sends your score, emotion word, and journal entry to Claude Haiku. It returns a named CBT technique, a short description, and three steps you can try right away. While it loads, the app shows quick tips. If your score is 2 or lower, your journal contains one of a list of crisis phrases, or the model flags the entry, crisis resources appear automatically. Nothing written in the journal can stop them from showing.

**Today.** The app has four tabs: Today, Journal, Insights, and Toolkit. Today asks how you're doing, with five mood-colored dots you can tap to start a check-in. After you check in, it shows your mood and the technique you got. Below that is the past week as a row of colored dots, plus a practice window that counts how many of the last 10 days you checked in. It doesn't reset to zero when you miss a day.

**Insights.** A 7-day or 30-day mood chart, a weekly summary, a "what lifts you" card that shows which activities tend to go with better or worse moods for you (once there's enough data), and a year-in-pixels grid with one square per day you logged.

**Journal and Toolkit.** Every past entry can be opened to see the mood, tags, journal text, and the suggestion you got. You can rate a suggestion as helpful or not and save it to your Toolkit to find later.

**Weekly summary.** On request, Claude Haiku writes a short reflection on your week with two or three highlights. It's generated once per week and saved.

**Settings.** Display name, light, dark, or system theme, JSON export of your data, deleting all your mood data, and deleting your account. The mobile app also has a daily reminder time and a biometric or PIN lock.

**Design.** The look is a clean notebook page with one ballpoint-blue accent. Mood colors work like highlighter pens: lavender, sky, butter, tangerine, and pink from low to high. There's no red-to-green scale. Errors use a muted berry instead of red. Dark mode gets the same attention as light mode, since a lot of journaling happens at night.

## How it's built

A monorepo with two client apps and one shared backend.

| Layer | Stack |
|---|---|
| Mobile | Flutter (Dart SDK ^3.12.2, tested against Flutter 3.44.4 in CI) |
| Web | React 19, Vite, TypeScript, Tailwind CSS v4, React Router v7 |
| Charts | fl_chart (mobile), Recharts (web) |
| Backend | Supabase: Postgres, Auth, Row Level Security, Edge Functions (Deno) |
| AI | Claude Haiku (`claude-haiku-5-5`), called only from Edge Functions |
| Hosting | Vercel (web), TestFlight and Play Store (mobile) |
| CI | GitHub Actions, with path filters so a web-only change doesn't rebuild the mobile app |

The Anthropic API key only exists in the Edge Function environment. Neither client holds business logic. The Edge Functions own the AI prompts and write all AI-generated data to the database.

I built the Flutter and React apps side by side, one feature at a time, so they stay at feature parity. The one exception was the visual redesign, which went to Flutter first because it's the demo platform, then to web.

## Repository layout

```
mindbridge/
├── apps/
│   ├── mobile/              Flutter app (iOS, Android, web)
│   │   ├── lib/
│   │   │   ├── core/        theme tokens, pure logic (streaks, crisis rules, mood color), env config
│   │   │   ├── widgets/     shared UI (mood slider, breathing circle, notebook widgets)
│   │   │   └── features/    one folder per area: onboarding, auth, mood, dashboard, history, settings, toolkit, help
│   │   └── test/            unit and widget tests
│   └── web/
│       └── src/
│           ├── pages/       one file per route
│           ├── components/  shared UI, mirroring the mobile widgets
│           ├── features/    onboarding flow
│           ├── lib/         Supabase calls and pure logic
│           └── context/     auth context
├── shared/
│   └── types/               TypeScript types shared by the web app and Edge Functions
├── supabase/
│   ├── functions/
│   │   ├── _shared/                     helpers shared across functions
│   │   ├── generate-suggestion/         coping suggestion for one check-in
│   │   ├── generate-weekly-summary/     weekly summary
│   │   └── delete-account/              deletes a user's account and data
│   ├── migrations/          SQL migrations, applied in filename order
│   ├── qa/                  scripts that seed test and demo accounts
│   └── seed.sql
└── qa/
    └── web/                 headless browser script that walks through the app
```

## A first session

You land on the homepage, tap "Get started," and go through the five onboarding screens. The personalization questions only change some wording, and you can skip them. On the last screen you drag the mood slider, pick an emotion word, and see a sample coping technique. Then you create an account with email or Google, and the app offers to save that first check-in. After sign-up, suggestions come from Claude.

On a regular day you open the app, check in, and read your suggestion. Now and then you can look at Insights for your trend or generate a weekly summary. If a technique helped, you save it to your Toolkit. If a check-in trips the crisis rule, crisis resources come up on their own, and the Help chip is there either way.

## Database

All data lives in Postgres with Row Level Security enforced by the database itself. Even if one of the apps had a bug, the database would still refuse to let one user read or write another user's rows.

Core tables:

```
users               one row per account: id, display name, created_at
mood_logs           mood score (1 to 10), emotion tag, logged_at
journal_entries     optional entry for a mood log, max 500 characters
coping_suggestions  the AI response: technique name, description, three steps
ai_call_logs        every Claude call: token counts, latency, timestamp
```

Later features added `activity_tags` and `mood_log_activities` for activity tagging, `weekly_summaries` for the weekly summary, and extra columns on `journal_entries` for thinking traps. There are 16 migrations in `supabase/migrations/`.

## Security and privacy

- Every table has Row Level Security tied to `auth.uid()`, so users can only touch their own rows. CI checks this on every schema change.
- The Anthropic API key only exists in the Edge Function environment and never reaches either client app.
- Your mood score, emotion word, and journal text are sent to Anthropic's API to generate your suggestion. Nothing goes to parents or schools.
- Journal text goes into the AI prompt wrapped in a tag, and the system prompt tells the model to treat everything inside it as data, not instructions. That helps against prompt injection, but I wouldn't call it a complete guarantee.
- Crisis resources show when the score is 2 or lower, when the journal contains any of about 30 crisis phrases (checked on the server), or when the model flags the entry. Journal text can only add to that, never remove it.
- Both AI functions cap each account at 30 calls per hour and 100 per day, and there's an overall daily cap across all users, so a buggy or malicious client can't run up the API bill.
- Passwords must be at least 8 characters.
- A password reset link only lets you set a new password. You don't get into the rest of the app until you've done that.

## Testing

The mobile app has unit and widget tests in `apps/mobile/test/`, covering streak math, crisis detection, mood colors, and some of the more involved widgets.

The web app has a headless end-to-end script, `qa/web/golden_path.py`, that signs in and walks through Today, Insights, Journal, entry detail, dark mode, Help, and Toolkit, checking that each one renders and works.

`supabase/qa/seed_qa_demo_user.py` creates a test account with weeks of realistic mood history. It inserts pre-written coping suggestions instead of calling Claude, so seeding a demo account doesn't use API credits.

CI runs on every push and pull request to `main` and `dev`, and only runs the parts that changed. It does these checks:

- Web: lint, tests, build, and an `npm audit` for high severity advisories.
- Mobile: `flutter analyze`, tests, and a debug APK build.
- Edge Functions: Deno type check, lint, format check, and tests for the shared helpers.
- Database: applies every migration to a temporary Postgres database, confirms Row Level Security is on for all 8 tables, and checks that one user can't read another's rows.
- A check that no `.env` file is tracked in git.

## Known limitations

- AI suggestions take about 3.5 to 6 seconds with `claude-haiku-5-5` in production testing, over my 2 second target. The quick tips cover the wait, but it's still slower than I'd like.
- The crisis phrase check is a keyword list. It can miss indirect wording, so it isn't a substitute for the Help chip or for someone noticing.
- There's no offline mode. Every screen needs a connection.
- Emails like password resets come from Supabase's default sender. A branded sender needs a custom domain and email provider, which I haven't set up yet.
- In the Flutter app, keyboard and switch access focus outlines are on text inputs but not yet on every button and chip.
