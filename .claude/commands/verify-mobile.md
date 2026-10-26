---
description: Drive the Flutter app via the Dart MCP server through the golden-path flow and verify state
---

Run MindBridge's mobile verification pass against the seeded QA demo account (`qa-demo@mindbridge.test`, password = the `QA_PASSWORD` you seeded it with; it is no longer stored in the repo) using the Dart/Flutter MCP server — no manual tapping.

## One-time setup (already done as of 2026-08-18, check before assuming it's stale)

- `dart` MCP server is registered for this project (`claude mcp list` should show `dart`).
- `apps/mobile/pubspec.yaml` has `flutter_driver` and `integration_test` dev dependencies.
- `apps/mobile/lib/main.dart` calls `enableFlutterDriverExtension()` when built with `--dart-define=ENABLE_FLUTTER_DRIVER=true`.
- No Android AVD exists yet on this machine (no system image installed) — iOS Simulator is the working path. Boot one with `xcrun simctl boot "iPhone 17"` (or another available device from `xcrun simctl list devices available`) then `open -a Simulator`.

## Steps

1. Ensure a simulator is booted (see above) and seed fresh QA data if needed:
   ```
   source .venv-qa/bin/activate && python3 supabase/qa/seed_qa_demo_user.py
   ```

2. Launch the app with the driver extension enabled:
   ```
   cd apps/mobile && flutter run -d <device-id> --dart-define-from-file=.env --dart-define=ENABLE_FLUTTER_DRIVER=true
   ```
   (Get `<device-id>` from `flutter devices` or the Dart MCP server's `list_devices` tool.)

3. Use the Dart MCP server's tools interactively to drive the golden path:
   - `get_widget_tree` to find keys/text for the login form, mood slider, history rows, settings toggles, etc.
   - `tap` / `enter_text` / `scroll` to log in as the QA demo account and walk: dashboard → history → entry detail (verify crisis chip on the low-mood entry) → settings (dark mode toggle, notification toggle) → toolkit → app lock (background via simulator Home gesture, verify lock screen on resume) → JSON export (verify share sheet invoked).
   - `screenshot` after each step.

4. **Do not submit a brand-new mood log through this flow unless the user has explicitly asked for a live AI-suggestion check** — that triggers a real `generate-suggestion` edge function call (real Anthropic API cost). Verify the suggestion-display UI against one of the seeded fixture entries instead.

5. Once a flow has been manually validated via MCP, follow the `flutter-add-integration-test` skill to convert it into a permanent test at `apps/mobile/integration_test/golden_path_test.dart`, so future runs are `flutter drive` rather than a fresh interactive walkthrough. Do this incrementally — one flow at a time — rather than trying to script the entire golden path unattended in one pass.

6. Save screenshots to `docs/qa-runs/<timestamp>/mobile/` and write a `report.md` alongside them, same shape as the web report.

If a widget can't be found, it may be lazily mounted (e.g. inside a `ListView`) — scroll it into view before retrying, per the skill's troubleshooting notes.
