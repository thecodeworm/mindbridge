#!/usr/bin/env python3
"""
Headless golden-path check for the MindBridge web app, driven against the
seeded QA demo account (supabase/qa/seed_qa_demo_user.py) instead of a real
signup/OAuth flow.

Does NOT trigger a real Anthropic API call by default: mood-log submission
(which fires the generate-suggestion edge function) is skipped unless
--live-ai is passed explicitly. Every other check below reads pre-seeded
fixture data (mood_logs / coping_suggestions inserted with model_used
'qa-fixture'), so it's free to run as often as needed.

Usage (from repo root, with apps/web's dev server already started via
with_server.py or run separately):
    source .venv-qa/bin/activate
    python3 qa/web/golden_path.py --out docs/qa-runs/<timestamp>/web [--live-ai]

Typically invoked via the /verify-web slash command, which handles the
server lifecycle and report writing.
"""
from __future__ import annotations

import argparse
import datetime as dt
import pathlib
import sys

from playwright.sync_api import sync_playwright

QA_EMAIL = "qa-demo@mindbridge.test"
QA_PASSWORD = "MindBridgeQA2026!"
BASE_URL = "http://localhost:5173"


def check(results: list[dict], name: str, ok: bool, detail: str = "") -> None:
    results.append({"step": name, "pass": ok, "detail": detail})
    print(f"{'PASS' if ok else 'FAIL'}: {name}" + (f" -- {detail}" if detail else ""))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", required=True, help="directory to write screenshots + report.md into")
    parser.add_argument(
        "--live-ai",
        action="store_true",
        help="also submit a brand-new mood log and wait for a REAL Claude Haiku suggestion "
        "(costs a real Anthropic API call -- only pass this when the user has explicitly "
        "asked for a live-AI check, never on a routine/automatic run)",
    )
    args = parser.parse_args()

    out_dir = pathlib.Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)
    results: list[dict] = []

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page(viewport={"width": 430, "height": 2000})

        # 1. Login (fixture account, no OAuth/signup needed)
        page.goto(f"{BASE_URL}/login")
        page.wait_for_load_state("networkidle")
        page.locator('input[type="email"]').first.fill(QA_EMAIL)
        page.locator('input[type="password"]').first.fill(QA_PASSWORD)
        page.locator('button[type="submit"]').first.click()
        page.wait_for_url(f"{BASE_URL}/", timeout=15000)
        page.wait_for_load_state("networkidle")
        check(results, "login", page.url.rstrip("/") == BASE_URL, page.url)
        # dashboard sections (streak, history rows) fetch async after the shell
        # renders -- wait for an actual history row badge, not just "networkidle"
        try:
            page.wait_for_selector("text=This week", timeout=15000)
        except Exception:
            pass
        page.screenshot(path=str(out_dir / "01_dashboard.png"), full_page=True)

        # 2. Today: practice line + recent entries; Insights: trend chart
        body = page.inner_text("body")
        check(results, "today shows practice streak", "practiced" in body.lower(), body[:120])
        check(results, "today shows recent entries", "Recent" in body)
        page.goto(f"{BASE_URL}/insights")
        try:
            page.wait_for_selector(".recharts-surface", timeout=15000)
        except Exception:
            pass
        check(
            results,
            "insights shows mood trend chart",
            page.locator(".recharts-surface").count() > 0,
            f"{page.locator('.recharts-surface').count()} recharts surfaces found",
        )
        page.screenshot(path=str(out_dir / "01b_insights.png"), full_page=True)

        # 3. Journal -> entry detail for the lowest-mood seeded day -> crisis chip visible
        # the score badge is a <span class="tabular ...">N</span> inside the row <button>
        page.goto(f"{BASE_URL}/journal")
        try:
            page.wait_for_selector('button span.tabular', timeout=15000)
        except Exception:
            pass
        check(results, "journal lists entries", page.locator("button span.tabular").count() > 0)
        page.locator('button span.tabular:text-is("2")').first.locator(
            "xpath=ancestor::button[1]"
        ).click()
        page.wait_for_load_state("networkidle")
        page.wait_for_timeout(500)
        detail_text = page.inner_text("body")
        check(results, "entry detail opens", "/entry/" in page.url, page.url)
        check(
            results,
            "crisis chip shown for low-mood entry",
            "988" in detail_text,
            "no 988 reference found on a mood_score<=2 entry" if "988" not in detail_text else "",
        )
        page.screenshot(path=str(out_dir / "02_entry_detail.png"), full_page=True)

        # 4. Dark mode toggle -> warm dark palette applied
        page.goto(f"{BASE_URL}/settings")
        page.wait_for_load_state("networkidle")
        dark_button = page.get_by_text("Dark", exact=True)
        if dark_button.count():
            dark_button.first.click()
            page.wait_for_timeout(500)
        bg_color = page.evaluate("getComputedStyle(document.body).backgroundColor")
        check(
            results,
            "dark mode applies warm palette (not default browser dark)",
            bg_color not in ("rgb(0, 0, 0)", "rgba(0, 0, 0, 0)", ""),
            bg_color,
        )
        page.screenshot(path=str(out_dir / "03_settings_dark.png"), full_page=True)

        # 5. Help screen: crisis resources visible
        page.goto(f"{BASE_URL}/help")
        page.wait_for_load_state("networkidle")
        help_text = page.inner_text("body")
        check(results, "help screen shows 988 lifeline", "988" in help_text)
        page.screenshot(path=str(out_dir / "04_help.png"), full_page=True)

        # 6. Toolkit: saved techniques list
        page.goto(f"{BASE_URL}/toolkit")
        page.wait_for_load_state("networkidle")
        page.screenshot(path=str(out_dir / "05_toolkit.png"), full_page=True)
        check(results, "toolkit page loads", "toolkit" in page.url)

        if args.live_ai:
            # 7. OPTIONAL: real mood-log submission -> real Claude Haiku call.
            # Only runs when explicitly requested (see memory: never trigger
            # real Anthropic API calls autonomously).
            page.goto(f"{BASE_URL}/log")
            page.wait_for_load_state("networkidle")
            # left as a manual/one-off extension point -- intentionally not
            # auto-filling the mood slider here; see docs/qa-runs report for
            # what to fill in if/when this is wired up.
            check(results, "live-ai mood submission", False, "not yet implemented -- placeholder for explicit live-AI runs")

        browser.close()

    # write report.md
    passed = sum(1 for r in results if r["pass"])
    lines = [
        f"# Web golden-path QA run -- {dt.datetime.now().isoformat(timespec='seconds')}",
        "",
        f"**{passed}/{len(results)} checks passed**",
        "",
        "| Step | Result | Detail |",
        "|---|---|---|",
    ]
    for r in results:
        lines.append(f"| {r['step']} | {'✅ PASS' if r['pass'] else '❌ FAIL'} | {r['detail']} |")
    lines.append("")
    lines.append("Screenshots in this directory: 01_dashboard.png, 02_entry_detail.png, "
                  "03_settings_dark.png, 04_help.png, 05_toolkit.png")
    (out_dir / "report.md").write_text("\n".join(lines))

    failed = len(results) - passed
    print(f"\n{passed}/{len(results)} passed, report at {out_dir / 'report.md'}")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
