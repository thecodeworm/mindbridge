#!/usr/bin/env python3
"""
Creates (or resets) a disposable QA demo account with ~14 days of mood logs,
a couple of journal entries, a low-mood entry (crisis banner check), and
fixture coping suggestions -- so headless web/mobile test runs have real
data to drive against without needing OAuth or a live Claude Haiku call.

Reads SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY from apps/web/.env.local.
Idempotent: deletes any existing user with QA_EMAIL first, then recreates.

Usage:
    source ../../.venv-qa/bin/activate  # from supabase/qa/, or use repo-root .venv-qa
    python3 seed_qa_demo_user.py
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

QA_EMAIL = "qa-demo@mindbridge.test"
QA_PASSWORD = "MindBridgeQA2026!"
QA_DISPLAY_NAME = "QA Demo"

REPO_ROOT = pathlib.Path(__file__).resolve().parents[2]
ENV_FILE = REPO_ROOT / "apps" / "web" / ".env.local"


def load_env(path: pathlib.Path) -> dict[str, str]:
    env: dict[str, str] = {}
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        env[key.strip()] = value.strip()
    return env


def request(method: str, url: str, headers: dict[str, str], body: dict | None = None):
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
    # service_role only has explicit table grants on coping_suggestions /
    # ai_call_logs (migration 0004) -- deliberately narrow, matching what the
    # generate-suggestion edge function actually writes (see 0005's comment
    # "Narrow grants to match what RLS actually allows"). Don't widen that;
    # it's a security-hardening decision, not an oversight. So mood_logs /
    # journal_entries get seeded as the authenticated QA user instead, via
    # RLS, exactly like the real app does.
    admin_rest_headers = {**admin_headers, "Prefer": "return=representation"}

    # --- 1. find + delete any existing QA user (idempotent re-seed) ---
    status, listing = request(
        "GET",
        f"{supabase_url}/auth/v1/admin/users?email={QA_EMAIL}",
        admin_headers,
    )
    if status == 200 and listing:
        users = listing.get("users", listing) if isinstance(listing, dict) else listing
        for u in users or []:
            if u.get("email") == QA_EMAIL:
                request(
                    "DELETE",
                    f"{supabase_url}/auth/v1/admin/users/{u['id']}",
                    admin_headers,
                )
                print(f"deleted existing QA user {u['id']}")

    # --- 2. create the auth user (pre-confirmed, no OAuth/email flow needed) ---
    status, created = request(
        "POST",
        f"{supabase_url}/auth/v1/admin/users",
        admin_headers,
        {
            "email": QA_EMAIL,
            "password": QA_PASSWORD,
            "email_confirm": True,
            "user_metadata": {"display_name": QA_DISPLAY_NAME},
        },
    )
    if status not in (200, 201):
        print(f"failed to create user: {status} {created}", file=sys.stderr)
        return 1
    user_id = created["id"]
    print(f"created QA user {user_id} ({QA_EMAIL})")

    # public.users row is created by the handle_new_user trigger; give it a moment
    # via a direct upsert too, in case the trigger hasn't fired yet under REST timing.
    request(
        "POST",
        f"{supabase_url}/rest/v1/users?on_conflict=id",
        {**admin_rest_headers, "Prefer": "resolution=merge-duplicates"},
        {"id": user_id, "display_name": QA_DISPLAY_NAME},
    )

    # --- 2b. sign in as the QA user so subsequent inserts go through RLS
    # exactly like the real app (auth.uid() = user_id), instead of relying on
    # service_role grants that don't exist for these two tables on purpose.
    status, token_resp = request(
        "POST",
        f"{supabase_url}/auth/v1/token?grant_type=password",
        {"apikey": anon_key, "Content-Type": "application/json"},
        {"email": QA_EMAIL, "password": QA_PASSWORD},
    )
    if status != 200:
        print(f"failed to sign in as QA user: {status} {token_resp}", file=sys.stderr)
        return 1
    access_token = token_resp["access_token"]
    user_rest_headers = {
        "apikey": anon_key,
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json",
        "Prefer": "return=representation",
    }

    # --- 3. seed mood logs across the last 14 days ---
    # scores chosen to cover: streak continuity, 7d/30d chart variation,
    # mood-scale stops (slate/neutral/gold/terracotta), and one <=2 score
    # to exercise the crisis banner path.
    #
    # IMPORTANT: anchor "today" and each timestamp to *local* noon, not UTC.
    # The web/mobile clients compute streaks and the 7d/30d trend window
    # against the browser/device's local calendar day. Anchoring to
    # dt.datetime.now(UTC).date() is wrong whenever local time is far enough
    # from UTC midnight that the UTC date has already rolled to "tomorrow"
    # (e.g. any evening in a UTC-5/-6 zone) -- the newest seeded entry then
    # lands on the wrong local day, and streak/trend both silently break.
    # Local noon is far enough from both the local and UTC day boundary to
    # be safe either way.
    local_now = dt.datetime.now().astimezone()
    today = local_now.date()
    local_tz = local_now.tzinfo
    scores_by_days_ago = {
        13: 6, 12: 7, 11: 5, 10: 2, 9: 4,
        8: 6, 7: 8, 6: 7, 5: 3, 4: 6,
        3: 9, 2: 5, 1: 6, 0: 7,
    }
    # must be one of the 8 values the mood_tag check constraint allows
    # (migration 0005) -- also what's interpolated into the Claude prompt.
    tags = ["happy", "calm", "meh", "sad", "anxious", "angry", "tired", "confused"]

    mood_log_ids: dict[int, str] = {}
    for days_ago, score in scores_by_days_ago.items():
        logged_at = dt.datetime.combine(
            today - dt.timedelta(days=days_ago), dt.time(12, 0), tzinfo=local_tz
        ).isoformat()
        status, row = request(
            "POST",
            f"{supabase_url}/rest/v1/mood_logs",
            user_rest_headers,
            {
                "user_id": user_id,
                "mood_score": score,
                "mood_tag": random.choice(tags),
                "logged_at": logged_at,
            },
        )
        if status not in (200, 201):
            print(f"failed mood_log for day-{days_ago}: {status} {row}", file=sys.stderr)
            continue
        mood_log_ids[days_ago] = row[0]["id"]

    print(f"seeded {len(mood_log_ids)} mood logs")

    # --- 4. journal entries on a couple of days, incl. the crisis-check day ---
    journal_days = {
        10: "Rough day, couldn't focus on anything and felt really low.",
        3: "Great day! Hung out with friends after the exam and felt so relieved.",
        0: "Pretty normal day, just tired from staying up too late.",
    }
    journal_ok = 0
    for days_ago, body in journal_days.items():
        if days_ago not in mood_log_ids:
            continue
        status, row = request(
            "POST",
            f"{supabase_url}/rest/v1/journal_entries",
            user_rest_headers,
            {
                "mood_log_id": mood_log_ids[days_ago],
                "user_id": user_id,
                "body": body,
            },
        )
        if status not in (200, 201):
            print(f"failed journal_entry for day-{days_ago}: {status} {row}", file=sys.stderr)
            continue
        journal_ok += 1
    print(f"seeded {journal_ok} journal entries")

    # --- 5. fixture coping suggestions (no real Anthropic call; service_role
    # has explicit grants here per migration 0004, matching what the real
    # generate-suggestion edge function does) ---
    suggestion_ok = 0
    for days_ago, mood_log_id in mood_log_ids.items():
        status, row = request(
            "POST",
            f"{supabase_url}/rest/v1/coping_suggestions",
            admin_rest_headers,
            {
                "mood_log_id": mood_log_id,
                "user_id": user_id,
                "technique_name": "Box Breathing",
                "description": "A simple grounding technique to slow your breathing and calm your body.",
                "steps": [
                    "Breathe in slowly for 4 counts.",
                    "Hold your breath for 4 counts.",
                    "Breathe out slowly for 4 counts.",
                ],
                "model_used": "qa-fixture",
                "crisis_signal": scores_by_days_ago[days_ago] <= 2,
                "generated_at": dt.datetime.now(dt.timezone.utc).isoformat(),
            },
        )
        if status not in (200, 201):
            print(f"failed coping_suggestion for day-{days_ago}: {status} {row}", file=sys.stderr)
            continue
        suggestion_ok += 1
    print(f"seeded {suggestion_ok} fixture coping suggestions")

    print("\nQA demo account ready:")
    print(f"  email:    {QA_EMAIL}")
    print(f"  password: {QA_PASSWORD}")
    print(f"  user_id:  {user_id}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
