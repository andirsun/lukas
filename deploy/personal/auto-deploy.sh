#!/usr/bin/env bash
# Deploys PERSONAL_BRANCH (main) on its own when it moves and CI has passed for the new commit. The
# server asks; nothing outside it can reach in: GitHub holds no key to this machine. Run by
# lukitas-deploy.timer every 5 minutes (install-auto-deploy.sh); by hand it does the same once.
#
#   1. `git ls-remote`: the branch's newest commit. The same one checked out: done, quietly.
#   2. A commit that failed before (CI, the deploy or its smoke test) is skipped from then on.
#   3. It must follow from what is checked out (a rewritten branch is refused: a person decides).
#   4. CI: every check in DEPLOY_REQUIRED_CHECKS (default "check e2e") completed and passed, asked
#      of GitHub's public API. Still running, or not started: try again next time. Failed: skip it.
#   5. That exact commit is checked out (not a newer one pushed meanwhile), then `update.sh
#      --no-pull` (a backup first, then rebuild and restart) and `smoke.sh`.
#   6. If either fails: back to the commit before, rebuilt without a backup, and the commit is
#      marked failed. The pre-update backup is still there in case a migration had run.
#
# Logs: journalctl -u lukitas-deploy.service. Settings (.env): PERSONAL_BRANCH,
# DEPLOY_REQUIRED_CHECKS, DEPLOY_GITHUB_REPO (default: from the origin URL). State (failed commits,
# the lock): ~/.local/state/lukitas.
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

repo="${LUKITAS_DEPLOY_REPO:-$REPO_DIR}"
state="${LUKITAS_STATE_DIR:-$HOME/.local/state/lukitas}"
update="${LUKITAS_DEPLOY_UPDATE:-$DIR/update.sh}"
smoke="${LUKITAS_DEPLOY_SMOKE:-$DIR/smoke.sh}"
api="${LUKITAS_GITHUB_API:-https://api.github.com}"
branch="$(cfg PERSONAL_BRANCH main)"
required="$(cfg DEPLOY_REQUIRED_CHECKS "check e2e")"
failed_list="$state/failed-commits"

need_env_file
command -v jq >/dev/null 2>&1 || die "'jq' is not installed (apt install jq)"
mkdir -p "$state"
touch "$failed_list"

# One deploy at a time. systemd never overlaps a service with itself; this covers a run by hand. A
# lock left by a process that is gone (killed, the machine restarted) is taken over.
lock="$state/deploy.lock"
if ! mkdir "$lock" 2>/dev/null; then
  holder="$(cat "$lock/pid" 2>/dev/null || true)"
  if [ -n "$holder" ] && kill -0 "$holder" 2>/dev/null; then
    say "Another deploy is running (pid $holder)"
    exit 0
  fi
  rm -rf "$lock"
  mkdir "$lock"
fi
printf '%s\n' "$$" >"$lock/pid"
trap 'rm -rf "$lock"' EXIT

current="$(git -C "$repo" rev-parse HEAD)"
target="$(git -C "$repo" ls-remote origin "refs/heads/$branch" | cut -f1)"
[ -n "$target" ] || die "origin has no branch $branch"
[ "$target" != "$current" ] || exit 0
short="${target:0:9}"

if grep -qx "$target" "$failed_list"; then
  say "Skipping $short: it failed before (remove it from $failed_list to try again)"
  exit 0
fi

git -C "$repo" fetch -q origin "$branch"
git -C "$repo" merge-base --is-ancestor "$current" "$target" ||
  die "$branch at $short does not follow from ${current:0:9}: it was rewritten. Not deploying; a person has to look."

# ci_state SHA: success, pending or failure, for the required checks of that commit.
ci_state() {
  local slug json name state
  slug="$(cfg DEPLOY_GITHUB_REPO)"
  if [ -z "$slug" ]; then
    slug="$(git -C "$repo" remote get-url origin | sed -E 's#^(https://github.com/|git@github.com:)##; s#\.git$##')"
  fi
  json="$(curl -fsS -H "Accept: application/vnd.github+json" \
    "$api/repos/$slug/commits/$1/check-runs?per_page=100")" || {
    echo pending
    return
  }
  for name in $required; do
    state="$(jq -r --arg n "$name" \
      '[.check_runs[] | select(.name == $n)] | last | if . == null then "missing" else .status + " " + (.conclusion // "none") end' \
      <<<"$json")"
    case "$state" in
      "completed success" | "completed skipped" | "completed neutral") ;;
      completed*)
        say "CI: $name is ${state#completed }" >&2
        echo failure
        return
        ;;
      *)
        say "CI: waiting for $name (${state%% *})" >&2
        echo pending
        return
        ;;
    esac
  done
  echo success
}

# Only a plain "success" deploys: anything else, even an answer this script does not expect, does not.
ci="$(ci_state "$target")"
case "$ci" in
  success) ;;
  pending) exit 0 ;;
  *)
    say "Not deploying $short: CI failed"
    printf '%s\n' "$target" >>"$failed_list"
    exit 0
    ;;
esac

# The build needs node and pnpm, which nvm puts on PATH only in a login shell.
if ! command -v node >/dev/null 2>&1 && [ -s "${NVM_DIR:-$HOME/.nvm}/nvm.sh" ]; then
  # shellcheck disable=SC1091
  . "${NVM_DIR:-$HOME/.nvm}/nvm.sh"
fi

say "Deploying $short ($(git -C "$repo" log -1 --format=%s "$target"))"
git -C "$repo" merge -q --ff-only "$target"
if "$update" --no-pull && "$smoke"; then
  say "Deployed $short"
  exit 0
fi

say "The deploy of $short failed: going back to ${current:0:9}"
printf '%s\n' "$target" >>"$failed_list"
git -C "$repo" reset -q --hard "$current"
"$update" --no-pull --skip-backup || say "WARNING: rebuilding ${current:0:9} failed too; look at it now"
die "deploy of $short failed and was rolled back (the pre-update backup is in BACKUP_DIR)"
