#!/usr/bin/env bash
# Runs the integration tests (integration_test/) on a running emulator, against the dev stack
# (`docker compose up -d` at the repo root), the way docs/mobile/setup.md describes and the
# `mobile-emulator` job in .github/workflows/ci.yml does.
#
#   apps/mobile/scripts/run-integration-tests.sh [-d <device>]      (default: emulator-5554)
#
# Three `flutter test` runs, each one build of the app (a build and install takes longer than most
# files' tests): integration_test/suites_test.dart, every file that needs the notification permission
# given (or the notification question covers the screen), and the two notice tests, which need it
# not given, then given. suites_test.dart starts each file from what a fresh install has, with an
# address of its own (below). The emulator reaches
# the host at 10.0.2.2. voice_engine_test.dart is not here: it needs the voice models served by a
# stand-in (setup.md) and skips itself without them.
#
# The API allows 5 code requests per 10 minutes from one address, and the emulator is one address for
# every file. So each run is a client of its own, as each browser is in the web's e2e suite
# (apps/web/e2e/helpers.ts): it is given a made-up address (--dart-define=LUKITAS_CLIENT_IP, and
# suites_test.dart a new one per file), which a debug build sends as x-forwarded-for and the dev
# stack counts. A release build never sends it, and
# the API's limits are as they are. Runs every file even when one fails, and exits 1 if any did.
set -uo pipefail

MOBILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
device="${ANDROID_SERIAL:-emulator-5554}"
while [ $# -gt 0 ]; do
  case "$1" in
    -d) device="${2:-}"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done
server="${LUKITAS_SERVER:-http://10.0.2.2:3000}"
mailpit="${MAILPIT_URL:-http://10.0.2.2:8025}"
package="com.andersonlaverde.lukitas"
notification="android.permission.POST_NOTIFICATIONS"

cd "$MOBILE"
case "$device" in
  emulator-*) ;;
  *) echo "run-integration-tests.sh: '$device' is not an emulator. These tests sign guests in and out, and change the app's settings: not on a real phone." >&2; exit 2 ;;
esac

failed=()
passed=()
apk="$MOBILE/build/app/outputs/flutter-apk/app-debug.apk"

# `flutter test` uninstalls the app when it ends, and a fresh install has not been given the
# notification permission, so the question Task 16 asks guests ("notices.ask") would cover the
# screen. Before each run the app is installed by hand in the state the file needs, and Flutter's
# own install, which replaces it, keeps the grants.
prepare() { # prepare granted|revoked
  if [ "$1" = granted ]; then
    adb -s "$device" install -r -t -g "$apk" >/dev/null && adb -s "$device" shell pm grant "$package" "$notification"
  else
    adb -s "$device" install -r -t "$apk" >/dev/null && adb -s "$device" shell pm revoke "$package" "$notification"
  fi || { echo "run-integration-tests.sh: could not install the app as $1" >&2; exit 2; }
}

run() { # run <granted|revoked> <label> <flutter test args...>
  local state="$1" label="$2"
  shift 2
  echo
  echo "=== $label"
  prepare "$state"
  # A new address per run (the web's `clientIp`: 198.18.0.0/15, a range for benchmarking).
  local client_ip="198.$((18 + RANDOM % 2)).$((RANDOM % 256)).$((1 + RANDOM % 254))"
  if flutter test "$@" -d "$device" --dart-define=LUKITAS_SERVER="$server" --dart-define=MAILPIT_URL="$mailpit" --dart-define=LUKITAS_CLIENT_IP="$client_ip" --dart-define=CI="${CI:-false}"; then
    passed+=("$label")
  else
    failed+=("$label")
  fi
}

# Any debug build to start from (the first install); each run builds its own over it.
[ -f "$apk" ] || flutter build apk --debug

run granted "suites" integration_test/suites_test.dart
# Not given -> asked once; given -> the notice goes out.
run revoked "notices: asked once" integration_test/notices_test.dart --plain-name "a guest who has not been asked"
run granted "notices: Hoy vence" integration_test/notices_test.dart --plain-name "Hoy vence"

echo
echo "Passed: ${#passed[@]}  Failed: ${#failed[@]}"
if [ ${#failed[@]} -gt 0 ]; then
  printf 'FAILED: %s\n' "${failed[@]}"
  exit 1
fi
