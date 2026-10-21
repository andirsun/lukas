#!/usr/bin/env bash
# Updates the install to the latest code of the branch this repository is on: backs up the data,
# pulls (fast-forward only), rebuilds and restarts. It never removes volumes, so the data stays.
#
#   ./update.sh               backup, pull, rebuild, restart
#   ./update.sh --skip-backup don't back up first (not recommended)
#   ./update.sh --no-pull     rebuild what is checked out now, without pulling
#   ./update.sh --force       deploy even with uncommitted changes to tracked files or off
#                             PERSONAL_BRANCH (see .env); refused otherwise
# Other options (--no-tunnel, --skip-web) go to up.sh.
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

backup=1
pull=1
force=0
passthrough=()
for arg in "$@"; do
  case "$arg" in
    --skip-backup) backup=0 ;;
    --no-pull) pull=0 ;;
    --force)
      force=1
      passthrough+=("$arg")
      ;;
    -h | --help)
      sed -n '2,10p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) passthrough+=("$arg") ;;
  esac
done

need_env_file
need_docker
# Before anything changes: not a dirty checkout, not another branch.
guard_checkout "$force"

if [ "$backup" = 1 ] && db_running; then
  say "Backing up first"
  "$DIR/backup.sh" --pre-update
elif [ "$backup" = 1 ]; then
  say "The database is not running; nothing to back up"
fi

if [ "$pull" = 1 ]; then
  branch="$(git -C "$REPO_DIR" symbolic-ref --short -q HEAD || true)"
  [ -n "$branch" ] || die "The repository is on a detached HEAD; check out a branch first."
  say "Pulling $branch"
  git -C "$REPO_DIR" pull --ff-only
fi

# ${passthrough[@]+...} keeps an empty array from failing under `set -u` in bash 3.2.
exec "$DIR/up.sh" ${passthrough[@]+"${passthrough[@]}"}
