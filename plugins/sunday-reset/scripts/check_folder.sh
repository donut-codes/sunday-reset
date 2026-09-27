#!/bin/bash
# Creates the Sunday Reset folder, proves it is writable, and reports whether iCloud has offloaded anything.
# Usage: check_folder.sh ["~/Documents/Sunday Reset"]
set -euo pipefail
DIR="${1:-$HOME/Documents/Sunday Reset}"
DIR="${DIR/#\~/$HOME}"
mkdir -p "$DIR/history" "$DIR/state" "$DIR/logs" "$DIR/health"
echo "setup-check $(date '+%Y-%m-%d %H:%M:%S')" > "$DIR/.write-test" && rm -f "$DIR/.write-test"
echo "WRITE_OK $DIR"
if [ "$(uname)" = "Darwin" ]; then
  offloaded=$(find "$DIR" -maxdepth 2 -type f -exec stat -f '%Sf %N' {} \; 2>/dev/null | grep -c dataless || true)
  if [ "$offloaded" -gt 0 ]; then echo "OFFLOADED_FILES $offloaded (right-click the folder in Finder and choose Keep Downloaded)"; else echo "NO_OFFLOADED_FILES"; fi
fi
