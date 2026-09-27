#!/bin/bash
# Creates the Sunday Reset folder and proves it is writable.
# The folder lives in ~/Library/Application Support/Sunday Reset because macOS blocks background jobs
# (like the Sunday schedule) from writing to Documents, Desktop, Downloads, and iCloud Drive.
#
# Usage: check_folder.sh [--migrate] [--link]
#   --migrate  if an older ~/Documents/Sunday Reset folder exists, move its contents here (run interactively)
#   --link     add a Finder shortcut at ~/Documents/Sunday Reset that points here (run interactively)
set -euo pipefail
DIR="$HOME/Library/Application Support/Sunday Reset"
OLD="$HOME/Documents/Sunday Reset"
MIGRATE=""; LINK=""
for a in "$@"; do case "$a" in --migrate) MIGRATE=1;; --link) LINK=1;; esac; done
mkdir -p "$DIR/history" "$DIR/state" "$DIR/logs" "$DIR/health"
if [ -n "$MIGRATE" ] && [ -d "$OLD" ] && [ ! -L "$OLD" ]; then
  if [ -e "$DIR/config.json" ]; then
    echo "MIGRATE_SKIPPED both folders have settings; ask which config.json to keep"
  else
    cp -Rp "$OLD/." "$DIR/" && rm -rf "$OLD" && echo "MIGRATED $OLD -> $DIR"
  fi
fi
echo "setup-check $(date '+%Y-%m-%d %H:%M:%S')" > "$DIR/.write-test" && rm -f "$DIR/.write-test"
echo "WRITE_OK $DIR"
if [ -n "$LINK" ]; then
  if [ -L "$OLD" ]; then echo "LINK_OK $OLD"
  elif [ -e "$OLD" ]; then echo "LINK_SKIPPED $OLD already exists as a real folder"
  else ln -s "$DIR" "$OLD" && echo "LINK_OK $OLD"; fi
fi
