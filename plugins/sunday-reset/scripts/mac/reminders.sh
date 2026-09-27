#!/bin/bash
# Apple Reminders helper (macOS).
# Usage:
#   reminders.sh list-lists
#   reminders.sh add "<list>" "<title>" ["YYYY-MM-DD"]   -> prints reminder id
#   reminders.sh delete "<list>" "<id>"
#
# Titles often come from email subjects, which are untrusted. Every value is passed to AppleScript as an
# argument (argv) and never pasted into the script text, so a crafted title can't run code.
set -euo pipefail
case "${1:-}" in
  list-lists) osascript -e 'tell application "Reminders" to get name of every list' ;;
  add)
    [ $# -eq 3 ] || [ $# -eq 4 ] || { echo "usage: reminders.sh add <list> <title> [YYYY-MM-DD]" >&2; exit 2; }
    due="${4:-}"
    if [ -n "$due" ]; then
      [[ "$due" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || { echo "due date must be YYYY-MM-DD" >&2; exit 2; }
      osascript - "$2" "$3" "$due" <<'AS'
on run argv
  set listName to item 1 of argv
  set remTitle to item 2 of argv
  set t to item 3 of argv
  set dd to current date
  set day of dd to 1
  set year of dd to (text 1 thru 4 of t) as integer
  set month of dd to (text 6 thru 7 of t) as integer
  set day of dd to (text 9 thru 10 of t) as integer
  set hours of dd to 9
  set minutes of dd to 0
  set seconds of dd to 0
  tell application "Reminders" to return id of (make new reminder at end of list listName with properties {name:remTitle, due date:dd})
end run
AS
    else
      osascript - "$2" "$3" <<'AS'
on run argv
  set listName to item 1 of argv
  set remTitle to item 2 of argv
  tell application "Reminders" to return id of (make new reminder at end of list listName with properties {name:remTitle})
end run
AS
    fi ;;
  delete)
    [ $# -eq 3 ] || { echo "usage: reminders.sh delete <list> <id>" >&2; exit 2; }
    osascript - "$2" "$3" <<'AS'
on run argv
  set listName to item 1 of argv
  set remId to item 2 of argv
  tell application "Reminders" to delete (every reminder of list listName whose id is remId)
end run
AS
    ;;
  *) echo "usage: reminders.sh list-lists|add|delete" >&2; exit 2 ;;
esac
