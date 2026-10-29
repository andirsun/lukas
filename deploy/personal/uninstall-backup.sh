#!/usr/bin/env bash
# Stops the daily backup: the launchd agent on macOS, the systemd timer and service on Linux.
# Existing backups stay where they are.
set -euo pipefail

if [ "$(uname)" = "Linux" ]; then
  sudo systemctl disable --now lukitas-backup.timer >/dev/null 2>&1 || true
  sudo rm -f /etc/systemd/system/lukitas-backup.timer /etc/systemd/system/lukitas-backup.service
  sudo systemctl daemon-reload
  echo "==> Removed lukitas-backup.timer and lukitas-backup.service. Backups already made are untouched."
  exit 0
fi

label="com.lukitas.backup"
target="$HOME/Library/LaunchAgents/$label.plist"

launchctl bootout "gui/$(id -u)/$label" >/dev/null 2>&1 || true
rm -f "$target"
echo "==> Removed $label. Backups already made are untouched."
