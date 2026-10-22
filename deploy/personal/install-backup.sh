#!/usr/bin/env bash
# Installs the daily backup (03:00) as a launchd agent for your user. Run it once, yourself.
#   ./install-backup.sh            install and load
#   ./install-backup.sh --render   print the plist it would install, change nothing
# Remove it with ./uninstall-backup.sh. Logs: ~/Library/Logs/lukitas-backup.log
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

label="com.lukitas.backup"
target="$HOME/Library/LaunchAgents/$label.plist"

render() {
  sed -e "s#@REPO_DIR@#$REPO_DIR#g" -e "s#@HOME@#$HOME#g" -e "s#@BASH@#$(command -v bash)#g" \
    "$DIR/$label.plist"
}

if [ "${1:-}" = "--render" ]; then
  render
  exit 0
fi

[ "$(uname)" = "Darwin" ] || die "launchd is macOS only. On Linux use cron or a systemd timer to run backup.sh daily."
need_env_file
mkdir -p "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"
render >"$target"
plutil -lint "$target" >/dev/null || die "the generated plist is not valid: $target"

# Reload if it was already installed.
launchctl bootout "gui/$(id -u)/$label" >/dev/null 2>&1 || true
launchctl bootstrap "gui/$(id -u)" "$target"
launchctl enable "gui/$(id -u)/$label"

say "Installed $target"
echo "Backs up every day at 03:00 (or when the Mac wakes, if it was asleep) into $(cfg BACKUP_DIR '~/Backups/lukitas')"
echo "Try it now:  launchctl kickstart gui/$(id -u)/$label   (log: ~/Library/Logs/lukitas-backup.log)"
