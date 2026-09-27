#!/bin/bash
# Stops Sunday Reset on a Mac: removes its scheduled jobs so nothing else runs.
# Leaves settings, history, calendar events and reminders alone; /sunday-reset:stop offers to remove those.
# Usage: uninstall_schedule.sh
set -euo pipefail
AGENTS="${SUNDAY_RESET_AGENTS_DIR:-$HOME/Library/LaunchAgents}"
UIDN="$(id -u)"; n=0
for label in com.sundayreset.weekly com.sundayreset.sweep com.sundayreset.replies com.sundayreset.test; do
  loaded=""; [ -z "${SUNDAY_RESET_NO_LOAD:-}" ] && launchctl print "gui/$UIDN/$label" >/dev/null 2>&1 && loaded=1
  if [ -n "$loaded" ] || [ -f "$AGENTS/$label.plist" ]; then
    [ -n "$loaded" ] && launchctl bootout "gui/$UIDN/$label" 2>/dev/null || true
    rm -f "$AGENTS/$label.plist"
    echo "REMOVED $label"; n=$((n+1))
  fi
done
[ "$n" -gt 0 ] || echo "NOTHING_SCHEDULED"
