import { createClient } from '@supabase/supabase-js'
import { readFileSync } from 'fs'
import { resolve, dirname } from 'path'
import { fileURLToPath } from 'url'

const __dirname = dirname(fileURLToPath(import.meta.url))

const envPath = resolve(__dirname, '../.env.local')
const env = Object.fromEntries(
  readFileSync(envPath, 'utf8')
    .split('\n')
    .filter((line) => line.includes('=') && !line.startsWith('#'))
    .map((line) => {
      const idx = line.indexOf('=')
      return [line.slice(0, idx).trim(), line.slice(idx + 1).trim()]
    })
)

if (!env.SUPABASE_SERVICE_ROLE_KEY) {
  console.error('Missing SUPABASE_SERVICE_ROLE_KEY in apps/web/.env.local')
  console.error('Get it from the Supabase dashboard -> Project Settings -> API -> service_role secret (sb_secret_...)')
  process.exit(1)
}

const opts = { auth: { autoRefreshToken: false, persistSession: false } }

// service_role: creates the demo auth user, and inserts coping_suggestions /
// ai_call_logs directly (mirrors generate-suggestion's own write path —
// 0004_grant_service_role_privileges.sql granted it those tables).
// mood_logs / journal_entries go through the anon client signed in as the
// demo user instead, same as moodService.ts, so this never needs RLS bypass
// for the tables real users write to.
const supabaseAdmin = createClient(env.VITE_SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY, opts)
const supabaseAnon = createClient(env.VITE_SUPABASE_URL, env.VITE_SUPABASE_ANON_KEY, opts)

// Separate domain from seed-rls-test-users.mjs so the two scripts' --wipe
// flags can't accidentally delete each other's users.
const DEMO_DOMAIN = 'mindbridge-demo.dev'
const DEMO_PASSWORD = 'MindBridgeDemo2026!'
const DEMO_USER = { email: `demo@${DEMO_DOMAIN}`, display_name: 'Demo Teen' }

const DAYS = 30
const MODEL_USED = 'claude-haiku-4-5-seed-demo'

// ── Canned content (no Anthropic calls — see CLAUDE.md "no autonomous API
// calls" rule). Hand-written, CBT-flavored, non-alarming per the design
// system's tone rules (never red/scolding). ──────────────────────────────

const TECHNIQUES = [
  {
    name: 'Box Breathing',
    tags: ['anxious', 'angry', 'tired'],
    description: 'A steady breathing pattern that signals your nervous system to calm down.',
    steps: [
      'Breathe in slowly through your nose for 4 counts.',
      'Hold that breath gently for 4 counts.',
      'Breathe out through your mouth for 4 counts, then repeat 4 times.',
    ],
  },
  {
    name: '5-4-3-2-1 Grounding',
    tags: ['anxious', 'confused'],
    description: 'A sensory check-in that pulls your attention out of a spiral and into the room.',
    steps: [
      'Name 5 things you can see around you right now.',
      'Name 4 things you can touch, then 3 things you can hear.',
      'Name 2 things you can smell and 1 thing you can taste.',
    ],
  },
  {
    name: 'Thought Record',
    tags: ['sad', 'confused', 'anxious'],
    description: 'A quick way to notice a hard thought and check it against the evidence.',
    steps: [
      'Write down the thought that’s bothering you, exactly as it sounds in your head.',
      'Ask: what’s the evidence for it, and what’s the evidence against it?',
      'Write one more balanced way to think about the situation.',
    ],
  },
  {
    name: 'Progressive Muscle Relaxation',
    tags: ['angry', 'anxious', 'tired'],
    description: 'Tensing and releasing muscle groups to work physical tension out of your body.',
    steps: [
      'Starting at your feet, tense the muscles tight for 5 seconds.',
      'Release and notice the difference as they relax.',
      'Move upward through your legs, stomach, hands, and shoulders, repeating the tense-release.',
    ],
  },
  {
    name: 'Behavioral Activation',
    tags: ['sad', 'tired', 'meh'],
    description: 'Doing one small, doable thing to gently interrupt a low mood before it settles in.',
    steps: [
      'Pick one tiny task you’ve been putting off — something under 5 minutes.',
      'Do just that one thing, without worrying about what comes after.',
      'Notice how you feel once it’s done, even a little bit.',
    ],
  },
  {
    name: 'Gratitude Anchor',
    tags: ['happy', 'calm', 'meh'],
    description: 'Naming specific good things to reinforce a positive moment.',
    steps: [
      'Think of one good thing that happened today, however small.',
      'Notice one specific detail about why it mattered.',
      'Say or write it down so it sticks.',
    ],
  },
  {
    name: 'Worry Time',
    tags: ['anxious', 'confused'],
    description: 'Setting worries aside for a scheduled slot instead of letting them run all day.',
    steps: [
      'Write down the worry on a list instead of thinking it through right now.',
      'Tell yourself you’ll come back to it at a set time later today.',
      'Gently return to what you were doing.',
    ],
  },
  {
    name: 'Self-Compassion Break',
    tags: ['sad', 'angry'],
    description: 'A short pause to respond to yourself the way you would a friend having a hard day.',
    steps: [
      'Put a hand on your chest and acknowledge: this is a hard moment.',
      'Remind yourself that hard moments are part of being human.',
      'Ask what you’d say to a friend feeling this way — and say it to yourself.',
    ],
  },
]

const JOURNAL_SNIPPETS = {
  happy: ['Actually had a really good day today, felt like things clicked.', 'Hung out with friends after school and it was exactly what I needed.'],
  calm: ['Nothing dramatic today, just felt steady and okay.', 'Had some quiet time this evening and it helped a lot.'],
  meh: ['Kind of a flat day, nothing really stood out either way.', 'Not bad, not great. Just getting through it.'],
  sad: ['Missed my friends a lot today, felt kind of alone at lunch.', 'Been thinking about stuff that didn’t go the way I wanted.'],
  anxious: ['Big test coming up and I keep replaying every way it could go wrong.', 'Stomach’s been in knots since this morning, not sure why exactly.'],
  angry: ['Got into it with my sibling again and it’s still bugging me.', 'Group project partner flaked again — so frustrating.'],
  tired: ['Barely slept last night, dragging through the whole day.', 'Practice ran late and now I’m wiped for homework.'],
  confused: ['Not really sure how I feel today, kind of a jumble.', 'Had a weird conversation that I’m still turning over in my head.'],
}

function randomInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min
}

function pick(arr) {
  return arr[randomInt(0, arr.length - 1)]
}

function tagForScore(score) {
  if (score <= 4) return pick(['sad', 'anxious', 'tired', 'angry'])
  if (score <= 6) return pick(['meh', 'tired', 'confused', 'anxious'])
  return pick(['calm', 'happy', 'meh'])
}

function techniqueForTag(tag) {
  const candidates = TECHNIQUES.filter((t) => t.tags.includes(tag))
  return pick(candidates.length ? candidates : TECHNIQUES)
}

async function wipeDemoUser() {
  console.log('Wiping existing demo user...')
  const { data, error } = await supabaseAdmin.auth.admin.listUsers({ perPage: 200 })
  if (error) {
    console.error('Could not list users:', error.message)
    return
  }

  const demoUsers = data.users.filter((u) => u.email?.endsWith(DEMO_DOMAIN))
  if (!demoUsers.length) {
    console.log('No demo user found.\n')
    return
  }

  for (const u of demoUsers) {
    const { error: delError } = await supabaseAdmin.auth.admin.deleteUser(u.id)
    if (delError) {
      console.error(`  x Could not delete ${u.email}: ${delError.message}`)
    } else {
      console.log(`  - Deleted ${u.email}`)
    }
  }
  console.log()
}

async function seed() {
  await wipeDemoUser()

  console.log('Creating demo user...\n')

  // public.users row comes from the on_auth_user_created trigger.
  const { data: created, error: createError } = await supabaseAdmin.auth.admin.createUser({
    email: DEMO_USER.email,
    password: DEMO_PASSWORD,
    email_confirm: true,
    user_metadata: { display_name: DEMO_USER.display_name },
  })

  if (createError) {
    console.error(`Could not create demo user: ${createError.message}`)
    process.exit(1)
  }

  const userId = created.user.id
  console.log(`+ ${DEMO_USER.email} (${userId})\n`)

  const { error: signInError } = await supabaseAnon.auth.signInWithPassword({
    email: DEMO_USER.email,
    password: DEMO_PASSWORD,
  })
  if (signInError) {
    console.error('Failed to sign in as demo user:', signInError.message)
    process.exit(1)
  }

  console.log(`Seeding ${DAYS} days of mood logs...\n`)

  let logCount = 0
  let journalCount = 0
  let suggestionCount = 0

  for (let dayOffset = DAYS - 1; dayOffset >= 0; dayOffset--) {
    // Teens skip days — ~15% of days get no entry at all.
    if (Math.random() < 0.15) continue

    // Most days get one entry; occasionally two (e.g. morning + evening).
    const logsToday = Math.random() < 0.1 ? 2 : 1

    for (let i = 0; i < logsToday; i++) {
      const day = new Date()
      day.setDate(day.getDate() - dayOffset)
      day.setHours(randomInt(8, 22), randomInt(0, 59), 0, 0)
      const loggedAt = day.toISOString()

      const moodScore = randomInt(3, 9)
      const moodTag = tagForScore(moodScore)

      // mood_logs insert goes through the anon client (RLS: auth.uid() = user_id),
      // same path as the real app's moodService.ts.
      const { data: moodLog, error: moodLogError } = await supabaseAnon
        .from('mood_logs')
        .insert({ user_id: userId, mood_score: moodScore, mood_tag: moodTag, logged_at: loggedAt })
        .select('id')
        .single()

      if (moodLogError) {
        console.error(`  x mood_log insert failed: ${moodLogError.message}`)
        continue
      }
      logCount++

      if (Math.random() < 0.35) {
        const body = pick(JOURNAL_SNIPPETS[moodTag])
        const { error: journalError } = await supabaseAnon
          .from('journal_entries')
          .insert({ mood_log_id: moodLog.id, user_id: userId, body, created_at: loggedAt })
        if (journalError) {
          console.error(`  x journal_entry insert failed: ${journalError.message}`)
        } else {
          journalCount++
        }
      }

      const technique = techniqueForTag(moodTag)
      const { error: suggestionError } = await supabaseAdmin.from('coping_suggestions').insert({
        mood_log_id: moodLog.id,
        user_id: userId,
        technique_name: technique.name,
        description: technique.description,
        steps: technique.steps,
        model_used: MODEL_USED,
        generated_at: loggedAt,
      })
      if (suggestionError) {
        console.error(`  x coping_suggestion insert failed: ${suggestionError.message}`)
        continue
      }
      suggestionCount++

      const { error: aiLogError } = await supabaseAdmin.from('ai_call_logs').insert({
        user_id: userId,
        input_tokens: randomInt(280, 420),
        output_tokens: randomInt(120, 220),
        latency_ms: randomInt(1400, 2300),
        called_at: loggedAt,
      })
      if (aiLogError) {
        console.error(`  x ai_call_log insert failed: ${aiLogError.message}`)
      }
    }
  }

  await supabaseAnon.auth.signOut()

  console.log(`\n${logCount} mood logs, ${journalCount} journal entries, ${suggestionCount} coping suggestions created.`)
  console.log('\n--- Demo login ---')
  console.log(`Email:    ${DEMO_USER.email}`)
  console.log(`Password: ${DEMO_PASSWORD}`)
  console.log('\nRun with --wipe to tear this down when done.')
}

if (process.argv.includes('--wipe')) {
  wipeDemoUser().then(() => console.log('Done.'))
} else {
  seed()
}
