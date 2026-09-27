#!/bin/bash
# Apple Calendar helper (macOS). Writes go straight to the calendar you name, including iCloud calendars.
# Usage:
#   calendar.sh list-calendars
#   calendar.sh add "<calendar>" "<title>" "<YYYY-MM-DD HH:MM>" "<YYYY-MM-DD HH:MM>"   -> prints event uid
#   calendar.sh delete "<calendar>" "<uid>"
#   calendar.sh events "<calendar>" "<YYYY-MM-DD>" "<YYYY-MM-DD>"                       -> title|start|end per line
#
# Titles often come from email subjects, which are untrusted. Every value is passed to AppleScript as an
# argument (argv) and never pasted into the script text, so a crafted title can't run code.
set -euo pipefail
cmd="${1:-}"

datetime_ok() { [[ "$1" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}$ ]]; }
date_ok()     { [[ "$1" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; }

# Builds an AppleScript date from "YYYY-MM-DD HH:MM". Static code, no user data.
MK='on mk(t)
  set d to current date
  set day of d to 1
  set year of d to (text 1 thru 4 of t) as integer
  set month of d to (text 6 thru 7 of t) as integer
  set day of d to (text 9 thru 10 of t) as integer
  set hours of d to (text 12 thru 13 of t) as integer
  set minutes of d to (text 15 thru 16 of t) as integer
  set seconds of d to 0
  return d
end mk'

case "$cmd" in
  list-calendars)
    osascript -e 'tell application "Calendar" to get name of every calendar' ;;
  add)
    [ $# -eq 5 ] || { echo "usage: calendar.sh add <calendar> <title> <start> <end>" >&2; exit 2; }
    datetime_ok "$4" && datetime_ok "$5" || { echo "dates must be YYYY-MM-DD HH:MM" >&2; exit 2; }
    osascript - "$2" "$3" "$4" "$5" <<AS
$MK
on run argv
  set calName to item 1 of argv
  set evTitle to item 2 of argv
  set sd to my mk(item 3 of argv)
  set ed to my mk(item 4 of argv)
  tell application "Calendar"
    tell calendar calName
      set ev to make new event with properties {summary:evTitle, start date:sd, end date:ed}
      return uid of ev
    end tell
  end tell
end run
AS
    ;;
  delete)
    [ $# -eq 3 ] || { echo "usage: calendar.sh delete <calendar> <uid>" >&2; exit 2; }
    osascript - "$2" "$3" <<'AS'
on run argv
  set calName to item 1 of argv
  set theUid to item 2 of argv
  tell application "Calendar" to delete (every event of calendar calName whose uid is theUid)
end run
AS
    ;;
  events)
    [ $# -eq 4 ] || { echo "usage: calendar.sh events <calendar> <from> <to>" >&2; exit 2; }
    date_ok "$3" && date_ok "$4" || { echo "dates must be YYYY-MM-DD" >&2; exit 2; }
    osascript - "$2" "$3 00:00" "$4 23:59" <<AS
$MK
on run argv
  set calName to item 1 of argv
  set sd to my mk(item 2 of argv)
  set ed to my mk(item 3 of argv)
  set out to ""
  tell application "Calendar"
    repeat with ev in (every event of calendar calName whose start date is greater than or equal to sd and start date is less than or equal to ed)
      set out to out & (summary of ev) & "|" & ((start date of ev) as string) & "|" & ((end date of ev) as string) & linefeed
    end repeat
  end tell
  return out
end run
AS
    ;;
  *) echo "usage: calendar.sh list-calendars|add|delete|events" >&2; exit 2 ;;
esac
