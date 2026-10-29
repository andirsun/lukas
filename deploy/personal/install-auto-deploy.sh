#!/usr/bin/env bash
# Installs the automatic deploy on a Linux server: a systemd timer that runs auto-deploy.sh every
# 5 minutes, as you (needs sudo). Run it once, yourself, on the server.
#   ./install-auto-deploy.sh             install and start
#   ./install-auto-deploy.sh --render    print the units it would install, change nothing
#   ./install-auto-deploy.sh --remove    stop it and remove the units
# Logs: journalctl -u lukitas-deploy.service
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

units="lukitas-deploy.service lukitas-deploy.timer"

fill() {
  sed -e "s#@REPO_DIR@#$REPO_DIR#g" -e "s#@HOME@#$HOME#g" -e "s#@BASH@#$(command -v bash)#g" \
    -e "s#@USER@#$(id -un)#g" "$1"
}

case "${1:-}" in
  --render)
    for unit in $units; do
      printf '# --- /etc/systemd/system/%s\n' "$unit"
      fill "$DIR/$unit"
    done
    exit 0
    ;;
  --remove)
    sudo systemctl disable --now lukitas-deploy.timer >/dev/null 2>&1 || true
    for unit in $units; do sudo rm -f "/etc/systemd/system/$unit"; done
    sudo systemctl daemon-reload
    say "Removed $units. Deploy by hand with ./update.sh."
    exit 0
    ;;
  "") ;;
  *) die "unknown option: $1" ;;
esac

[ "$(uname)" = "Linux" ] && command -v systemctl >/dev/null 2>&1 || die "this needs a Linux server with systemd"
need_env_file
command -v jq >/dev/null 2>&1 || die "'jq' is not installed (sudo apt install jq)"
# The first run must not find a checkout it would refuse to deploy.
guard_checkout 0 >/dev/null

for unit in $units; do
  fill "$DIR/$unit" | sudo tee "/etc/systemd/system/$unit" >/dev/null
done
sudo systemctl daemon-reload
sudo systemctl enable --now lukitas-deploy.timer
say "Installed $units in /etc/systemd/system"
echo "Every 5 minutes it deploys $(cfg PERSONAL_BRANCH main) once CI has passed ($(cfg DEPLOY_REQUIRED_CHECKS 'check e2e'))."
echo "Run it now:  sudo systemctl start lukitas-deploy.service   (log: journalctl -u lukitas-deploy.service)"
