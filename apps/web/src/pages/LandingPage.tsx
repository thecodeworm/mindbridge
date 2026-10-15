import { Link } from 'react-router-dom'
import { CrisisChip } from '../components/CrisisChip'
import { moodColor } from '../lib/moodColor'

const MOODS: [string, number][] = [
  ['Heavy', 1.5],
  ['Low', 3.5],
  ['Okay', 5.5],
  ['Good', 7.5],
  ['Great', 9.5],
]

const FEATURES: [number, string, string][] = [
  [7, 'A coping technique, instantly', 'Every check-in returns a real CBT technique, like a breathing exercise, a grounding method, or a reframe, picked for how you feel right now.'],
  [3, 'Your patterns, over time', 'Your week at a glance, 30-day trends, and gentle insights about what actually helps.'],
  [1, 'Made for late nights', 'A dark mode that is easy on the eyes, and crisis help that is always one tap away.'],
  [10, 'Private by design', 'Your entries are yours. Nobody else can read them. Not even us.'],
]

/**
 * Public front door at `/` for signed-out visitors. "Get started" leads into
 * the five-step OnboardingFlow (/onboarding); "Log in" is for returning
 * users. Mirrors apps/mobile/lib/features/onboarding/landing_screen.dart.
 */
export function LandingPage() {
  return (
    <div className="min-h-screen bg-cream">
      <header className="mx-auto flex w-full max-w-5xl items-center gap-2 px-4 py-5 sm:px-6">
        <span className="flex-1 font-display text-xl font-black tracking-tight text-ink">MindBridge</span>
        <Link to="/login" className="rounded-lg px-3 py-2 font-semibold text-blue-dark hover:bg-blue-tint">
          Log in
        </Link>
        <CrisisChip inline />
      </header>

      <main className="mx-auto w-full max-w-5xl px-4 pb-16 sm:px-6">
        <section className="grid gap-10 pt-8 md:grid-cols-[1.2fr_1fr] md:items-center md:pt-16">
          <div>
            <h1 className="text-5xl text-ink sm:text-6xl">
              Check in with yourself.
              <br />
              <span className="hl">In two minutes.</span>
            </h1>
            <p className="mt-5 max-w-xl text-lg leading-relaxed text-muted">
              A private mood journal for teens. Say how you feel, write a line if you want, and get one small,
              evidence-based thing to try right away.
            </p>
            <div className="mt-8 flex flex-col gap-3 sm:flex-row">
              <Link
                to="/onboarding"
                className="rounded-[10px] bg-blue-dark px-7 py-3.5 text-center font-display text-lg font-extrabold text-on-accent hover:opacity-90"
              >
                Get started free
              </Link>
              <Link
                to="/login"
                className="rounded-[10px] border border-border bg-card px-7 py-3.5 text-center font-display text-lg font-bold text-ink hover:bg-blue-tint"
              >
                I have an account
              </Link>
            </div>
            <p className="mt-3 text-sm text-muted">No cost. No ads. Nothing shared without your say-so.</p>
          </div>

          <div className="card p-5 sm:p-6" aria-label="Every mood has a color">
            <p className="label">Every mood has a color</p>
            <div className="mt-4 grid grid-cols-5 gap-2">
              {MOODS.map(([word, s]) => (
                <div key={word} className="flex flex-col items-center gap-1.5">
                  <span className="h-14 w-full rounded-lg" style={{ backgroundColor: moodColor(s) }} />
                  <span className="text-sm font-medium text-muted">{word}</span>
                </div>
              ))}
            </div>
            <p className="mt-4 text-sm text-muted">
              None of them means "bad day." Heavy days get calm colors, not alarms.
            </p>
          </div>
        </section>

        <section className="mt-16" aria-labelledby="what-you-get">
          <h2 id="what-you-get" className="label">
            What you get
          </h2>
          <ul className="mt-2 grid gap-x-10 md:grid-cols-2">
            {FEATURES.map(([tone, title, body]) => (
              <li key={title} className="flex gap-3 border-b border-border py-5">
                <span className="mt-1.5 h-3.5 w-3.5 shrink-0 rounded-[4px]" style={{ backgroundColor: moodColor(tone) }} />
                <div>
                  <h3 className="font-body text-lg font-bold tracking-normal text-ink">{title}</h3>
                  <p className="mt-1 leading-relaxed text-muted">{body}</p>
                </div>
              </li>
            ))}
          </ul>
        </section>

        <p className="mt-10 text-sm text-muted">
          If you're in crisis, you're not alone. Call or text 988, or text HOME to 741741.
        </p>
      </main>
    </div>
  )
}
