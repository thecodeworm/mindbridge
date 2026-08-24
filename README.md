# MindBridge

**This is not the main MindBridge repo. That's a private repo that I will contiunue building on. This is the Hackathon Checkpoint.**

MindBridge is a mood tracker built for teenagers. You log how you're feeling in under two minutes, and an AI assistant gives you back one simple coping technique based on what you wrote, right away. Over time it also shows you patterns: how your mood moves through the week, what activities seem to help or hurt, and how long you've kept up the habit.

It was built for the 2026 Congressional App Challenge, Texas's 22nd Congressional District (TX-22).

Live web app: https://usemindbridge.vercel.app

## Table of contents

1. [The problem this solves](#the-problem-this-solves)
2. [Who it's for](#who-its-for)
3. [What the app actually does](#what-the-app-actually-does)
4. [How it's built](#how-its-built)
5. [Repository layout](#repository-layout)
6. [Getting it running yourself](#getting-it-running-yourself)
7. [Configuration reference](#configuration-reference)
8. [Using the app: a walkthrough](#using-the-app-a-walkthrough)
9. [Database schema](#database-schema)
10. [Security and privacy](#security-and-privacy)
11. [Testing and QA](#testing-and-qa)
12. [Known limitations](#known-limitations)
13. [Further documentation](#further-documentation)
14. [About this project](#about-this-project)

## The problem this solves

About one in five teenagers in the US deals with a serious mental health issue in a given year, and most of them never get help. It's rarely because nothing is available. It's stigma, it's cost, and honestly it's often just that a teenager has no easy way to notice their own patterns until something has already gotten bad.

Most mental health apps are built for adults, feel clinical, or ask for way too much up front (long assessments, a subscription, a parent's involvement). MindBridge tries to remove almost all of that friction. You open the app, you say how you feel, and you get something useful back immediately. No therapist required, no diagnosis, no waiting.

The goal isn't to replace therapy or a counselor. It's to give someone a low-stakes way to check in with themselves daily, learn a coping skill from cognitive behavioral therapy (CBT) in the moment they need it, and build enough self-awareness over weeks and months to notice when things are trending in a bad direction, and get themselves help sooner if they need it.

## Who it's for

The primary user is a teenager, roughly 13 to 19, who wants a private space to track their mood without anyone else seeing it by default. A few things followed directly from that:

- Nothing in the app auto-shares data with parents or schools. It's the teen's data, kept private.
- The tone had to be warm and non-clinical. No red error banners, no chart lines that turn green when you're "good" and red when you're "bad." A bad day is not treated as a failure state.
- The whole first interaction (mood score, an emotion word, and getting a coping suggestion back) needed to take under two minutes, because a habit that takes effort to start doesn't survive as a daily habit.
- Crisis resources (the 988 Suicide and Crisis Lifeline, Crisis Text Line, and the Trevor Project) are always one tap away, not buried in a menu, and never presented in a way that feels alarming.

## What the app actually does

**Landing and onboarding.** A new visitor sees an actual marketing page first, not a login wall. It explains what the app does in plain language before asking for an email address. From there a short five step walkthrough (welcome, a privacy explanation, a couple of personalization questions, a "here's how this works" explainer, and then a real first mood check-in) gets someone to their first coping suggestion before they've even finished creating an account.

**Mood logging.** The core loop: drag a slider from 1 to 10 to rate your mood (the slider itself has some spring physics to it and changes color as you drag, so it feels more like a real object than a form input), pick an emotion word from a Mood Meter style picker (24 words split across four quadrants of energy and pleasantness), optionally tag what you were doing (school, exercise, friends, poor sleep, and so on, with 12 built-in tags and support for custom ones), optionally write a journal entry up to 500 characters, and optionally flag a cognitive distortion you noticed in your own thinking (catastrophizing, all-or-nothing thinking, mind reading, and a few others) along with a short reframe of that thought.

**AI coping suggestion.** The moment you submit a mood log, the app calls a Supabase Edge Function, which in turn calls Claude Haiku with your mood score, emotion word, and journal entry (if you wrote one). It comes back with a named CBT technique, a plain-language description, and three concrete steps you can do right now. This usually takes around two seconds. If your mood score is very low, or if the model detects signs of crisis in what you wrote, crisis resources are surfaced automatically, and that flag can only ever be turned on by a deterministic server-side check, never suppressed by anything a user (or an injected prompt) writes into the journal field.

**Dashboard.** Your home screen shows a 7 or 30 day mood trend chart with a gradient line that draws itself in on load, a streak tracker (both your current streak and your all-time best, plus a rolling 10-day "practice window" that never resets all the way to zero the way a normal streak does, since the goal is encouragement, not guilt), a year-in-pixels grid showing one colored square per day you logged over the past year, and an insights card that surfaces which activities actually correlate with better or worse moods for you specifically, once you have enough data for it to mean anything.

**History and Toolkit.** Every past entry is browsable with full detail (the mood, the tag, the journal text, the activities, and the coping suggestion you got). You can mark a suggestion as helpful or not, and save any suggestion to a personal Toolkit so you can find your favorite coping techniques again later without digging through history.

**Weekly summary.** On demand, the app can generate a short AI-written weekly reflection: a couple of sentences summarizing the week plus two or three concrete highlights, again from Claude Haiku, cached so it's only generated once per week.

**Settings.** Display name, light/dark/system theme, a daily reminder notification (mobile), exporting your own data as a JSON file (mobile), a biometric or PIN app lock (mobile), and a way to wipe your own mood data if you want a fresh start.

**Design details worth knowing about.** Dark mode is treated as a first-class requirement, not an afterthought, since a lot of journaling happens at night. The whole color system deliberately avoids red for anything (errors use a muted rose instead) and avoids a red-to-green mood gradient (low moods render as cool slate, high moods as warm gold, so no color on the app ever tells you your day was "bad").

## How it's built

MindBridge is a monorepo with two client apps sharing one backend.

| Layer | What's used |
|---|---|
| Mobile | Flutter (Dart SDK ^3.12.2, built and tested against Flutter 3.44.4 in CI) |
| Web | React 19 with Vite, TypeScript, Tailwind CSS v4, React Router v7 |
| Charts | fl_chart (mobile), Recharts (web) |
| Backend | Supabase: Postgres, Auth, Row Level Security, Edge Functions on Deno |
| AI | Anthropic's Claude Haiku (`claude-haiku-4-5`), called only from server-side Edge Functions |
| Deployment | Vercel for the web app, TestFlight and the Play Store for mobile |
| CI | GitHub Actions, five jobs gated behind path filtering so a change to one app doesn't trigger a full rebuild of everything |

A few decisions that shaped how this is put together:

The Anthropic API key lives only in Supabase's Edge Function environment. It's never bundled into the Flutter or React code, so there's no way to extract it from either client app. Both client apps are intentionally "thin": neither one owns any real business logic. The Edge Functions are the single source of truth for the AI prompt and for writing AI-generated data to the database. Both platforms are built in parallel, feature by feature, rather than finishing one app entirely before starting the other, so they stay at feature parity with each other (the one deliberate exception being the visual design system rollout, which shipped on Flutter first as the demo platform and was ported to web afterward as a separate step).

## Repository layout

```
mindbridge/
├── apps/
│   ├── mobile/              Flutter app (iOS, Android, and a web target)
│   │   ├── lib/
│   │   │   ├── core/        design tokens, pure logic (streaks, crisis rules, mood color), env config
│   │   │   ├── widgets/     shared UI pieces used across features (the breathing circle, the mood slider, etc.)
│   │   │   └── features/    one folder per feature area: onboarding, auth, mood, dashboard, history, settings, toolkit, help
│   │   └── test/            unit and widget tests
│   └── web/
│       └── src/
│           ├── pages/       one file per route
│           ├── components/  shared UI pieces, mirroring the mobile widgets
│           ├── features/    onboarding flow
│           ├── lib/         Supabase calls and pure logic, one file per concern
│           └── context/     auth context
├── shared/
│   └── types/                TypeScript types shared between the web app and the Edge Functions
├── supabase/
│   ├── functions/
│   │   ├── generate-suggestion/         calls Claude Haiku for a single mood check-in
│   │   └── generate-weekly-summary/     calls Claude Haiku for a weekly reflection
│   ├── migrations/           every SQL migration, applied in filename order
│   ├── qa/                   scripts for seeding test/demo accounts
│   └── seed.sql
├── qa/
│   └── web/                  a headless browser script that walks the whole app end to end
└── docs/                     a written doc for every source file in the project, plus a running session log
```

## Getting it running yourself

### What you need first

- Node.js 24 and npm, for the web app
- Flutter 3.44.4 or newer, for the mobile app
- A free Supabase account, at supabase.com
- An Anthropic API key, at console.anthropic.com, if you want the AI features to actually work rather than just fail gracefully

### Setting up the backend

1. Create a new project on Supabase and open its SQL editor.
2. Run every file in `supabase/migrations/` in order, starting from `0001_init_schema.sql` through the highest numbered file. Each one is a plain `.sql` file you can paste in and run.
3. Deploy both functions in `supabase/functions/` (`generate-suggestion` and `generate-weekly-summary`) through the Supabase dashboard's Edge Functions page. Each one is a single `index.ts` file with no build step.
4. Under the project's Edge Function settings, set two secrets:
   - `ANTHROPIC_API_KEY`, your Claude API key
   - `ALLOWED_ORIGINS`, a comma separated list of the URLs your web app will be served from
5. Under Authentication settings, turn off "Confirm email" if you want zero-friction sign-ups for testing (this is what the deployed demo uses; a production launch to real users should turn this back on and set up a real email provider first).
6. Still under Authentication, add your web app's URL to both the Site URL and the Redirect URLs.

### Running the web app

```bash
cd apps/web
npm install
```

Create a file at `apps/web/.env.local` (see the configuration section below for what goes in it), then:

```bash
npm run dev       # starts a local dev server, usually at localhost:5173
npm run build     # type-checks and builds for production
npm run lint      # runs the linter
```

### Running the mobile app

```bash
cd apps/mobile
flutter pub get
```

Create a file at `apps/mobile/.env` (again, see the configuration section), then:

```bash
flutter run --dart-define-from-file=.env
```

The `--dart-define-from-file` flag has to be passed every time you run or build the app, since that's how it picks up the Supabase URL and key without hardcoding them into the source. A few other useful commands:

```bash
flutter analyze                                    # static analysis
flutter test                                        # unit and widget tests
flutter build apk --debug                           # a debug Android build
flutter build ios --release                         # a release iOS build (needs Xcode)
```

## Configuration reference

### Web: `apps/web/.env.local`

```
VITE_SUPABASE_URL=https://your-project-ref.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
```

Both values are found on your Supabase project's API settings page. This file is gitignored on purpose and should never be committed.

### Mobile: `apps/mobile/.env`

```
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

Same values as above, just under the variable names the Flutter side expects. Also gitignored.

### Edge Function secrets (set through the Supabase dashboard, not in any file)

```
ANTHROPIC_API_KEY=your-anthropic-key
ALLOWED_ORIGINS=https://your-deployed-web-app.com
```

The anon key is meant to be public and ships inside both client apps by design; Supabase's Row Level Security is what actually protects user data, not the secrecy of that key. The Anthropic key and the service role key (used internally by the Edge Functions, never by either client app) are the only two values in this whole project that need to stay secret.

## Using the app: a walkthrough

Here's what an actual first session looks like, from a new user's point of view.

You land on the homepage and read a short pitch for what the app does. You tap "Get started" and go through five quick onboarding screens: a welcome screen, a short explanation of what's private and what isn't, one or two questions that just tailor the wording a little (never a gate you have to answer correctly), a quick explainer of how the mood-to-suggestion flow works, and then your actual first check-in: drag the mood slider, pick an emotion word, and you're shown a sample coping technique so you know what to expect. You then create an account (or use Google sign-in), and the app quietly offers to save that first check-in for real, which triggers the same pipeline a normal check-in would.

From there, day to day, you open the app, log your mood in well under a minute, and get your coping suggestion. Every few days you might glance at your dashboard to see your trend line and your streak. Once a week you can generate a short written summary of how the week went. If a technique really worked for you, you save it to your Toolkit so you can find it again without hunting through history. If your mood ever drops into a range the app flags, crisis resources show up automatically, and they're also just always sitting one tap away regardless.

## Database schema

Everything lives in Postgres, behind Supabase's Row Level Security, which is enforced at the database level, not just checked in application code. That means even if there were a bug in the web or mobile app, the database itself refuses to let one user read or write another user's rows.

The core tables:

```
users               one row per account: id, display name, created_at
mood_logs           the mood score (1 to 10), the chosen emotion tag, and when it was logged
journal_entries     the optional written entry attached to a mood log, capped at 500 characters
coping_suggestions  the AI's response to a mood log: technique name, description, three steps
ai_call_logs        a record of every Claude API call: token counts, latency, when it happened
```

A handful of tables were added later as the feature set grew: `activity_tags` and `mood_log_activities` for the activity tagging feature, `weekly_summaries` for the weekly AI reflection, and a couple of extra columns on `journal_entries` for the cognitive distortion feature. As of this writing there are 14 migration files, all under `supabase/migrations/`, applied in order.

## Security and privacy

A few things worth calling out specifically, since this is a mental health app dealing with a teenage user base:

- Every table has Row Level Security turned on, scoped to `auth.uid()`, so a signed-in user can only ever read or write their own rows. This is checked by an automated test in CI on every change to the schema.
- The Anthropic API key never touches either client app. It only exists in the Edge Function's server-side environment.
- Anything a user writes into a journal entry is treated strictly as data, not as instructions, when it's included in the AI prompt. It's wrapped in an explicit tag and the system prompt tells the model to ignore anything inside it that looks like a command. This is a real defense against prompt injection, not just a polite request to the model.
- Whether crisis resources get shown is decided by a deterministic, server-side rule (a low mood score, or a keyword check on the journal text) that can only raise the crisis flag, never lower it. A cleverly worded journal entry cannot talk the app out of showing crisis resources if the score or keywords already triggered it.
- Both Edge Functions rate-limit how many AI calls a single user can make per hour, so no client-side bug (or malicious client) can run up an unbounded API bill.
- Passwords require a minimum of 8 characters.
- A password reset link opens a restricted session that can only be used to set a new password. It does not grant normal access to the rest of the app until that's done.

## Testing and QA

The mobile app has a suite of unit and widget tests under `apps/mobile/test/`, covering the pure logic (streak calculation, crisis detection, mood coloring) as well as some of the more complex widgets. Run them with `flutter test`.

The web app has a headless end-to-end script (`qa/web/golden_path.py`) that drives a real browser through sign-in, the dashboard, history, entry detail, dark mode, the help screen, and the toolkit, checking that each one actually renders and behaves correctly.

There's also a script (`supabase/qa/seed_qa_demo_user.py`) that spins up a disposable test account with realistic mood history, so the app can be clicked through or tested without needing to manually create weeks of data by hand, and without spending real API budget on live AI calls (it inserts pre-written coping suggestions instead of calling Claude).

CI runs on every push and pull request against `main` and `dev`: linting and a production build for the web app, static analysis, a debug build, and the test suite for the mobile app, and a job that spins up a real throwaway Postgres database, applies every migration in order, and checks that Row Level Security is actually enabled everywhere it should be.

## Known limitations

Being upfront about where this stands right now:

- AI response time runs around 2.3 seconds at the 95th percentile, a bit over the original 2 second target, though still fast enough not to feel broken.
- There's no offline mode. Every screen needs a network connection to load data.
- Two of the cognitive distortion feature's internal identifiers are spelled slightly differently between the web and mobile codebases (one uses hyphens, the other uses underscores). The database accepts both spellings so it isn't a functional bug, but it's on the list to clean up.
- Branded transactional email (password resets, etc.) is gated on buying a domain and setting up a real email provider. Right now it uses Supabase's default sender, which works but looks generic.
- Focus indicators for keyboard navigation are fully implemented on text inputs but not yet on every button and chip in the mobile app.

