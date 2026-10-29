#!/usr/bin/env bash
# Tests the R2 copy of the backups (r2_* in lib.sh) against a fake rclone on PATH that records how
# it was called: no Docker, no network, no Cloudflare account. Run: ./test-r2.sh
#
# What it checks: R2 is off without a bucket and refused when half set up; only an encrypted copy
# (.age) is ever uploaded; the keys reach rclone through its environment, never its arguments (they
# would show in `ps`); an upload counts only once the object is listed; a download asks for the
# named object.
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
failures=0

# The fake rclone: logs its arguments and the R2 settings it was given, one call per line; lists
# an object only if it "uploaded" it; FAKE_RCLONE_FAIL=copyto makes that command fail.
mkdir "$tmp/bin"
cat >"$tmp/bin/rclone" <<'EOF'
#!/usr/bin/env bash
printf 'args: %s\n' "$*" >>"$FAKE_RCLONE_LOG"
printf 'env: %s %s %s %s %s\n' "${RCLONE_CONFIG_R2_TYPE:-}" "${RCLONE_CONFIG_R2_PROVIDER:-}" \
  "${RCLONE_CONFIG_R2_ACCESS_KEY_ID:-}" "${RCLONE_CONFIG_R2_SECRET_ACCESS_KEY:-}" \
  "${RCLONE_CONFIG_R2_ENDPOINT:-}" >>"$FAKE_RCLONE_LOG"
[ "${FAKE_RCLONE_FAIL:-}" != "$1" ] || exit 1
case "$1" in
  copyto)
    case "$2" in
      r2:*) cp "$FAKE_RCLONE_STORE/${2##*/}" "$3" ;;
      *) cp "$2" "$FAKE_RCLONE_STORE/${3##*/}" ;;
    esac
    ;;
  lsf) [ ! -f "$FAKE_RCLONE_STORE/${2##*/}" ] || printf '%s\n' "${2##*/}" ;;
esac
EOF
chmod +x "$tmp/bin/rclone"
PATH="$tmp/bin:$PATH"
export FAKE_RCLONE_LOG="$tmp/rclone.log" FAKE_RCLONE_STORE="$tmp/store"
mkdir "$FAKE_RCLONE_STORE"

# A .env with only the R2 settings this test sets.
export ENV_FILE="$tmp/.env"
r2_env() {
  printf 'BACKUP_R2_BUCKET=%s\nBACKUP_R2_ENDPOINT=%s\nBACKUP_R2_ACCESS_KEY_ID=%s\nBACKUP_R2_SECRET_ACCESS_KEY=%s\n' \
    "$1" "$2" "$3" "$4" >"$ENV_FILE"
}

check() {
  local what="$1"
  shift
  if "$@"; then
    printf 'ok   %s\n' "$what"
  else
    printf 'FAIL %s\n' "$what" >&2
    failures=$((failures + 1))
  fi
}
log_has() { grep -qF -- "$1" "$FAKE_RCLONE_LOG"; }
log_lacks() { ! grep -qF -- "$1" "$FAKE_RCLONE_LOG"; }

endpoint="https://abc123.r2.cloudflarestorage.com"
dump="$tmp/lukitas-2026-10-29.dump"
printf 'plain dump\n' >"$dump"
printf 'encrypted dump\n' >"$dump.age"

# Off: no bucket, nothing set.
r2_env "" "" "" ""
check "no bucket: R2 is off" eval '! r2_enabled'
check "no bucket: the settings are fine" eval '[ -z "$(r2_problem)" ]'

# Half set up: a bucket but no keys is refused, not silently skipped.
r2_env lukitas-backups "$endpoint" "" ""
check "a bucket without keys is a problem" eval '[ -n "$(r2_problem)" ]'
r2_env lukitas-backups "" key-id secret-key
check "a bucket without an endpoint is a problem" eval '[ -n "$(r2_problem)" ]'

r2_env lukitas-backups "$endpoint" key-id secret-key
check "fully set up: R2 is on" r2_enabled
check "fully set up: no problem" eval '[ -z "$(r2_problem)" ]'

# Only an encrypted copy goes up.
: >"$FAKE_RCLONE_LOG"
check "a plain dump is refused" eval '! r2_upload "$dump" 2>/dev/null'
check "a refused dump never reaches rclone" eval '[ ! -s "$FAKE_RCLONE_LOG" ]'

# The upload, then the listing that proves it is there.
: >"$FAKE_RCLONE_LOG"
check "an encrypted copy uploads" r2_upload "$dump.age"
check "it goes to the bucket under its own name" log_has "args: copyto $dump.age r2:lukitas-backups/lukitas-2026-10-29.dump.age"
check "the upload is checked by listing it" log_has "args: lsf r2:lukitas-backups/lukitas-2026-10-29.dump.age"
check "rclone gets the R2 settings in its environment" log_has "env: s3 Cloudflare key-id secret-key $endpoint"
check "the secret is never an argument" eval '! grep "^args:" "$FAKE_RCLONE_LOG" | grep -q secret-key'

# A failed upload is a failure.
rm -f "$FAKE_RCLONE_STORE"/*
export FAKE_RCLONE_FAIL=copyto
check "a failed upload fails" eval '! r2_upload "$dump.age" 2>/dev/null'
unset FAKE_RCLONE_FAIL

# An upload rclone reports as done but that does not list is a failure too.
mkdir "$tmp/bin-lost"
cat >"$tmp/bin-lost/rclone" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$tmp/bin-lost/rclone"
check "an upload that does not list fails" eval '(PATH="$tmp/bin-lost:$PATH"; ! r2_upload "$dump.age" 2>/dev/null)'

# The download asks for the named object and writes it where told.
r2_upload "$dump.age" >/dev/null
: >"$FAKE_RCLONE_LOG"
check "a download works" r2_download lukitas-2026-10-29.dump.age "$tmp/fetched.age"
check "it asks for the named object" log_has "args: copyto r2:lukitas-backups/lukitas-2026-10-29.dump.age $tmp/fetched.age"
check "the file arrives" eval 'cmp -s "$dump.age" "$tmp/fetched.age"'

[ "$failures" = 0 ] || die "$failures R2 check(s) failed"
say "R2: all checks passed"
