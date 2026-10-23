#!/usr/bin/env bash
# Builds the unsigned release APKs twice from clean, on the same commit, and compares them byte for
# byte (spec section 8, "Reproducible builds"): what F-Droid will do, and what lets anyone check that
# the APK the founder signed is the source's. Unsigned on purpose: a signature is not part of the
# comparison (F-Droid copies the developer's signature onto its own unsigned build).
#
#   apps/mobile/scripts/check-reproducible.sh [--tag mobile-vX.Y.Z] [--out <dir>]
#
# --tag names the version to build with (defaults to the dev version, as release.sh does without a
# tag); the files of both builds are kept in <out> (default: a temporary folder) for diffoscope or
# `unzip -l`. Takes two full builds, a few minutes. Exit codes: 0 identical, 1 they differ, 2 setup.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOBILE="$(cd "$HERE/.." && pwd)"
# shellcheck source=release-lib.sh
source "$HERE/release-lib.sh"

ABIS=(arm64-v8a armeabi-v7a)
tag=""
out=""
while [ $# -gt 0 ]; do
  case "$1" in
    --tag) tag="${2:-}"; shift 2 ;;
    --out) out="${2:-}"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done
command -v flutter >/dev/null 2>&1 || { echo "flutter is not on PATH (docs/mobile/setup.md)" >&2; exit 2; }
[ -n "$out" ] || out="$(mktemp -d)"
mkdir -p "$out"

if [ -n "$tag" ]; then
  version_name="$(release_version_name "$tag")"
  base_code="$(release_base_code "$tag")"
else
  version_name="$(release_dev_version_name "$(git -C "$MOBILE" rev-parse --short=7 HEAD)")"
  base_code="$(release_dev_base_code)"
fi
echo "Two clean unsigned builds of $(git -C "$MOBILE" rev-parse --short=7 HEAD) as $version_name (base code $base_code)"
if [ -n "$(git -C "$MOBILE" status --porcelain --untracked-files=no)" ]; then
  echo "Note: the working tree has uncommitted changes; both builds include them." >&2
fi

cd "$MOBILE"
for run in 1 2; do
  flutter clean >/dev/null 2>&1
  flutter pub get --enforce-lockfile >/dev/null 2>&1
  env -u SHELLOPTS LUKITAS_UNSIGNED_RELEASE=1 flutter build apk --release --split-per-abi \
    --target-platform android-arm,android-arm64 --build-name "$version_name" --build-number "$base_code" >/dev/null 2>&1 ||
    { echo "build $run failed: run the flutter build command in release.sh by hand to see why" >&2; exit 2; }
  mkdir -p "$out/build$run"
  for abi in "${ABIS[@]}"; do cp "build/app/outputs/flutter-apk/app-$abi-release.apk" "$out/build$run/$abi.apk"; done
done

status=0
for abi in "${ABIS[@]}"; do
  one="$(release_sha256 "$out/build1/$abi.apk")"
  two="$(release_sha256 "$out/build2/$abi.apk")"
  if [ "$one" = "$two" ]; then
    echo "identical  $abi  $one"
  else
    echo "DIFFERENT  $abi  $one  $two"
    status=1
    if command -v diffoscope >/dev/null 2>&1; then
      diffoscope --text "$out/diff-$abi.txt" "$out/build1/$abi.apk" "$out/build2/$abi.apk" >/dev/null 2>&1 || true
      echo "  diffoscope report: $out/diff-$abi.txt"
    else
      # No diffoscope: which files inside differ.
      mkdir -p "$out/unzip1-$abi" "$out/unzip2-$abi"
      (cd "$out/unzip1-$abi" && unzip -qo "$out/build1/$abi.apk")
      (cd "$out/unzip2-$abi" && unzip -qo "$out/build2/$abi.apk")
      diff -rq "$out/unzip1-$abi" "$out/unzip2-$abi" | sed "s|$out/||g" | head -40 | sed 's/^/  /' || true
    fi
  fi
done
echo "Kept in $out"
exit "$status"
