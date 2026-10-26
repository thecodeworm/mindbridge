#!/usr/bin/env python3
"""
Creates (or resets) a disposable "showcase" demo account with ~90 days of
rich, internally-consistent data touching every P0/P2/P3 feature at once --
built for demo videos / CAC submission walkthroughs, not for headless CI
(see seed_qa_demo_user.py for the minimal 14-day fixture used there).

Covers, in one account:
  - mood_logs across 90 days hitting all 5 mood-scale color stops
  - a current streak (12 days) shorter than a historical longest streak
    (19 days), so the dashboard's "current vs. personal best" framing
    actually differs
  - a 3-day low-mood window (score <= 2) to exercise the crisis chip/signal
  - journal entries, incl. 5 hand-written cognitive-distortion + reframe
    entries (Distortion picker feature)
  - activity tags with deliberate mood correlation (exercise/friends/outdoors
    skew high-mood days; poor-sleep/exam/screen-time skew low-mood days) so
    InsightsCard's correlation view (MIN_SAMPLE=5) has real signal to show
    in both directions
  - one fixture coping_suggestion + ai_call_log per mood log, technique
    varied across an 9-item pool, with helpful/saved feedback populated so
    the Toolkit screen has real saved techniques
  - weekly_summaries fixtures for every ISO week touched, so WeeklySummaryCard
    doesn't need a live Anthropic call to render
  - users.reminder_time set, so Settings shows a configured reminder

Nothing here calls the real Anthropic API -- all AI-shaped rows are
clearly-marked fixtures (model_used: 'qa-fixture'), exactly like
seed_qa_demo_user.py's existing convention.

Uses the full 24-value MoodTag vocabulary (shared/types/index.ts's
MOOD_TAGS, 4 quadrants x 6) now that 0014_mood_tag_full_vocabulary.sql has
widened the mood_tag CHECK constraint to match -- confirmed live 2026-08-23.
Before that migration, mood_logs.mood_tag only accepted the original 8
values (0005_security_hardening.sql), and this script was restricted to
those 8 to avoid failing its own inserts; see docs/database/
0014_mood_tag_full_vocabulary.md for the bug that fix addressed.

Reads SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY from apps/web/.env.local.
Idempotent: deletes any existing user with SHOWCASE_EMAIL first, then
recreates.

Usage:
    source ../../.venv-qa/bin/activate  # from supabase/qa/, or repo-root .venv-qa
    python3 seed_showcase_user.py
"""
from __future__ import annotations

import datetime as dt
import json
import pathlib
import random
import ssl
import sys
import urllib.error
import urllib.request

import certifi

_SSL_CONTEXT = ssl.create_default_context(cafile=certifi.where())

SHOWCASE_EMAIL = "showcase@mindbridge.test"
SHOWCASE_PASSWORD = "showcase26"
SHOWCASE_DISPLAY_NAME = "Jordan"
SHOWCASE_REMINDER_TIME = "20:00:00"

DAYS = 90
RNG_SEED = 20260823  # fixed, so reruns produce the same demo narrative

REPO_ROOT = pathlib.Path(__file__).resolve().parents[2]
ENV_FILE = REPO_ROOT / "apps" / "web" / ".env.local"

# Full MoodTag vocabulary (shared/types/index.ts's MOOD_TAGS), grouped by
# quadrant -- mirrors apps/web/src/components/MoodTagPicker.tsx and
# apps/mobile/lib/features/mood/mood_log_service.dart's kMoodTags. Valid
# against mood_logs.mood_tag as of 0014_mood_tag_full_vocabulary.sql.
HIGH_PLEASANT = ["excited", "happy", "energized", "proud", "grateful", "hopeful"]
HIGH_UNPLEASANT = ["anxious", "angry", "stressed", "frustrated", "overwhelmed", "irritated"]
LOW_PLEASANT = ["calm", "content", "relaxed", "peaceful", "focused", "satisfied"]
LOW_UNPLEASANT = ["sad", "tired", "confused", "meh", "lonely", "bored"]

# Built-in activity_tags catalog, by slug (0006_activity_tags.sql).
POSITIVE_TAGS = ["exercise", "friends", "outdoors"]
NEGATIVE_TAGS = ["poor-sleep", "exam", "screen-time"]
NEUTRAL_TAGS = ["school", "family", "good-sleep", "music", "food", "alone-time"]

# Valid distortion ids per is_valid_distortions() (0012_...sql) -- union of
# web's kebab-case catalog and mobile's snake_case catalog.
TECHNIQUES = [
    {
        "technique_name": "Box Breathing",
        "description": "A simple grounding technique to slow your breathing and calm your body down.",
        "steps": [
            "Breathe in slowly through your nose for 4 counts.",
            "Hold that breath gently for 4 counts.",
            "Let it out slowly for 4 counts, then repeat until you feel steadier.",
        ],
        "tags": ["anxious", "angry"],
    },
    {
        "technique_name": "5-4-3-2-1 Grounding",
        "description": "A sensory exercise that pulls your attention out of a spiral and into the room around you.",
        "steps": [
            "Name 5 things you can see right now.",
            "Name 4 things you can touch and 3 things you can hear.",
            "Finish with 2 things you can smell and 1 thing you can taste.",
        ],
        "tags": ["anxious", "confused"],
    },
    {
        "technique_name": "Cognitive Reframe",
        "description": "A quick way to catch a thought that feels true and check it against the evidence.",
        "steps": [
            "Write down the exact thought that's bothering you.",
            "Ask yourself what you'd say if a friend told you this about themselves.",
            "Write one more balanced version of the thought next to it.",
        ],
        "tags": ["sad", "meh", "confused"],
    },
    {
        "technique_name": "Progressive Muscle Relaxation",
        "description": "Releases physical tension you might not even notice you're carrying.",
        "steps": [
            "Tense your shoulders up toward your ears for 5 seconds.",
            "Release them all at once and notice the difference.",
            "Move down through your arms, hands, and legs the same way.",
        ],
        "tags": ["tired", "anxious"],
    },
    {
        "technique_name": "Worry Time",
        "description": "Gives your worries a scheduled slot instead of letting them run all day.",
        "steps": [
            "Jot the worry down on paper instead of chewing on it right now.",
            "Pick a specific 10-minute slot later today to think it through.",
            "When that time comes, reread it; most worries shrink once you revisit them.",
        ],
        "tags": ["anxious", "meh"],
    },
    {
        "technique_name": "Gratitude Pause",
        "description": "A short reflection that reinforces a good day instead of letting it slide by unnoticed.",
        "steps": [
            "Name one specific moment from today that felt good.",
            "Notice what you did, or who you were with, that helped make it happen.",
            "Say one sentence about why it mattered to you.",
        ],
        "tags": ["happy", "calm"],
    },
    {
        "technique_name": "Self-Compassion Break",
        "description": "A gentle check-in for the moments you'd never talk to a friend the way you're talking to yourself.",
        "steps": [
            "Put a hand on your chest and name what you're feeling out loud.",
            "Remind yourself that plenty of people your age feel this exact thing sometimes.",
            "Ask what you actually need right now, then try to offer yourself that.",
        ],
        "tags": ["sad", "tired"],
    },
    {
        "technique_name": "Small Step Forward",
        "description": "Breaks a stuck, low-motivation feeling into one step small enough to actually start.",
        "steps": [
            "Pick the smallest possible version of the thing you're avoiding.",
            "Set a timer for just 5 minutes and start only that much.",
            "Notice that starting was the hard part; decide whether to keep going once the timer ends.",
        ],
        "tags": ["tired", "meh"],
    },
    {
        "technique_name": "Opposite Action",
        "description": "Uses a small deliberate action to shift out of a reactive, heated moment.",
        "steps": [
            "Notice the urge the anger is pushing you toward.",
            "Do the opposite on purpose: soften your posture, lower your voice, step away for a minute.",
            "Come back to the situation once your body isn't running the show anymore.",
        ],
        "tags": ["angry", "confused"],
    },
]

# Hand-crafted narrative entries: journal body + optional distortion/reframe,
# placed at specific days_ago so a demo walkthrough has a coherent story to
# click into, rather than relying on randomness to produce something usable.
NARRATIVE_DAYS = {
    3: {
        "score": 8, "tag": "happy",
        "body": "Great day! Hung out with friends after the exam and felt so relieved.",
    },
    8: {
        "score": 3, "tag": "anxious",
        "body": "Bombed practice questions for tomorrow's exam. I'm going to fail the whole class.",
        "distortions": ["catastrophizing"],
        "reframe": "One bad practice set doesn't set the whole grade; I still have time to review the topics I missed.",
    },
    20: {
        "score": 4, "tag": "sad",
        "body": "My friends got quiet when I sat down at lunch. Pretty sure they're annoyed with me.",
        "distortions": ["mind-reading"],
        "reframe": "They might've just been tired, or mid-conversation about something unrelated; I don't actually know what they were thinking.",
    },
    30: {
        "score": 4, "tag": "meh",
        "body": "Got a B- on the project. If it's not an A it basically doesn't count.",
        "distortions": ["all-or-nothing"],
        "reframe": "A B- is still a solid grade on a hard project; it doesn't erase the parts I did well.",
    },
    50: {
        "score": 7, "tag": "calm",
        "body": "Realized I've checked in every day this week without missing one. Feels good to actually notice a pattern instead of just powering through.",
    },
    65: {
        "score": 6, "tag": "meh",
        "body": "Had one really rough week a bit ago, but looking back I got through it and things have felt steadier since.",
        "distortions": ["overgeneralization"],
        "reframe": "One hard stretch doesn't mean everything is always going to feel that heavy.",
    },
    82: {
        "score": 5, "tag": "meh",
        "body": "I should have finished my homework earlier instead of scrolling all night. I should just be better at this by now.",
        "distortions": ["should_statements"],
        "reframe": "I'm still learning how to manage my time; one slow night doesn't mean I'm bad at this.",
    },
}

GENERIC_JOURNALS = [
    "Pretty normal day, just tired from staying up too late.",
    "Practice went long and I'm wiped, but glad I went.",
    "Family dinner ran late, good to just talk about nothing for a while.",
    "Didn't sleep great, felt it all day.",
    "Made it through a busy day without feeling too overwhelmed.",
    "Quiet day at home, mostly just recharged.",
    "Group project stress today, but we figured out a plan.",
    "Went for a walk after school and it actually helped clear my head.",
]

CURRENT_STREAK = set(range(0, 12))        # days_ago 0..11 -- current streak = 12
LONGEST_STREAK = set(range(40, 59))       # days_ago 40..58 -- longest streak = 19
CRISIS_DAYS = [70, 71, 72]                # 3 consecutive low-mood days
FORCE_EXCLUDE = {12, 39, 59}              # keeps the two streaks visually distinct
ALWAYS_INCLUDE = CURRENT_STREAK | LONGEST_STREAK | set(CRISIS_DAYS) | set(NARRATIVE_DAYS)
RANDOM_INCLUDE_PROB = 0.65


def load_env(path: pathlib.Path) -> dict[str, str]:
    env: dict[str, str] = {}
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        env[key.strip()] = value.strip()
    return env


def request(method: str, url: str, headers: dict[str, str], body=None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, context=_SSL_CONTEXT) as resp:
            raw = resp.read()
            return resp.status, (json.loads(raw) if raw else None)
    except urllib.error.HTTPError as e:
        raw = e.read()
        try:
            return e.code, json.loads(raw)
        except json.JSONDecodeError:
            return e.code, raw.decode(errors="replace")


def tag_for_score(score: int, rng: random.Random) -> str:
    # Mood score (intensity) and mood tag (energy x valence quadrant) are
    # independent axes in the real product -- this mapping is a demo
    # convenience, not a product rule, but keeps entries looking plausible
    # rather than randomly pairing e.g. a 9/10 score with "bored".
    if score >= 9:
        return rng.choice(HIGH_PLEASANT)
    if score >= 7:
        return rng.choice(HIGH_PLEASANT + LOW_PLEASANT)
    if score >= 5:
        return rng.choice(LOW_PLEASANT + LOW_UNPLEASANT[:3])
    if score >= 3:
        return rng.choice(LOW_UNPLEASANT + HIGH_UNPLEASANT[:3])
    return rng.choice(HIGH_UNPLEASANT + ["sad", "lonely"])


def technique_for(tag: str, rng: random.Random) -> dict:
    matches = [t for t in TECHNIQUES if tag in t["tags"]]
    return rng.choice(matches or TECHNIQUES)


def week_start_str(d: dt.date) -> str:
    # Monday of the ISO week containing d, matching apps/web/src/lib/weeklySummaryService.ts
    return (d - dt.timedelta(days=d.weekday())).isoformat()


def summary_for_week(avg_score: float, count: int, week_index: int, total_weeks: int) -> dict:
    if avg_score >= 7:
        summary = (
            "This was a genuinely good week; your mood stayed high across most check-ins, "
            "and it looks like the things you've been leaning on (friends, time outdoors) kept showing up."
        )
        highlights = [
            "Mood stayed in the happy/calm range most of the week.",
            "Consistent check-ins: you showed up for yourself daily.",
        ]
    elif avg_score >= 5:
        summary = (
            "A pretty even week overall, some ups and downs, but nothing that knocked you off track. "
            "You kept checking in even on the flatter days, which matters more than it feels like."
        )
        highlights = [
            "Mood held steady in the calm/meh range.",
            "You kept your check-in habit going through an average week.",
        ]
    else:
        summary = (
            "This was a harder week. Mood dipped more than usual, and it's worth being gentle with "
            "yourself about that; showing up to log it, even on the low days, is still showing up."
        )
        highlights = [
            "A few tougher days this week, worth noticing what was going on around them.",
            "You kept logging even when the mood wasn't great, which is the harder thing to do.",
        ]
    if week_index == total_weeks - 1:
        highlights.append("Most recent week: keep an eye on how this trend continues.")
    return {
        "summary": f"{summary} ({count} check-in{'s' if count != 1 else ''} this week.)",
        "highlights": highlights,
    }


def main() -> int:
    if not ENV_FILE.exists():
        print(f"missing {ENV_FILE}", file=sys.stderr)
        return 1

    env = load_env(ENV_FILE)
    supabase_url = env["VITE_SUPABASE_URL"].rstrip("/")
    service_key = env["SUPABASE_SERVICE_ROLE_KEY"]
    anon_key = env["VITE_SUPABASE_ANON_KEY"]

    admin_headers = {
        "apikey": service_key,
        "Authorization": f"Bearer {service_key}",
        "Content-Type": "application/json",
    }
    admin_rest_headers = {**admin_headers, "Prefer": "return=representation"}

    rng = random.Random(RNG_SEED)

    # --- 1. find + delete any existing showcase user (idempotent re-seed) ---
    status, listing = request(
        "GET",
        f"{supabase_url}/auth/v1/admin/users?email={SHOWCASE_EMAIL}",
        admin_headers,
    )
    if status == 200 and listing:
        users = listing.get("users", listing) if isinstance(listing, dict) else listing
        for u in users or []:
            if u.get("email") == SHOWCASE_EMAIL:
                request("DELETE", f"{supabase_url}/auth/v1/admin/users/{u['id']}", admin_headers)
                print(f"deleted existing showcase user {u['id']}")

    # --- 2. create the auth user (pre-confirmed) ---
    status, created = request(
        "POST",
        f"{supabase_url}/auth/v1/admin/users",
        admin_headers,
        {
            "email": SHOWCASE_EMAIL,
            "password": SHOWCASE_PASSWORD,
            "email_confirm": True,
            "user_metadata": {"display_name": SHOWCASE_DISPLAY_NAME},
        },
    )
    if status not in (200, 201):
        print(f"failed to create user: {status} {created}", file=sys.stderr)
        return 1
    user_id = created["id"]
    print(f"created showcase user {user_id} ({SHOWCASE_EMAIL})")

    # public.users row is created by the handle_new_user trigger (SECURITY
    # DEFINER, sets display_name from user_metadata) -- but service_role has
    # no explicit grant on public.users (only coping_suggestions/ai_call_logs/
    # weekly_summaries per 0004/0008), so reminder_time has to be set via the
    # authenticated user's own session below, not a service-role POST here.

    # --- 2b. sign in as the showcase user so mood_logs/journal_entries writes
    # go through RLS exactly like the real app (auth.uid() = user_id) --
    # service_role only has explicit grants on coping_suggestions/
    # ai_call_logs/weekly_summaries (0004, 0008), deliberately narrow. See
    # seed_qa_demo_user.py for the full rationale.
    status, token_resp = request(
        "POST",
        f"{supabase_url}/auth/v1/token?grant_type=password",
        {"apikey": anon_key, "Content-Type": "application/json"},
        {"email": SHOWCASE_EMAIL, "password": SHOWCASE_PASSWORD},
    )
    if status != 200:
        print(f"failed to sign in as showcase user: {status} {token_resp}", file=sys.stderr)
        return 1
    access_token = token_resp["access_token"]
    user_rest_headers = {
        "apikey": anon_key,
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json",
        "Prefer": "return=representation",
    }

    # `authenticated` has explicit grants on public.users (0003) and an RLS
    # "Users can update own profile" policy (0005), so this goes through the
    # user's own session rather than service_role.
    status, _ = request(
        "PATCH",
        f"{supabase_url}/rest/v1/users?id=eq.{user_id}",
        user_rest_headers,
        {"reminder_time": SHOWCASE_REMINDER_TIME},
    )
    if status not in (200, 204):
        print(f"warning: failed to set reminder_time: {status}", file=sys.stderr)

    # --- 3. fetch the built-in activity_tags catalog (seeded by migration 0006) ---
    status, catalog = request(
        "GET",
        f"{supabase_url}/rest/v1/activity_tags?user_id=is.null&select=id,slug",
        user_rest_headers,
    )
    if status != 200 or not catalog:
        print(f"failed to fetch activity_tags catalog: {status} {catalog}", file=sys.stderr)
        return 1
    tag_id_by_slug = {row["slug"]: row["id"] for row in catalog}
    missing = [s for s in POSITIVE_TAGS + NEGATIVE_TAGS + NEUTRAL_TAGS if s not in tag_id_by_slug]
    if missing:
        print(f"warning: catalog missing expected slugs: {missing}", file=sys.stderr)

    # --- 4. anchor "today" to local noon (see seed_qa_demo_user.py's note on
    # why UTC-anchoring silently breaks streaks/trend for evening-in-a-
    # western-timezone runs) ---
    local_now = dt.datetime.now().astimezone()
    today = local_now.date()
    local_tz = local_now.tzinfo

    # --- 5. build the day plan ---
    included_days: set[int] = set(ALWAYS_INCLUDE)
    for days_ago in range(DAYS):
        if days_ago in ALWAYS_INCLUDE or days_ago in FORCE_EXCLUDE:
            continue
        if rng.random() < RANDOM_INCLUDE_PROB:
            included_days.add(days_ago)

    mood_log_ids: dict[int, str] = {}
    scores: dict[int, int] = {}
    tags: dict[int, str] = {}

    print(f"seeding {len(included_days)} of {DAYS} days...")

    for days_ago in sorted(included_days, reverse=True):
        date = today - dt.timedelta(days=days_ago)
        narrative = NARRATIVE_DAYS.get(days_ago)

        if days_ago in CRISIS_DAYS:
            score = rng.choice([1, 2])
            tag = rng.choice(["sad", "anxious", "angry", "overwhelmed", "lonely"])
        elif narrative:
            score = narrative["score"]
            tag = narrative["tag"]
        else:
            day_index = (DAYS - 1) - days_ago  # 0 = 90 days ago, DAYS-1 = today
            base = 5.0 + (day_index / (DAYS - 1)) * 1.5
            weekend_bonus = 1.2 if date.weekday() >= 5 else 0.0
            noise = rng.gauss(0, 1.3)
            score = round(base + weekend_bonus + noise)
            score = max(1, min(10, score))
            tag = tag_for_score(score, rng)

        scores[days_ago] = score
        tags[days_ago] = tag

        logged_at = dt.datetime.combine(date, dt.time(12, 0), tzinfo=local_tz).isoformat()
        status, row = request(
            "POST",
            f"{supabase_url}/rest/v1/mood_logs",
            user_rest_headers,
            {"user_id": user_id, "mood_score": score, "mood_tag": tag, "logged_at": logged_at},
        )
        if status not in (200, 201):
            print(f"failed mood_log for day-{days_ago}: {status} {row}", file=sys.stderr)
            continue
        mood_log_ids[days_ago] = row[0]["id"]

    print(f"seeded {len(mood_log_ids)} mood logs")

    # --- 6. activity tags, correlated with mood score ---
    activity_ok = 0
    tag_sample_counts = {slug: 0 for slug in POSITIVE_TAGS + NEGATIVE_TAGS}
    for days_ago, mood_log_id in mood_log_ids.items():
        score = scores[days_ago]
        chosen: list[str] = []
        if score >= 7:
            chosen += [s for s in POSITIVE_TAGS if s in tag_id_by_slug and rng.random() < 0.6]
        elif score <= 4:
            chosen += [s for s in NEGATIVE_TAGS if s in tag_id_by_slug and rng.random() < 0.6]
        if rng.random() < 0.3:
            filler = rng.choice(NEUTRAL_TAGS)
            if filler in tag_id_by_slug:
                chosen.append(filler)
        chosen = list(dict.fromkeys(chosen))  # dedupe, keep order
        if not chosen:
            continue
        rows = [
            {"mood_log_id": mood_log_id, "activity_tag_id": tag_id_by_slug[slug], "user_id": user_id}
            for slug in chosen
        ]
        status, _ = request(
            "POST", f"{supabase_url}/rest/v1/mood_log_activities", user_rest_headers, rows
        )
        if status not in (200, 201):
            print(f"failed activities for day-{days_ago}: {status}", file=sys.stderr)
            continue
        activity_ok += 1
        for slug in chosen:
            if slug in tag_sample_counts:
                tag_sample_counts[slug] += 1

    print(f"seeded activity tags on {activity_ok} days -- correlated-tag sample sizes: {tag_sample_counts}")
    low_samples = [slug for slug, n in tag_sample_counts.items() if n < 5]
    if low_samples:
        print(
            f"warning: {low_samples} fell below InsightsCard's MIN_SAMPLE=5 -- "
            "correlation card won't show these; rerun with a different RNG_SEED if this matters.",
            file=sys.stderr,
        )

    # --- 7. journal entries: hand-crafted narrative days + generic filler ---
    journal_ok = 0
    distortion_ok = 0
    filler_pool = list(GENERIC_JOURNALS)
    rng.shuffle(filler_pool)
    filler_iter = iter(filler_pool * 3)  # enough to cover filler days with repeats if needed

    for days_ago, mood_log_id in mood_log_ids.items():
        narrative = NARRATIVE_DAYS.get(days_ago)
        body = None
        distortions = None
        reframe = None

        if narrative:
            body = narrative["body"]
            distortions = narrative.get("distortions")
            reframe = narrative.get("reframe")
        elif days_ago in CRISIS_DAYS:
            body = "Rough day, couldn't focus on anything and felt really low."
        elif rng.random() < 0.25:
            body = next(filler_iter)

        if body is None:
            continue

        payload = {"mood_log_id": mood_log_id, "user_id": user_id, "body": body}
        if distortions:
            payload["distortions"] = distortions
            payload["reframe"] = reframe

        status, row = request(
            "POST", f"{supabase_url}/rest/v1/journal_entries", user_rest_headers, payload
        )
        if status not in (200, 201):
            print(f"failed journal_entry for day-{days_ago}: {status} {row}", file=sys.stderr)
            continue
        journal_ok += 1
        if distortions:
            distortion_ok += 1

    print(f"seeded {journal_ok} journal entries ({distortion_ok} with a distortion + reframe)")

    # --- 8. fixture coping_suggestions + ai_call_logs (service_role, matching
    # what the real edge functions write) ---
    suggestion_ok = 0
    saved_count = 0
    days_sorted = sorted(mood_log_ids.keys(), reverse=True)  # oldest first
    for days_ago in days_sorted:
        mood_log_id = mood_log_ids[days_ago]
        score = scores[days_ago]
        tag = tags[days_ago]
        technique = technique_for(tag, rng)
        crisis_signal = score <= 2

        # Feedback loop: mostly no opinion yet, some helpful, few not helpful;
        # only helpful entries can be saved, and only some of those are.
        helpful = rng.choices([None, True, False], weights=[45, 40, 15])[0]
        saved = bool(helpful) and rng.random() < 0.22

        generated_at = dt.datetime.combine(
            today - dt.timedelta(days=days_ago), dt.time(12, 5), tzinfo=local_tz
        ).isoformat()

        status, row = request(
            "POST",
            f"{supabase_url}/rest/v1/coping_suggestions",
            admin_rest_headers,
            {
                "mood_log_id": mood_log_id,
                "user_id": user_id,
                "technique_name": technique["technique_name"],
                "description": technique["description"],
                "steps": technique["steps"],
                "model_used": "qa-fixture",
                "crisis_signal": crisis_signal,
                "helpful": helpful,
                "saved": saved,
                "generated_at": generated_at,
            },
        )
        if status not in (200, 201):
            print(f"failed coping_suggestion for day-{days_ago}: {status} {row}", file=sys.stderr)
            continue
        suggestion_ok += 1
        if saved:
            saved_count += 1

        request(
            "POST",
            f"{supabase_url}/rest/v1/ai_call_logs",
            admin_rest_headers,
            {
                "user_id": user_id,
                "input_tokens": rng.randint(300, 900),
                "output_tokens": rng.randint(150, 400),
                "latency_ms": rng.randint(700, 1900),
                "called_at": generated_at,
            },
        )

    print(f"seeded {suggestion_ok} fixture coping suggestions ({saved_count} saved to Toolkit)")

    # --- 9. weekly_summaries fixtures for every ISO week touched ---
    weeks: dict[str, list[int]] = {}
    for days_ago, score in scores.items():
        date = today - dt.timedelta(days=days_ago)
        weeks.setdefault(week_start_str(date), []).append(score)

    ordered_weeks = sorted(weeks.keys())
    summary_ok = 0
    for i, week_start in enumerate(ordered_weeks):
        week_scores = weeks[week_start]
        avg = sum(week_scores) / len(week_scores)
        content = summary_for_week(avg, len(week_scores), i, len(ordered_weeks))
        status, row = request(
            "POST",
            f"{supabase_url}/rest/v1/weekly_summaries?on_conflict=user_id,week_start",
            {**admin_rest_headers, "Prefer": "return=representation,resolution=merge-duplicates"},
            {
                "user_id": user_id,
                "week_start": week_start,
                "summary": content["summary"],
                "highlights": content["highlights"],
                "model_used": "qa-fixture",
            },
        )
        if status not in (200, 201):
            print(f"failed weekly_summary for week {week_start}: {status} {row}", file=sys.stderr)
            continue
        summary_ok += 1

    print(f"seeded {summary_ok} weekly summaries")

    current_streak_days = len([d for d in CURRENT_STREAK if d in mood_log_ids])
    longest_streak_days = len([d for d in LONGEST_STREAK if d in mood_log_ids])

    print("\nShowcase account ready:")
    print(f"  email:            {SHOWCASE_EMAIL}")
    print(f"  password:         {SHOWCASE_PASSWORD}")
    print(f"  user_id:          {user_id}")
    print(f"  mood logs:        {len(mood_log_ids)} across {DAYS} days")
    print(f"  current streak:   ~{current_streak_days} days (days_ago 0-11)")
    print(f"  longest streak:   ~{longest_streak_days} days (days_ago 40-58)")
    print(f"  crisis window:    days_ago {CRISIS_DAYS} (score <= 2)")
    print(f"  journals:         {journal_ok} ({distortion_ok} with distortion+reframe)")
    print(f"  saved techniques: {saved_count} (Toolkit screen)")
    print(f"  weekly summaries: {summary_ok}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
