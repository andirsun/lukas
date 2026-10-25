#!/usr/bin/env bash
# Fails when any build of the Android app takes a proprietary Google (or Huawei) dependency: Play
# Services, Firebase, ML Kit, Play Core, ARCore, ads, billing, Crashlytics and the like (spec
# section 8; F-Droid takes no proprietary dependency in any build).
#
# It checks, in this order:
#   1. the Gradle build files under android/, for the Google Services, Firebase (Crashlytics,
#      Performance…) and Huawei AGConnect plugins, which sit on no runtime classpath;
#   2. what every shipped variant resolves, with Gradle
#        ./gradlew :app:dependencies --configuration {debug,profile,release}RuntimeClasspath
#      and the Dart packages, with `flutter pub deps --style=compact`;
# and exits 1, printing the offending names, when any of them matches BANNED below (a list modelled
# on F-Droid's scanner). AndroidX (androidx.*), Kotlin and Guava's listenablefuture are free and
# allowed.
#
# Usage, from anywhere:
#   apps/mobile/scripts/check-no-google.sh
#   apps/mobile/scripts/check-no-google.sh --gradle-deps <file> --pub-deps <file> [--android-dir <dir>]
# The second form checks recorded listings instead of resolving them (the tests use it), and the
# build files under <dir> (default: the app's android/). scripts/test-no-google-probes.sh runs the
# first form on a copy of the app with banned dependencies added.
# Exit codes: 0 clean, 1 banned dependency found, 2 the listings could not be produced or read.
set -euo pipefail

BANNED='com\.google\.android\.gms|com\.google\.firebase|com\.google\.android\.play|com\.google\.mlkit|com\.google\.android\.ump|com\.google\.android\.libraries|com\.google\.android\.datatransport|com\.google\.android\.recaptcha|com\.google\.ar[.:]|com\.android\.billingclient|com\.google\.android\.ads|com\.crashlytics|io\.fabric[.:]|com\.huawei\.hms|play-services|firebase'
# Plugin ids in build files: com.google.gms.google-services, com.google.firebase.crashlytics,
# com.huawei.agconnect, on top of everything above.
BANNED_IN_BUILD_FILES="${BANNED}|com\\.google\\.gms|com\\.huawei\\.agconnect"
CONFIGURATIONS=(debugRuntimeClasspath profileRuntimeClasspath releaseRuntimeClasspath)

MOBILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
gradle_deps=""
pub_deps=""
android_dir="$MOBILE/android"
while [ $# -gt 0 ]; do
  case "$1" in
    --gradle-deps) gradle_deps="${2:-}"; shift 2 ;;
    --pub-deps) pub_deps="${2:-}"; shift 2 ;;
    --android-dir) android_dir="${2:-}"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

fail_to_produce() {
  echo "$1" >&2
  exit 2
}

# 1. Plugins and anything else banned named in the build files.
if [ ! -d "$android_dir" ]; then fail_to_produce "No android directory at $android_dir"; fi
build_hits="$(
  find "$android_dir" \( -name build -o -name .gradle -o -name .kotlin \) -prune -o -type f \
    \( -name '*.gradle' -o -name '*.gradle.kts' -o -name '*.toml' \) -print0 |
    xargs -0 grep -nHiE "$BANNED_IN_BUILD_FILES" 2>/dev/null || true
)"
if [ -n "$build_hits" ]; then
  echo "Proprietary Google plugins or dependencies in the Gradle build files (F-Droid takes none):"
  # shellcheck disable=SC2001 # indent each line
  echo "$build_hits" | sed 's/^/  /'
  exit 1
fi

# 2. What the variants and the Dart packages resolve.
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

if [ -z "$gradle_deps" ] || [ -z "$pub_deps" ]; then
  cd "$MOBILE"
  flutter pub get --enforce-lockfile >/dev/null || fail_to_produce "flutter pub get failed"
  if [ -z "$pub_deps" ]; then
    pub_deps="$WORK/pub.txt"
    flutter pub deps --style=compact >"$pub_deps" || fail_to_produce "flutter pub deps failed"
  fi
  if [ -z "$gradle_deps" ]; then
    # The Gradle wrapper script and local.properties are not committed; Flutter writes them.
    if [ ! -x android/gradlew ] || [ ! -f android/local.properties ]; then
      flutter build apk --config-only >/dev/null || fail_to_produce "flutter build --config-only failed"
    fi
    # Gradle runs on the JDK Flutter is configured with (`flutter config --jdk-dir`), as
    # `flutter build` does; otherwise on JAVA_HOME.
    jdk_dir="$(flutter config --list 2>/dev/null | sed -n 's/^ *jdk-dir: //p')"
    if [ -n "$jdk_dir" ]; then export JAVA_HOME="$jdk_dir"; fi
    gradle_deps="$WORK/gradle.txt"
    for configuration in "${CONFIGURATIONS[@]}"; do
      (cd android && ./gradlew --quiet :app:dependencies --configuration "$configuration") \
        >>"$gradle_deps" || fail_to_produce "Gradle could not resolve $configuration"
    done
  fi
fi

for listing in "$gradle_deps" "$pub_deps"; do
  if [ ! -r "$listing" ]; then fail_to_produce "Cannot read the dependency listing $listing"; fi
done
# An empty or unexpected listing must not pass as clean.
for configuration in "${CONFIGURATIONS[@]}"; do
  if ! grep -q "^${configuration} " "$gradle_deps"; then
    fail_to_produce "The Gradle listing has no $configuration section: $gradle_deps"
  fi
done
if ! grep -q 'io\.flutter:' "$gradle_deps"; then
  fail_to_produce "The Gradle listing has no io.flutter dependency; it is not the app's classpath: $gradle_deps"
fi
if ! grep -q '^dependencies:' "$pub_deps"; then
  fail_to_produce "The pub listing has no dependencies section: $pub_deps"
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
echo "No Google dependency: ${gradle_count} Gradle artifacts (${CONFIGURATIONS[*]}) and ${pub_count} pub packages checked."
