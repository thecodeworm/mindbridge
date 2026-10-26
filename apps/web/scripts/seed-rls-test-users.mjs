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
  console.error('Should NOT be VITE_-prefixed, so it never ships to the client bundle.')
  process.exit(1)
}


// Safety rails. These scripts create and DELETE auth users with the service
// role, and their old hard-coded passwords were committed to git. So:
//  - the target project must be confirmed explicitly (SEED_TARGET_REF), and
//  - passwords come from the environment, never from the repo.
// Point them at a staging project, not production.
const targetRef = new URL(env.VITE_SUPABASE_URL).hostname.split('.')[0]
if (process.env.SEED_TARGET_REF !== targetRef) {
  console.error(`Refusing to run. Set SEED_TARGET_REF=${targetRef} to confirm this is the project you mean to seed.`)
  process.exit(1)
}
function requirePassword(name) {
  const value = process.env[name] ?? ''
  if (value.length < 12) {
    console.error(`Set ${name} (12+ characters) in the environment. Passwords are not stored in the repo.`)
    process.exit(1)
  }
  return value
}

const opts = { auth: { autoRefreshToken: false, persistSession: false } }

// sb_secret_ only needs to cover auth.admin here — table inserts go through
// the anon client signed in as the seed user, same as the real app
// (moodService.ts), so this never touches service_role's table grants.
const supabaseAuth = createClient(env.VITE_SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY, opts)
const supabaseAnon = createClient(env.VITE_SUPABASE_URL, env.VITE_SUPABASE_ANON_KEY, opts)

// All seed emails share this domain so we can identify and wipe them cleanly.
const SEED_DOMAIN = 'mindbridge-seed.dev'
const SEED_PASSWORD = requirePassword('SEED_PASSWORD')

const USERS = [
  { email: `rls-test-a@${SEED_DOMAIN}`, display_name: 'RLS Test A' },
  { email: `rls-test-b@${SEED_DOMAIN}`, display_name: 'RLS Test B' },
]

async function wipeSeedUsers() {
  console.log('Wiping existing seed users...')
  const { data, error } = await supabaseAuth.auth.admin.listUsers({ perPage: 200 })
  if (error) {
    console.error('Could not list users:', error.message)
    return
  }

  const seedUsers = data.users.filter((u) => u.email?.endsWith(SEED_DOMAIN))
  if (!seedUsers.length) {
    console.log('No seed users found.\n')
    return
  }

  for (const u of seedUsers) {
    const { error: delError } = await supabaseAuth.auth.admin.deleteUser(u.id)
    if (delError) {
      console.error(`  x Could not delete ${u.email}: ${delError.message}`)
    } else {
      console.log(`  - Deleted ${u.email}`)
    }
  }
  console.log()
}

async function seed() {
  await wipeSeedUsers()

  console.log(`Creating ${USERS.length} RLS test users...\n`)

  const created = []
  for (const u of USERS) {
    // public.users row is populated automatically by the on_auth_user_created
    // trigger (0001_init_schema.sql) — no separate insert needed here.
    const { data, error } = await supabaseAuth.auth.admin.createUser({
      email: u.email,
      password: SEED_PASSWORD,
      email_confirm: true,
      user_metadata: { display_name: u.display_name },
    })

    if (error) {
      console.error(`x  ${u.email} — auth error: ${error.message}`)
      continue
    }

    created.push({ ...u, id: data.user.id })
    console.log(`+  ${u.email} (${data.user.id})`)
  }

  const [userA, userB] = created
  if (!userA || !userB) {
    console.error('\nDid not create both users — aborting.')
    process.exit(1)
  }

  // Sign in as User A and insert through the anon client — same path the
  // real app uses (moodService.ts), scoped by RLS to auth.uid() = User A.
  // service_role has no table-level GRANT on mood_logs (0003 only granted
  // `authenticated`), so this deliberately avoids the service-role client
  // for the insert rather than widening that grant just for a seed script.
  const { error: signInAError } = await supabaseAnon.auth.signInWithPassword({
    email: userA.email,
    password: SEED_PASSWORD,
  })

  if (signInAError) {
    console.error('\nFailed to sign in as User A:', signInAError.message)
    process.exit(1)
  }

  const { data: moodLog, error: moodLogError } = await supabaseAnon
    .from('mood_logs')
    .insert({ user_id: userA.id, mood_score: 6, mood_tag: 'anxious' })
    .select()
    .single()

  if (moodLogError) {
    console.error('\nFailed to insert mood log for User A:', moodLogError.message)
    process.exit(1)
  }

  await supabaseAnon.auth.signOut()

  // Sign in as User B to get a real, RLS-scoped access token — the same
  // kind the app itself would send.
  const { data: signInB, error: signInBError } = await supabaseAnon.auth.signInWithPassword({
    email: userB.email,
    password: SEED_PASSWORD,
  })

  if (signInBError) {
    console.error('\nFailed to sign in as User B:', signInBError.message)
    process.exit(1)
  }

  console.log('\n--- RLS rehearsal inputs ---')
  console.log(`USER_A_ID=${userA.id}`)
  console.log(`USER_A_MOOD_LOG_ID=${moodLog.id}`)
  console.log(`USER_B_ID=${userB.id}`)
  console.log(`USER_B_ACCESS_TOKEN=${signInB.session.access_token}`)
  console.log('\nRun with --wipe to tear these down when done.')
}

if (process.argv.includes('--wipe')) {
  wipeSeedUsers().then(() => console.log('Done.'))
} else {
  seed()
}
