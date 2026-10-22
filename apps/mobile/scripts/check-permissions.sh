#!/usr/bin/env bash
# Checks the permissions the release APK asks for, with `aapt2 dump permissions`.
#
# The release build is what F-Droid ships, and Android merges the INTERNET permission into debug
# and profile builds only (src/debug, src/profile), so a release APK without it cannot reach its
# server. This fails when INTERNET is missing, and when the APK asks for any permission not in
# ALLOWED below: a new permission is a decision, made here on purpose.
#
# Usage, from anywhere (after `flutter build apk --release`):
#   apps/mobile/scripts/check-permissions.sh [--apk <path>]
#   apps/mobile/scripts/check-permissions.sh --dump <file>   a recorded dump (the tests use it)
# Exit codes: 0 as expected, 1 missing or unexpected permission, 2 no APK, aapt2 or dump.
set -euo pipefail

PACKAGE="com.andersonlaverde.lukitas"
REQUIRED=("android.permission.INTERNET")
ALLOWED=(
  "android.permission.INTERNET"
  # androidx.core's own signature permission for receivers registered as not exported.
  "${PACKAGE}.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION"
)

MOBILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
apk="$MOBILE/build/app/outputs/flutter-apk/app-release.apk"
dump=""
while [ $# -gt 0 ]; do
  case "$1" in
    --apk) apk="${2:-}"; shift 2 ;;
    --dump) dump="${2:-}"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [ -z "$dump" ]; then
  if [ ! -f "$apk" ]; then
    echo "No APK at $apk: run 'flutter build apk --release' first." >&2
    exit 2
  fi
  sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
  if [ -z "$sdk" ] && [ -f "$MOBILE/android/local.properties" ]; then
    sdk="$(sed -n 's/^sdk\.dir=//p' "$MOBILE/android/local.properties")"
  fi
  aapt2="$(find "$sdk/build-tools" -mindepth 2 -maxdepth 2 -name aapt2 -type f 2>/dev/null |
    sort -V | tail -n 1 || true)"
  if [ -z "$aapt2" ]; then
    echo "aapt2 not found under the Android SDK ($sdk/build-tools)." >&2
    exit 2
  fi
  dump="$(mktemp)"
  trap 'rm -f "$dump"' EXIT
  "$aapt2" dump permissions "$apk" >"$dump" || { echo "aapt2 failed on $apk" >&2; exit 2; }
fi
if [ ! -r "$dump" ] || ! grep -q "^package: $PACKAGE\$" "$dump"; then
  echo "Not a permissions dump of $PACKAGE: $dump" >&2
  exit 2
fi

requested="$(sed -n "s/^uses-permission: name='\([^']*\)'.*/\1/p" "$dump" | sort -u)"
failed=0
for permission in "${REQUIRED[@]}"; do
  if ! grep -qxF "$permission" <<<"$requested"; then
    echo "Missing permission: $permission (add it to android/app/src/main/AndroidManifest.xml)"
    failed=1
  fi
done
while IFS= read -r permission; do
  [ -z "$permission" ] && continue
  if ! printf '%s\n' "${ALLOWED[@]}" | grep -qxF "$permission"; then
    echo "Unexpected permission: $permission (allow it in scripts/check-permissions.sh on purpose)"
    failed=1
  fi
done <<<"$requested"

if [ "$failed" -ne 0 ]; then exit 1; fi
echo "Release permissions as expected: $(tr '\n' ' ' <<<"$requested")"
