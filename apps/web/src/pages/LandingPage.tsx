import { Link } from 'react-router-dom'
import { BreathingCircle } from '../components/BreathingCircle'
import { CrisisChip } from '../components/CrisisChip'
import { moodColor } from '../lib/moodColor'

/**
 * Public marketing page — the first thing a signed-out visitor sees at `/`.
 * Previously `/` fell straight through to the onboarding flow or a login
 * redirect with no chance to explain what the app is first; this gives
 * MindBridge an actual front door. "Get started" leads into the existing
 * five-step OnboardingFlow (now routed at /onboarding); "Log in" is for
 * returning users.
 */
export function LandingPage() {
  const moodRamp = [1, 3, 5, 7, 10].map(moodColor)

  return (
    <div className="min-h-screen bg-cream">
      <header className="mx-auto flex w-full max-w-5xl items-center justify-between px-4 py-6 sm:px-6">
        <span className="text-xl font-bold text-blue-dark">MindBridge</span>
        <Link
          to="/login"
          className="rounded-full px-4 py-2 text-sm font-medium text-ink transition-colors hover:bg-blue-tint"
        >
          Log in
        </Link>
      </header>

      <main>
        {/* Hero */}
        <section className="mx-auto flex w-full max-w-3xl flex-col items-center px-4 pb-20 pt-8 text-center sm:px-6">
          <div className="relative mb-8 flex h-40 w-40 items-center justify-center">
            <BreathingCircle colors={[moodColor(1), moodColor(5.5), moodColor(10)]} size={160} />
            <span className="absolute text-4xl">🌤️</span>
          </div>

          <h1 className="text-4xl font-bold leading-tight text-ink sm:text-5xl">
            Check in with yourself.
            <br />
            <span className="text-blue-dark">In under two minutes.</span>
          </h1>

          <p className="mt-5 max-w-xl text-lg text-muted">
            MindBridge is a private mood tracker for teens. Rate how you feel, jot a quick note if
            you want, and get an evidence-based coping technique picked for you — instantly, every time.
          </p>

          <div className="mt-8 flex flex-col gap-3 sm:flex-row">
            <Link
              to="/onboarding"
              className="rounded-full bg-blue-dark px-8 py-3.5 font-medium text-on-accent transition-opacity hover:opacity-90"
            >
              Get started — it's free
            </Link>
            <Link
              to="/login"
              className="rounded-full border border-border bg-field px-8 py-3.5 font-medium text-ink transition-colors hover:bg-blue-tint"
            >
              I have an account
            </Link>
          </div>

          <p className="mt-4 text-xs text-faint">
            No cost. No ads. Nothing shared with anyone without your say-so.
          </p>
        </section>

        {/* Features */}
        <section className="mx-auto w-full max-w-5xl px-4 pb-20 sm:px-6">
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <FeatureCard
              emoji="🧠"
              title="A coping technique, instantly"
              body="Every check-in returns a real CBT technique — a breathing exercise, a grounding method, a reframe — picked for how you feel right now."
            />
            <FeatureCard
              emoji="📈"
              title="See your patterns"
              body="Mood trends over 7 and 30 days, streaks, and gentle insights that surface what actually helps you."
            />
            <FeatureCard
              emoji="🌙"
              title="Built for hard days"
              body="Warm, dark-mode-first design for late-night journaling. Crisis resources are always one tap away — never a red alarm."
            />
            <FeatureCard
              emoji="🔒"
              title="Private by design"
              body="Your entries are yours. Row-level security means no one else — not even us — can read your data."
            />
          </div>
        </section>

        {/* Mood ramp strip */}
        <section className="mx-auto w-full max-w-3xl px-4 pb-24 text-center sm:px-6">
          <p className="mb-4 text-sm font-medium text-muted">
            Every mood has a place — no shade means "bad day"
          </p>
          <div className="flex h-3 overflow-hidden rounded-full">
            {moodRamp.map((c, i) => (
              <div key={i} className="flex-1" style={{ backgroundColor: c }} />
            ))}
          </div>
          <div className="mt-2 flex justify-between text-xs text-faint">
            <span>Low</span>
            <span>High</span>
          </div>
        </section>
      </main>

      <footer className="mx-auto w-full max-w-5xl px-4 pb-10 pt-6 text-center sm:px-6">
        <p className="text-xs text-faint">
          If you're in crisis, you're not alone — call or text 988, or text HOME to 741741.
        </p>
      </footer>

      <CrisisChip />
    </div>
  )
}

function FeatureCard({ emoji, title, body }: { emoji: string; title: string; body: string }) {
  return (
    <div className="card flex flex-col gap-2 p-5 text-left">
      <span className="text-2xl">{emoji}</span>
      <h3 className="font-semibold text-ink">{title}</h3>
      <p className="text-sm text-muted">{body}</p>
    </div>
  )
}
