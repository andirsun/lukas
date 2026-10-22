#!/usr/bin/env bash
# Fails when the Android app resolves a Google Play Services, Firebase, ML Kit or Play Core
# dependency (spec section 8: F-Droid takes no proprietary dependency in any build).
#
# It lists what the release build resolves, with Gradle
#   ./gradlew :app:dependencies --configuration releaseRuntimeClasspath
# and with pub
#   flutter pub deps --style=compact
# then exits 1, printing the offending names, when any of them matches com.google.android.gms,
# com.google.firebase, play-services, com.google.mlkit, com.google.android.play or firebase.
# AndroidX (androidx.*) and Kotlin are free and allowed.
#
# Usage, from anywhere:
#   apps/mobile/scripts/check-no-google.sh
#   apps/mobile/scripts/check-no-google.sh --gradle-deps <file> --pub-deps <file>
# The second form checks recorded listings instead of resolving them (the tests use it).
# Exit codes: 0 clean, 1 banned dependency found, 2 the listings could not be produced or read.
set -euo pipefail

BANNED='com\.google\.android\.gms|com\.google\.firebase|play-services|com\.google\.mlkit|com\.google\.android\.play|firebase'

MOBILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
gradle_deps=""
pub_deps=""
while [ $# -gt 0 ]; do
  case "$1" in
    --gradle-deps) gradle_deps="${2:-}"; shift 2 ;;
    --pub-deps) pub_deps="${2:-}"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

if [ -z "$gradle_deps" ] || [ -z "$pub_deps" ]; then
  cd "$MOBILE"
  flutter pub get >/dev/null
  if [ -z "$pub_deps" ]; then
    pub_deps="$WORK/pub.txt"
    flutter pub deps --style=compact >"$pub_deps"
  fi
  if [ -z "$gradle_deps" ]; then
    # The Gradle wrapper script and local.properties are not committed; Flutter writes them.
    if [ ! -x android/gradlew ] || [ ! -f android/local.properties ]; then
      flutter build apk --config-only >/dev/null
    fi
    # Gradle runs on the JDK Flutter is configured with (`flutter config --jdk-dir`), as
    # `flutter build` does; otherwise on JAVA_HOME.
    jdk_dir="$(flutter config --list 2>/dev/null | sed -n 's/^ *jdk-dir: //p')"
    if [ -n "$jdk_dir" ]; then export JAVA_HOME="$jdk_dir"; fi
    gradle_deps="$WORK/gradle.txt"
    (cd android && ./gradlew --quiet :app:dependencies --configuration releaseRuntimeClasspath) \
      >"$gradle_deps"
  fi
fi

for listing in "$gradle_deps" "$pub_deps"; do
  if [ ! -r "$listing" ]; then
    echo "Cannot read the dependency listing $listing" >&2
    exit 2
  fi
done
# An empty or unexpected listing must not pass as clean.
if ! grep -q 'io\.flutter:' "$gradle_deps"; then
  echo "The Gradle listing has no io.flutter dependency; it is not the app's release classpath:" >&2
  cat "$gradle_deps" >&2
  exit 2
fi
if ! grep -q '^dependencies:' "$pub_deps"; then
  echo "The pub listing has no dependencies section:" >&2
  cat "$pub_deps" >&2
  exit 2
fi

gradle_count="$(grep -oE -- '--- [A-Za-z0-9_.-]+:[A-Za-z0-9_.-]+' "$gradle_deps" | sort -u | wc -l | tr -d ' ')"
pub_count="$(grep -cE '^- ' "$pub_deps" || true)"

offending="$(
  cat "$gradle_deps" "$pub_deps" |
    grep -oiE "[A-Za-z0-9_.:-]*(${BANNED})[A-Za-z0-9_.:-]*" |
    sort -u || true
)"

if [ -n "$offending" ]; then
  echo "Proprietary Google dependencies found (F-Droid takes none):"
  # shellcheck disable=SC2001 # indent each name
  echo "$offending" | sed 's/^/  /'
  exit 1
fi
echo "No Google dependency: ${gradle_count} Gradle artifacts (releaseRuntimeClasspath) and ${pub_count} pub packages checked."
