#!/usr/bin/env bash
# Stops the daily backup and removes its launchd agent. Existing backups stay where they are.
set -euo pipefail
label="com.lukitas.backup"
target="$HOME/Library/LaunchAgents/$label.plist"

launchctl bootout "gui/$(id -u)/$label" >/dev/null 2>&1 || true
rm -f "$target"
echo "==> Removed $label. Backups already made are untouched."
