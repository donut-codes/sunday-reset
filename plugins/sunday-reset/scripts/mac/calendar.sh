#!/bin/bash
# Apple Calendar helper (macOS). Writes go straight to the calendar you name, including iCloud calendars.
# Usage:
#   calendar.sh list-calendars
#   calendar.sh add "<calendar>" "<title>" "<YYYY-MM-DD HH:MM>" "<YYYY-MM-DD HH:MM>"   -> prints event uid
#   calendar.sh delete "<calendar>" "<uid>"
#   calendar.sh events "<calendar>" "<YYYY-MM-DD>" "<YYYY-MM-DD>"                       -> title|start|end per line
set -euo pipefail
cmd="${1:-}"
mkdate() { # emits AppleScript that builds a date variable named $1 from "$2"
  local v="$1" d="$2"
  local y=${d:0:4} m=$((10#${d:5:2})) dd=$((10#${d:8:2})) hh=$((10#${d:11:2})) mm=$((10#${d:14:2}))
  cat <<AS
set $v to current date
set day of $v to 1
set year of $v to $y
set month of $v to $m
set day of $v to $dd
set hours of $v to $hh
set minutes of $v to $mm
set seconds of $v to 0
AS
}
case "$cmd" in
  list-calendars)
    osascript -e 'tell application "Calendar" to get name of every calendar' ;;
  add)
    cal="$2"; title="$3"; start="$4"; end="$5"
    osascript <<AS
$(mkdate s "$start")
$(mkdate e "$end")
tell application "Calendar"
  tell calendar "$cal"
    set ev to make new event with properties {summary:"$title", start date:s, end date:e}
    return uid of ev
  end tell
end tell
AS
    ;;
  delete)
    cal="$2"; uid="$3"
    osascript -e "tell application \"Calendar\" to delete (every event of calendar \"$cal\" whose uid is \"$uid\")" ;;
  events)
    cal="$2"; from="$3 00:00"; to="$4 23:59"
    osascript <<AS
$(mkdate s "$from")
$(mkdate e "$to")
set out to ""
tell application "Calendar"
  repeat with ev in (every event of calendar "$cal" whose start date ≥ s and start date ≤ e)
    set out to out & (summary of ev) & "|" & ((start date of ev) as string) & "|" & ((end date of ev) as string) & linefeed
  end repeat
end tell
return out
AS
    ;;
  *) echo "usage: calendar.sh list-calendars|add|delete|events" >&2; exit 2 ;;
esac
