---
description: Run the headless web golden-path QA check against the seeded QA demo account
---

Run MindBridge's headless web verification pass, driven by Playwright against the seeded QA demo account (`qa-demo@mindbridge.test`) — no OAuth or manual clicking involved.

1. Make sure the QA demo account has fresh data. Run (from repo root):
   ```
   source .venv-qa/bin/activate && python3 supabase/qa/seed_qa_demo_user.py
   ```
   This is idempotent — it deletes and recreates the account with 14 days of mood logs, journal entries, and fixture coping suggestions. Re-run it any time the data looks stale or a prior run mutated it (edited/deleted an entry, etc).

2. Run the golden path against a fresh dev server:
   ```
   cd apps/web && python3 ../../.claude/skills/webapp-testing/scripts/with_server.py \
     --server "npm run dev" --port 5173 --timeout 60 -- \
     python3 ../../qa/web/golden_path.py --out ../../docs/qa-runs/$(date +%Y-%m-%d-%H%M)/web
   ```

3. Read the generated `report.md` in that output directory and summarize pass/fail to the user, including any screenshot that shows a failure.

**Do not pass `--live-ai`** unless the user has explicitly asked for a live AI-suggestion check in this same request — it submits a brand-new mood log and triggers a real Claude Haiku call through the `generate-suggestion` edge function (real API cost). Every other check in this script runs against pre-seeded fixture data and costs nothing.

If checks fail, don't just report red — read the relevant page's source under `apps/web/src` to see if a selector changed, fix `qa/web/golden_path.py` if it's a script problem, or flag a real regression if the app itself is broken.
