#!/usr/bin/env bash
# Probes scripts/check-no-google.sh end to end: on a temporary copy of the app, it adds one banned
# dependency or plugin at a time and expects the check to fail and name it, with Gradle resolving
# for real. The unit tests (test/tooling/check_no_google_test.dart) cover the matching on recorded
# listings; this covers the resolution: every shipped variant, not only release.
#
# Usage, from anywhere: apps/mobile/scripts/test-no-google-probes.sh
# Exit codes: 0 every probe behaved, 1 a probe did not.
set -euo pipefail

MOBILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# The copy keeps the Gradle wrapper and local.properties when they exist (they are not committed;
# check-no-google.sh writes them otherwise) and leaves build outputs behind.
COPY="$WORK/mobile"
rsync -a --exclude /build --exclude /.dart_tool --exclude /android/.gradle \
  --exclude /android/.kotlin --exclude /android/app/build "$MOBILE/" "$COPY/"
APP_GRADLE="$COPY/android/app/build.gradle.kts"
SETTINGS_GRADLE="$COPY/android/settings.gradle.kts"
cp "$APP_GRADLE" "$WORK/app.gradle.kts"
cp "$SETTINGS_GRADLE" "$WORK/settings.gradle.kts"

failures=0

# probe <name> <expected exit> <text the output must contain>
probe() {
  local name="$1" expected="$2" needle="$3" status=0
  "$COPY/scripts/check-no-google.sh" >"$WORK/out.txt" 2>&1 || status=$?
  if [ "$status" -eq "$expected" ] && grep -qF -- "$needle" "$WORK/out.txt"; then
    echo "ok    $name (exit $status)"
  else
    echo "FAIL  $name: expected exit $expected with '$needle', got exit $status:"
    sed 's/^/        /' "$WORK/out.txt"
    failures=$((failures + 1))
  fi
  cp "$WORK/app.gradle.kts" "$APP_GRADLE"
  cp "$WORK/settings.gradle.kts" "$SETTINGS_GRADLE"
}

probe "the app as it is passes" 0 "No Google dependency"

# Through a dependency whose own name is not banned, debug builds only: only resolving the debug
# classpath can see it (android-maps-utils pulls in play-services-maps).
printf '\ndependencies {\n    debugImplementation("com.google.maps.android:android-maps-utils:3.8.2")\n}\n' \
  >>"$APP_GRADLE"
probe "a debug-only transitive Play Services dependency fails" 1 "com.google.android.gms:play-services-maps"

# Coordinates assembled at build time, so only resolution can see them, not the build-file scan.
printf '\ndependencies {\n    implementation(listOf("com.google.ar", "core", "1.44.0").joinToString(":"))\n}\n' \
  >>"$APP_GRADLE"
probe "ARCore, resolved, fails" 1 "com.google.ar:core"

printf '\ndependencies {\n    implementation("com.google.ar:core:1.44.0")\n}\n' >>"$APP_GRADLE"
probe "ARCore, named in a build file, fails" 1 "com.google.ar:core"

perl -0pi -e 's/(\nplugins \{\n)/$1    id("com.google.gms.google-services") version "4.4.2" apply false\n/' \
  "$SETTINGS_GRADLE"
probe "the Google Services plugin fails" 1 "com.google.gms.google-services"

if [ "$failures" -ne 0 ]; then
  echo "$failures probe(s) failed."
  exit 1
fi
echo "Every no-Google probe behaved."
