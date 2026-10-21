#!/usr/bin/env bash
# Checks the install from this machine, without the tunnel: the landing, the app shell, the API
# health, that OAuth and the API schema are blocked at Caddy, and that an address outside the
# allowlist is refused without sending an email.
# Usage: ./smoke.sh [BASE_URL]   (default http://127.0.0.1:$WEB_PORT)
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

base="${1:-http://127.0.0.1:$(cfg WEB_PORT 8088)}"
host="$(cfg PUBLIC_HOSTNAME app-lukas.andersonlaverde.com)"
failed=0

check() { # NAME EXPECTED ACTUAL
  if [ "$2" = "$3" ]; then
    printf 'ok    %s\n' "$1"
  else
    printf 'FAIL  %s (expected %s, got %s)\n' "$1" "$2" "$3"
    failed=1
  fi
}
status() { curl -s -o /dev/null -w '%{http_code}' "$@"; }

check "GET /                 landing" 200 "$(status "$base/")"
check "GET /api/health       API" 200 "$(status "$base/api/health")"
check "GET /app              app shell" 200 "$(status "$base/app")"
check "GET /sign-in          app shell" 200 "$(status "$base/sign-in")"
check "GET /nope.png         missing file" 404 "$(status "$base/nope.png")"
check "GET /api/v1/me        needs a session" 401 "$(status "$base/api/v1/me")"

# Kept off the internet by Caddy (not in the API): OAuth registration and flows, and the schema.
check "GET /api/openapi.json  not public" 404 "$(status "$base/api/openapi.json")"
check "POST oauth2/register   not public" 404 "$(status -X POST "$base/api/auth/oauth2/register" -H 'Content-Type: application/json' -d '{}')"
check "GET oauth2/authorize   not public" 404 "$(status "$base/api/auth/oauth2/authorize")"
check "GET frame-ancestors    header" "frame-ancestors 'none'" "$(curl -s -I "$base/" | tr -d '\r' | sed -n "s/^[Cc]ontent-[Ss]ecurity-[Pp]olicy: //p")"

# A made-up address is not on the list. The API answers 403 sign_in_not_allowed and sends nothing.
body="$(curl -s -w '\n%{http_code}' -X POST "$base/api/auth/email-otp/send-verification-otp" \
  -H "Origin: https://$host" -H 'Content-Type: application/json' \
  -d '{"email":"not-on-the-list@example.invalid","type":"sign-in"}')"
check "POST send-code        outside the allowlist" 403 "${body##*$'\n'}"
case "$body" in
  *sign_in_not_allowed*) check "                     error code" sign_in_not_allowed sign_in_not_allowed ;;
  *) check "                     error code" sign_in_not_allowed "(none): $body" ;;
esac

exit "$failed"
