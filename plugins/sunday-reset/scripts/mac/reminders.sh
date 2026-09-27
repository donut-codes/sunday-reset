#!/bin/bash
# Apple Reminders helper (macOS).
# Usage:
#   reminders.sh list-lists
#   reminders.sh add "<list>" "<title>" ["YYYY-MM-DD"]   -> prints reminder id
#   reminders.sh delete "<list>" "<id>"
set -euo pipefail
case "${1:-}" in
  list-lists) osascript -e 'tell application "Reminders" to get name of every list' ;;
  add)
    list="$2"; title="$3"; due="${4:-}"
    if [ -n "$due" ]; then
      y=${due:0:4}; m=$((10#${due:5:2})); d=$((10#${due:8:2}))
      osascript <<AS
set dd to current date
set day of dd to 1
set year of dd to $y
set month of dd to $m
set day of dd to $d
set hours of dd to 9
set minutes of dd to 0
tell application "Reminders" to return id of (make new reminder at end of list "$list" with properties {name:"$title", due date:dd})
AS
    else
      osascript -e "tell application \"Reminders\" to return id of (make new reminder at end of list \"$list\" with properties {name:\"$title\"})"
    fi ;;
  delete) osascript -e "tell application \"Reminders\" to delete (every reminder of list \"$2\" whose id is \"$3\")" ;;
  *) echo "usage: reminders.sh list-lists|add|delete" >&2; exit 2 ;;
esac
