#!/usr/bin/env bash
# Tests auto-deploy.sh in a temporary folder: a local "origin" repository and a clone of it as the
# install, a fake GitHub API (curl on PATH answers from a file), and fake update.sh and smoke.sh
# that only record what they were asked. No Docker, no network. Run: ./test-auto-deploy.sh
#
# What it checks: nothing happens while main has not moved, while CI is still running or has not
# started; a commit whose required checks pass is deployed exactly (not a newer one pushed
# meanwhile), and a failed one never is, nor asked about again; other checks (mobile, the landing)
# do not count; a deploy that fails, or whose smoke test fails, goes back to the commit before; a
# main that was rewritten is refused.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
. "$here/lib.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
failures=0

# --- The repositories: origin (bare) and the install's checkout of main. ---------------------
git init -q --bare -b main "$tmp/origin.git"
git clone -q "$tmp/origin.git" "$tmp/install" 2>/dev/null
git_in() { git -C "$1" -c user.name=test -c user.email=test@example.com "${@:2}"; }
# commit_on_origin MESSAGE: a new commit on origin's main (made in a scratch clone); prints its sha.
commit_on_origin() {
  [ -d "$tmp/dev" ] || git clone -q "$tmp/origin.git" "$tmp/dev" 2>/dev/null
  git_in "$tmp/dev" pull -q --ff-only origin main 2>/dev/null || true
  printf '%s\n' "$1" >>"$tmp/dev/history.txt"
  git_in "$tmp/dev" add history.txt
  git_in "$tmp/dev" commit -q -m "$1"
  git_in "$tmp/dev" push -q origin HEAD:main
  git -C "$tmp/dev" rev-parse HEAD
}
first="$(commit_on_origin "first")"
git_in "$tmp/install" pull -q --ff-only origin main

# --- The fakes. ---------------------------------------------------------------------------------
mkdir "$tmp/bin" "$tmp/state"
export FAKE_LOG="$tmp/calls.log" FAKE_CHECKS="$tmp/checks.json"
: >"$FAKE_LOG"
# curl: logs the URL, prints the check runs from FAKE_CHECKS, and runs FAKE_CURL_HOOK if set.
cat >"$tmp/bin/curl" <<'EOF'
#!/usr/bin/env bash
for a in "$@"; do case "$a" in http*) printf 'api %s\n' "$a" >>"$FAKE_LOG" ;; esac; done
[ -z "${FAKE_CURL_HOOK:-}" ] || eval "$FAKE_CURL_HOOK"
cat "$FAKE_CHECKS"
EOF
# update.sh and smoke.sh: log their arguments and the commit checked out; fail on request.
cat >"$tmp/bin/fake-update" <<'EOF'
#!/usr/bin/env bash
printf 'update %s at %s\n' "$*" "$(git -C "$LUKITAS_DEPLOY_REPO" rev-parse HEAD)" >>"$FAKE_LOG"
[ "${FAKE_UPDATE_FAILS_AT:-}" != "$(git -C "$LUKITAS_DEPLOY_REPO" rev-parse HEAD)" ]
EOF
cat >"$tmp/bin/fake-smoke" <<'EOF'
#!/usr/bin/env bash
printf 'smoke at %s\n' "$(git -C "$LUKITAS_DEPLOY_REPO" rev-parse HEAD)" >>"$FAKE_LOG"
[ "${FAKE_SMOKE_FAILS_AT:-}" != "$(git -C "$LUKITAS_DEPLOY_REPO" rev-parse HEAD)" ]
EOF
chmod +x "$tmp/bin/"*
PATH="$tmp/bin:$PATH"

export LUKITAS_DEPLOY_REPO="$tmp/install" LUKITAS_STATE_DIR="$tmp/state"
export LUKITAS_DEPLOY_UPDATE="$tmp/bin/fake-update" LUKITAS_DEPLOY_SMOKE="$tmp/bin/fake-smoke"
export ENV_FILE="$tmp/.env"
printf 'PERSONAL_BRANCH=main\nDEPLOY_GITHUB_REPO=slinqer/lukitas\n' >"$ENV_FILE"

# checks NAME=STATUS:CONCLUSION...: what the fake API answers.
checks() {
  local runs="" item name rest status conclusion
  for item in "$@"; do
    name="${item%%=*}" rest="${item#*=}" status="${rest%%:*}" conclusion="${rest#*:}"
    [ "$conclusion" = "-" ] && conclusion=null || conclusion="\"$conclusion\""
    runs="$runs${runs:+,}{\"name\":\"$name\",\"status\":\"$status\",\"conclusion\":$conclusion}"
  done
  printf '{"total_count":%s,"check_runs":[%s]}\n' "$#" "$runs" >"$FAKE_CHECKS"
}

deploy() { "$here/auto-deploy.sh" >"$tmp/out.log" 2>&1; }
head_is() { [ "$(git -C "$tmp/install" rev-parse HEAD)" = "$1" ]; }
log_has() { grep -qF -- "$1" "$FAKE_LOG"; }
log_lacks() { ! grep -qF -- "$1" "$FAKE_LOG"; }
check() {
  local what="$1"
  shift
  if "$@"; then
    printf 'ok   %s\n' "$what"
  else
    printf 'FAIL %s\n' "$what" >&2
    sed 's/^/       /' "$tmp/out.log" >&2
    failures=$((failures + 1))
  fi
}
fresh() { : >"$FAKE_LOG"; }

# 1. main has not moved: nothing at all, not even a question to GitHub.
checks check=completed:success e2e=completed:success
fresh
check "main unchanged: it succeeds" deploy
check "main unchanged: no API call" eval '[ ! -s "$FAKE_LOG" ]'

# 2. A new commit while CI runs: wait.
second="$(commit_on_origin "second")"
checks check=completed:success e2e=in_progress:-
fresh
check "CI running: it succeeds" deploy
check "CI running: nothing deployed" head_is "$first"
check "CI running: update.sh not run" log_lacks "update"
check "CI running: it asked about that commit" log_has "commits/$second/check-runs"

# 3. CI has not started: no check runs yet. Wait too.
checks
fresh
check "CI not started: nothing deployed" eval 'deploy && head_is "$first"'

# 4. Required checks pass; mobile skipped and the landing failing do not count.
checks check=completed:success e2e=completed:success mobile=completed:skipped deploy-landing=completed:failure
fresh
check "CI passed: it succeeds" deploy
check "CI passed: the commit is checked out" head_is "$second"
check "CI passed: update.sh rebuilds without pulling" log_has "update --no-pull at $second"
check "CI passed: then the smoke test" log_has "smoke at $second"
fresh
check "deployed: the next run does nothing" eval 'deploy && [ ! -s "$FAKE_LOG" ]'

# 5. A required check fails: never deployed, and not asked about again.
third="$(commit_on_origin "third")"
checks check=completed:success e2e=completed:failure
fresh
check "CI failed: it succeeds" deploy
check "CI failed: nothing deployed" head_is "$second"
check "CI failed: update.sh not run" log_lacks "update"
fresh
check "CI failed: the next run skips it" deploy
check "CI failed: without asking GitHub again" eval '[ ! -s "$FAKE_LOG" ]'

# 6. The smoke test fails: back to the commit before, rebuilt, and the commit is not retried.
fourth="$(commit_on_origin "fourth")"
checks check=completed:success e2e=completed:success
export FAKE_SMOKE_FAILS_AT="$fourth"
fresh
check "smoke failed: it fails" eval '! deploy'
check "smoke failed: back to the commit before" head_is "$second"
check "smoke failed: the commit before is rebuilt, without a backup" log_has "update --no-pull --skip-backup at $second"
unset FAKE_SMOKE_FAILS_AT
fresh
check "smoke failed: the next run skips it" eval 'deploy && head_is "$second" && [ ! -s "$FAKE_LOG" ]'

# 7. update.sh fails: the same.
fifth="$(commit_on_origin "fifth")"
export FAKE_UPDATE_FAILS_AT="$fifth"
fresh
check "update failed: it fails" eval '! deploy'
check "update failed: back to the commit before" head_is "$second"
check "update failed: the commit before is rebuilt" log_has "update --no-pull --skip-backup at $second"
unset FAKE_UPDATE_FAILS_AT

# 8. main moves again while CI is being checked: what was checked is deployed, not the newer one.
sixth="$(commit_on_origin "sixth")"
export FAKE_CURL_HOOK="commit_on_origin seventh >/dev/null"
export -f commit_on_origin git_in
export tmp
fresh
check "main moved meanwhile: it succeeds" deploy
check "main moved meanwhile: the checked commit is deployed" head_is "$sixth"
unset FAKE_CURL_HOOK

# 9. main rewritten (force-pushed): refused, nothing deployed.
git_in "$tmp/dev" pull -q --ff-only origin main
git_in "$tmp/dev" reset -q --hard "$first"
printf 'other\n' >"$tmp/dev/other.txt"
git_in "$tmp/dev" add other.txt
git_in "$tmp/dev" commit -q -m "rewritten"
git_in "$tmp/dev" push -q -f origin HEAD:main
fresh
check "main rewritten: it fails" eval '! deploy'
check "main rewritten: nothing deployed" head_is "$sixth"
check "main rewritten: update.sh not run" log_lacks "update"

[ "$failures" = 0 ] || die "$failures auto-deploy check(s) failed"
say "Auto-deploy: all checks passed"
