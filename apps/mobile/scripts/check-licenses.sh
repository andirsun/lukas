#!/usr/bin/env bash
# Checks that About can list a licence for every Dart package the app depends on.
#
# Flutter collects the LICENSE file of every package into assets/flutter_assets/NOTICES.Z when it
# builds (unit and integration tests never see them), and About's licence page is made from that
# file. This reads it from the release APK, and fails when a package listed under `dependencies:`
# in pubspec.yaml has no entry. (The app's own extras, the voice models, the speech engine with
# what its native library carries (OpenBLAS, CLAPACK and libf2c), JNA with libffi, the Android
# libraries and the sounds, are added in code: lib/settings/licenses.dart, and a widget test
# checks them.) It then checks that the Android libraries About lists
# (assets/licenses/android-libraries.json) are exactly the release classpath's, each with the
# licence its POM declares: scripts/gen-android-licenses.dart --check, which fails when the file
# is stale. That part needs Gradle and the POMs it cached while building.
#
# Usage, from anywhere (after `flutter build apk --release`):
#   apps/mobile/scripts/check-licenses.sh [--apk <path>]
#   apps/mobile/scripts/check-licenses.sh --notices <file>   the unpacked NOTICES text (the tests use it)
#   ... --skip-android                                        leave out the Android libraries part
# Exit codes: 0 all fine, 1 a package has no licence or the Android list is stale, 2 no APK,
# NOTICES, pubspec or POMs.
set -euo pipefail

MOBILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
apk="$MOBILE/build/app/outputs/flutter-apk/app-release.apk"
notices=""
pubspec="$MOBILE/pubspec.yaml"
android=1
while [ $# -gt 0 ]; do
  case "$1" in
    --apk) apk="${2:-}"; shift 2 ;;
    --notices) notices="${2:-}"; shift 2 ;;
    --pubspec) pubspec="${2:-}"; shift 2 ;;
    --skip-android) android=0; shift ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [ -z "$notices" ]; then
  if [ ! -f "$apk" ]; then
    echo "No APK at $apk: run 'flutter build apk --release' first." >&2
    exit 2
  fi
  notices="$(mktemp)"
  trap 'rm -f "$notices"' EXIT
  unzip -p "$apk" assets/flutter_assets/NOTICES.Z 2>/dev/null | gunzip >"$notices" 2>/dev/null ||
    { echo "No NOTICES.Z in $apk." >&2; exit 2; }
fi
if [ ! -s "$notices" ] || [ ! -r "$pubspec" ]; then
  echo "Cannot read the notices ($notices) or pubspec ($pubspec)." >&2
  exit 2
fi

# The packages under `dependencies:` (not the SDK ones): "  name: version".
packages="$(awk '
  /^dependencies:/ { in_block = 1; next }
  /^[^ #]/ { in_block = 0 }
  in_block && /^  [a-z_0-9]+: *[^ #]/ { sub(/:.*/, "", $1); print $1 }
' "$pubspec")"
if [ -z "$packages" ]; then
  echo "No dependencies found in $pubspec." >&2
  exit 2
fi

failed=0
count=0
while IFS= read -r package; do
  count=$((count + 1))
  # A licence entry starts with the names of the packages it covers, one per line.
  if ! grep -qxF "$package" "$notices"; then
    echo "No licence for $package in the build's NOTICES."
    failed=1
  fi
done <<<"$packages"

if [ "$failed" -ne 0 ]; then exit 1; fi
echo "A licence for each of the $count direct dependencies."

if [ "$android" -eq 1 ]; then
  cd "$MOBILE"
  # Gradle runs on the JDK Flutter is configured with, as `flutter build` does.
  jdk_dir="$(flutter config --list 2>/dev/null | sed -n 's/^ *jdk-dir: //p')"
  if [ -n "$jdk_dir" ]; then export JAVA_HOME="$jdk_dir"; fi
  dart run scripts/gen-android-licenses.dart --check
fi
