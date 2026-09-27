#!/bin/bash
# Installs (or reinstalls) the macOS launchd jobs for Sunday Reset.
# Usage: install_schedule.sh <weekday 0-6, 0=Sunday> <HH:MM weekly> <HH:MM daily sweep>
# Runs:  weekly -> claude -p "/sunday-reset:weekly-run"   daily -> claude -p "/sunday-reset:inbox-sweep"
#        plan day, every 30 min for 3 hours after the weekly email -> claude -p "/sunday-reset:inbox-sweep --replies-only"
set -euo pipefail
WD="$1"; WT="$2"; DT="$3"
CLAUDE="$(command -v claude)"; [ -n "$CLAUDE" ] || { echo "claude not found on PATH" >&2; exit 1; }
BASE="$HOME/Documents/Sunday Reset"; LOGS="$BASE/logs"; mkdir -p "$LOGS"
AGENTS="$HOME/Library/LaunchAgents"; mkdir -p "$AGENTS"
write_plist() { # label hour minute weekday(or -) prompt log [raw calendar xml]
  local label="$1" h=$((10#$2)) m=$((10#$3)) wd="$4" prompt="$5" log="$6" raw="${7:-}"
  local cal="<key>Hour</key><integer>$h</integer><key>Minute</key><integer>$m</integer>"
  [ "$wd" != "-" ] && cal="$cal<key>Weekday</key><integer>$wd</integer>"
  local calblock="<dict>$cal</dict>"
  [ -n "$raw" ] && calblock="$raw"
  cat > "$AGENTS/$label.plist" <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>$label</string>
  <key>ProgramArguments</key><array><string>$CLAUDE</string><string>-p</string><string>$prompt</string></array>
  <key>WorkingDirectory</key><string>$BASE</string>
  <key>StartCalendarInterval</key>$calblock
  <key>StandardOutPath</key><string>$log</string>
  <key>StandardErrorPath</key><string>$log</string>
  <key>EnvironmentVariables</key><dict><key>PATH</key><string>$(dirname "$CLAUDE"):/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin</string></dict>
</dict></plist>
PL
  launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" "$AGENTS/$label.plist"
  echo "INSTALLED $label"
}
write_plist com.sundayreset.weekly "${WT%%:*}" "${WT##*:}" "$WD" "/sunday-reset:weekly-run" "$LOGS/weekly.log"
write_plist com.sundayreset.sweep "${DT%%:*}" "${DT##*:}" - "/sunday-reset:inbox-sweep" "$LOGS/sweep.log"

# Reply watcher: checks every 30 minutes for 5 hours after the scheduled send. The window is longer than
# the 3-hour reply window so a late send (Mac asleep, slow run) is still covered; each check does nothing
# unless the current time is inside [sent_at, reply_until] from state/last-weekly.json.
start=$(( 10#${WT%%:*} * 60 + 10#${WT##*:} )); arr="<array>"
for i in 1 2 3 4 5 6 7 8 9 10; do t=$(( start + i*30 )); d=$WD; [ $t -ge 1440 ] && { t=$((t-1440)); d=$(( (WD+1) % 7 )); }
  arr="$arr<dict><key>Weekday</key><integer>$d</integer><key>Hour</key><integer>$((t/60))</integer><key>Minute</key><integer>$((t%60))</integer></dict>"; done
arr="$arr</array>"
write_plist com.sundayreset.replies 0 0 - "/sunday-reset:inbox-sweep --replies-only" "$LOGS/replies.log" "$arr"
