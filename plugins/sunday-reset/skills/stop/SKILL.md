---
name: stop
description: Stops Sunday Reset. Use when the user says "stop Sunday Reset", "turn it off", "pause it", "unsubscribe", "uninstall", or "delete my Sunday Reset data". Removes the schedule first, then offers (never assumes) to remove what it added and to delete its data.
---

# Stop Sunday Reset

## 1. Remove the schedule (always, no questions)
- Mac: run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/uninstall_schedule.sh`. It prints `REMOVED <job>` for each job or `NOTHING_SCHEDULED`. Confirm with `launchctl list | grep sundayreset`, which should print nothing.
- Windows: `schtasks /Delete /TN "Sunday Reset weekly" /F` and `schtasks /Delete /TN "Sunday Reset daily" /F`.

Then tell the user plainly: no more plan emails, calendar blocks, or reminders from now on. Settings and history are kept, so running `/sunday-reset:setup` and choosing "keep my settings" turns it back on. There is no separate pause: stopping and restarting takes about a minute.

## 2. Offer to remove what it added (ask; act only on an explicit yes)
Read every `~/Documents/Sunday Reset/history/*/written.json`. Count the calendar events and reminders dated today or later, and ask: "Remove the N upcoming calendar blocks and M reminders Sunday Reset added? Past ones stay." On yes, delete only those ids with `calendar.sh delete` and `reminders.sh delete` (or the matching connector), and report what was removed. Never touch anything that isn't listed in a `written.json`.

## 3. Offer to delete its data (ask; act only on an explicit yes)
Show the exact paths first: `~/Documents/Sunday Reset/` (settings, history, logs), plus the history folder in Google Drive or OneDrive if `history.location` in config.json says so. Say that this can't be undone and that the weekly grocery lists on store sites stay. Ask a second time before deleting.

## 4. Removing the plugin itself
Tell the user they can run `/plugin uninstall sunday-reset@sunday-reset`, and `/plugin marketplace remove sunday-reset` to forget the source.
