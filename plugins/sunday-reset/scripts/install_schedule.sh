#!/bin/bash
# Installs (or reinstalls) the macOS launchd jobs for Sunday Reset.
# Usage: install_schedule.sh <weekday 0-6, 0=Sunday> <HH:MM weekly> <HH:MM daily sweep>
#        install_schedule.sh --test    one unattended dry run right now, through the same path the schedule uses
# Runs:  weekly -> claude -p "/sunday-reset:weekly-run"   daily -> claude -p "/sunday-reset:inbox-sweep"
#        plan day, every 30 min for 5 hours after the weekly email -> claude -p "/sunday-reset:inbox-sweep --replies-only"
#
# Scheduled runs happen with nobody at the keyboard, so each one starts in --permission-mode dontAsk with an
# explicit allow-list: this plugin's own scripts, reading this plugin's files, editing inside the Sunday Reset
# folder, running skills, and the connector tools setup recorded in config.json (platform.allowed_tools).
# Anything else is refused rather than prompted, so a run can't do something you never approved.
#
# The allow-list names this plugin version's folder, so rerun this after a plugin update (setup does it).
# If the Mac is asleep at a scheduled time, launchd runs the job when it wakes. If it's off, that run is missed.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BASE="$HOME/Documents/Sunday Reset"; LOGS="$BASE/logs"; mkdir -p "$LOGS"
AGENTS="${SUNDAY_RESET_AGENTS_DIR:-$HOME/Library/LaunchAgents}"; mkdir -p "$AGENTS"
CLAUDE="$(command -v claude || true)"; [ -n "$CLAUDE" ] || { echo "claude not found on PATH" >&2; exit 1; }
UIDN="$(id -u)"

# ---- the allow-list every scheduled run gets ----
ALLOW=("Bash(bash $ROOT/scripts/*)" "Bash(python3 $ROOT/scripts/*)" "Read(/$ROOT/**)" "Edit(./**)" "Skill")
if [ -f "$BASE/config.json" ]; then
  while IFS= read -r t; do [ -n "$t" ] && ALLOW+=("$t"); done < <(python3 - "$BASE/config.json" <<'PY'
import json, os, sys
c = json.load(open(sys.argv[1]))
for t in c.get("platform", {}).get("allowed_tools", []):
    print(t)
# weekly history kept in Google Drive or OneDrive sits outside the Sunday Reset folder
p = os.path.abspath(os.path.expanduser(c.get("history", {}).get("path", "") or "~/Documents/Sunday Reset/history"))
if not p.startswith(os.path.expanduser("~/Documents/Sunday Reset")):
    print("Edit(/" + p + "/**)")
PY
)
fi

xml() { sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'; }
args_xml() { # claude -p "<prompt>" --permission-mode dontAsk --allowedTools <each rule>
  local a; for a in "$CLAUDE" -p "$1" --permission-mode dontAsk --allowedTools "${ALLOW[@]}"; do
    printf '<string>%s</string>' "$(printf '%s' "$a" | xml)"; done
}

write_plist() { # label prompt log when-xml
  local label="$1" prompt="$2" log="$3" when="$4"
  cat > "$AGENTS/$label.plist" <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>$label</string>
  <key>ProgramArguments</key><array>$(args_xml "$prompt")</array>
  <key>WorkingDirectory</key><string>$(printf '%s' "$BASE" | xml)</string>
  $when
  <key>StandardOutPath</key><string>$(printf '%s' "$log" | xml)</string>
  <key>StandardErrorPath</key><string>$(printf '%s' "$log" | xml)</string>
  <key>EnvironmentVariables</key><dict><key>PATH</key><string>$(dirname "$CLAUDE"):/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin</string></dict>
</dict></plist>
PL
  plutil -lint -s "$AGENTS/$label.plist"
  if [ -z "${SUNDAY_RESET_NO_LOAD:-}" ]; then
    launchctl bootout "gui/$UIDN/$label" 2>/dev/null || true
    launchctl bootstrap "gui/$UIDN" "$AGENTS/$label.plist"
  fi
  echo "INSTALLED $label"
}
at() { # hour minute [weekday]
  local c="<key>Hour</key><integer>$((10#$1))</integer><key>Minute</key><integer>$((10#$2))</integer>"
  [ -n "${3:-}" ] && c="$c<key>Weekday</key><integer>$3</integer>"
  printf '<key>StartCalendarInterval</key><dict>%s</dict>' "$c"
}

# ---- --test: prove the unattended path works while the user is here to answer macOS prompts ----
if [ "${1:-}" = "--test" ]; then
  label=com.sundayreset.test; log="$LOGS/test.log"; : > "$log"
  write_plist "$label" "/sunday-reset:weekly-run --dry-run" "$log" "<key>RunAtLoad</key><true/>"
  [ -n "${SUNDAY_RESET_NO_LOAD:-}" ] && exit 0
  echo "Running one scheduled-style dry run. Click Allow on any macOS prompt that appears."
  for _ in $(seq 1 90); do   # up to 15 minutes
    sleep 10
    st="$(launchctl print "gui/$UIDN/$label" 2>/dev/null || true)"
    echo "$st" | grep -q 'state = running' || break
  done
  code="$(echo "$st" | sed -n 's/.*last exit code = \([0-9-]*\).*/\1/p' | head -1)"
  launchctl bootout "gui/$UIDN/$label" 2>/dev/null || true; rm -f "$AGENTS/$label.plist"
  echo "---- last lines of $log"; tail -20 "$log"
  if [ "${code:-1}" = "0" ]; then echo "TEST_PASSED"; else echo "TEST_FAILED exit=${code:-unknown}"; exit 1; fi
  exit 0
fi

# ---- the real schedule ----
[ $# -eq 3 ] || { echo "usage: install_schedule.sh <weekday 0-6> <HH:MM> <daily HH:MM> | --test" >&2; exit 2; }
WD="$1"; WT="$2"; DT="$3"
[[ "$WD" =~ ^[0-6]$ && "$WT" =~ ^[0-9]{2}:[0-9]{2}$ && "$DT" =~ ^[0-9]{2}:[0-9]{2}$ ]] || { echo "bad arguments" >&2; exit 2; }
write_plist com.sundayreset.weekly "/sunday-reset:weekly-run" "$LOGS/weekly.log" "$(at "${WT%%:*}" "${WT##*:}" "$WD")"
write_plist com.sundayreset.sweep "/sunday-reset:inbox-sweep" "$LOGS/sweep.log" "$(at "${DT%%:*}" "${DT##*:}")"

# Reply watcher: every 30 minutes for 5 hours after the scheduled send. The window is longer than the 3-hour
# reply window so a late send (Mac asleep, slow run) is still covered; each check does nothing unless the
# current time is inside [sent_at, reply_until] from state/last-weekly.json.
start=$(( 10#${WT%%:*} * 60 + 10#${WT##*:} )); arr=""
for i in 1 2 3 4 5 6 7 8 9 10; do t=$(( start + i*30 )); d=$WD; [ $t -ge 1440 ] && { t=$((t-1440)); d=$(( (WD+1) % 7 )); }
  arr="$arr<dict><key>Weekday</key><integer>$d</integer><key>Hour</key><integer>$((t/60))</integer><key>Minute</key><integer>$((t%60))</integer></dict>"; done
write_plist com.sundayreset.replies "/sunday-reset:inbox-sweep --replies-only" "$LOGS/replies.log" "<key>StartCalendarInterval</key><array>$arr</array>"
echo "ALLOWED_TOOLS ${#ALLOW[@]}"
