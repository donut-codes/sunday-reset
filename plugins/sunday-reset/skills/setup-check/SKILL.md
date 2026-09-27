---
name: setup-check
description: Verifies every Sunday Reset integration with a read test and a write test that cleans up after itself, then emails a pass/fail report with a fun fact about each skill. Use after setup, when something seems broken, when the user asks to "check", "test", or "verify" Sunday Reset, or before a demo.
---

# Sunday Reset setup check

Read `~/Documents/Sunday Reset/config.json` first. Run each check, record PASS, FAIL (with the exact fix), or SKIP (not configured). Never leave test data behind.

| Check | How | Cleanup |
|---|---|---|
| Folder | `bash ${CLAUDE_PLUGIN_ROOT}/scripts/check_folder.sh` shows `WRITE_OK` and `NO_OFFLOADED_FILES` | none |
| Python | `python3 --version` prints a version (the email is rendered with it). Fix: `xcode-select --install` | none |
| Config | config.json parses and has `user.email` | none |
| Calendar read | `calendar.sh events "<calendar_name>" <today> <today+7>` | none |
| Calendar write | `calendar.sh add` a "Sunday Reset test" event today at 23:00 to 23:15, capture uid | `calendar.sh delete` with that uid |
| Reminders | `reminders.sh add "<list>" "Sunday Reset test"` | `reminders.sh delete` |
| Gmail read | search the inbox for the last day, metadata only | none |
| Email send | send the report below to `user.email` only | none |
| Draft fallback | only if send failed: save the report as a draft | none |
| Health data | `health/latest.json` exists and is from today or yesterday | none |
| Chrome | the Claude in Chrome extension answers; for each configured store, a search for one staple returns a price | close tabs |
| History | write and read back `history/.check` (or the Drive/OneDrive folder) | delete it |
| Schedule (Mac) | `launchctl list | grep sundayreset` shows `weekly`, `sweep`, and `replies`, and `~/Library/LaunchAgents/com.sundayreset.weekly.plist` contains `${CLAUDE_PLUGIN_ROOT}`. If it names a different folder, the plugin was updated since the schedule was installed: rerun `/sunday-reset:setup` and keep the settings | none |

## The report email
Subject: `Sunday Reset setup check: X of Y passed`. Render with the same look as the weekly email: build a plan JSON with a single "Checks" day list (kind `meal` for pass, `admin` for fail, `busy` for skipped) and run `python3 ${CLAUDE_PLUGIN_ROOT}/scripts/render_email.py plan.json out.html`. Include one short fun fact per skill, for example: "Grocery check reads price per ounce, so a bigger jar only wins when it's actually cheaper."

Print the same table in the terminal. For each FAIL, say exactly what the user should do next.
