#!/usr/bin/env bash
# Runs the integration tests (integration_test/) on a running emulator, against the dev stack
# (`docker compose up -d` at the repo root), the way docs/mobile/setup.md describes and the
# `mobile-emulator` job in .github/workflows/ci.yml does.
#
#   apps/mobile/scripts/run-integration-tests.sh [-d <device>]      (default: emulator-5554)
#
# Each file is its own `flutter test` run, because some need the phone in a state of their own: the
# two notice tests need the notification permission not given, then given, and the others need it
# given, or the notification question covers the screen. The emulator reaches
# the host at 10.0.2.2. voice_engine_test.dart is not here: it needs the voice models served by a
# stand-in (setup.md) and skips itself without them.
#
# The API allows 5 code requests per 10 minutes from one address, and a run asks for a few: run this
# more than twice in 10 minutes and the sign-in tests get too_many_requests. Runs every file even
# when one fails, and exits 1 if any did.
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
  if flutter test "$@" -d "$device" --dart-define=LUKITAS_SERVER="$server" --dart-define=MAILPIT_URL="$mailpit"; then
    passed+=("$label")
  else
    failed+=("$label")
  fi
}

# Any debug build to start from (the first install); each run builds its own over it.
[ -f "$apk" ] || flutter build apk --debug

run granted "feedback" integration_test/feedback_test.dart
run granted "settings" integration_test/settings_test.dart
run granted "add" integration_test/add_test.dart
run granted "budgets" integration_test/budgets_test.dart
run granted "categories" integration_test/categories_test.dart
run granted "recurring" integration_test/recurring_test.dart
run granted "import" integration_test/import_test.dart
run granted "capture" integration_test/capture_test.dart
run granted "entry" integration_test/entry_test.dart
run granted "widget" integration_test/widget_test.dart
# Not given -> asked once; given -> the notice goes out.
run revoked "notices: asked once" integration_test/notices_test.dart --plain-name "a guest who has not been asked"
run granted "notices: Hoy vence" integration_test/notices_test.dart --plain-name "Hoy vence"

echo
echo "Passed: ${#passed[@]}  Failed: ${#failed[@]}"
if [ ${#failed[@]} -gt 0 ]; then
  printf 'FAILED: %s\n' "${failed[@]}"
  exit 1
fi
