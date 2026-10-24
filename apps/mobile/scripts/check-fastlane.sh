#!/usr/bin/env bash
# Checks the F-Droid metadata in fastlane/metadata/android against F-Droid's limits and against
# itself: both locales (es-ES, en-US) have a title (30 characters at most), a short description (80),
# a full description (4000), changelogs of 500 bytes at most named for a version code, and PNG
# screenshots that are small (the repo is not an image store); the changelogs and the number of
# screenshots are the same in both. Run from anywhere:
#
#   apps/mobile/scripts/check-fastlane.sh
# Exit codes: 0 fine, 1 something is off.
set -uo pipefail

MOBILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
META="$MOBILE/fastlane/metadata/android"
LOCALES=(es-ES en-US)
MAX_SCREENSHOT_BYTES=250000
failed=0
fail() { echo "fastlane: $1"; failed=1; }

chars() { LC_ALL=en_US.UTF-8 wc -m <"$1" | tr -d ' '; }

# limit <file> <max characters>: the text, without its final newline, fits.
limit() {
  [ -s "$1" ] || { fail "${1#"$MOBILE"/} is missing or empty"; return; }
  local n
  n="$(chars "$1")"
  n=$((n - 1))
  [ "$n" -le "$2" ] || fail "${1#"$MOBILE"/} is $n characters, over $2"
}

for locale in "${LOCALES[@]}"; do
  dir="$META/$locale"
  [ -d "$dir" ] || { fail "no folder for $locale"; continue; }
  limit "$dir/title.txt" 30
  limit "$dir/short_description.txt" 80
  limit "$dir/full_description.txt" 4000

  codes="$(cd "$dir/changelogs" 2>/dev/null && ls | sort | tr '\n' ' ')"
  [ -n "$codes" ] || fail "$locale has no changelogs"
  for file in "$dir"/changelogs/*; do
    [ -e "$file" ] || continue
    name="$(basename "$file")"
    [[ "$name" =~ ^[1-9][0-9]*\.txt$ ]] || fail "changelogs/$name is not <versionCode>.txt"
    [ "$(wc -c <"$file")" -le 500 ] || fail "$locale/changelogs/$name is over 500 bytes"
  done
  if [ "$locale" = "${LOCALES[0]}" ]; then reference_codes="$codes"; fi
  [ "$codes" = "$reference_codes" ] || fail "$locale changelogs ($codes) differ from ${LOCALES[0]}'s ($reference_codes)"

  count=0
  for shot in "$dir"/images/phoneScreenshots/*; do
    [ -e "$shot" ] || continue
    count=$((count + 1))
    # The PNG signature, then the IHDR width and height.
    [ "$(head -c 8 "$shot" | od -An -tx1 | tr -d ' \n')" = "89504e470d0a1a0a" ] || { fail "$shot is not a PNG"; continue; }
    size=$(($(wc -c <"$shot")))
    [ "$size" -le "$MAX_SCREENSHOT_BYTES" ] || fail "${shot#"$MOBILE"/} is $size bytes, over $MAX_SCREENSHOT_BYTES"
    read -r width height < <(od -An -tu1 -j16 -N8 "$shot" | awk '{ print $1*16777216+$2*65536+$3*256+$4, $5*16777216+$6*65536+$7*256+$8 }')
    if [ "$width" -gt 1080 ] || [ "$height" -gt 2400 ] || [ "$width" -lt 320 ]; then
      fail "${shot#"$MOBILE"/} is ${width}x${height}: phone screenshots between 320 and 1080 pixels wide"
    fi
  done
  [ "$count" -ge 2 ] || fail "$locale needs at least 2 phone screenshots (has $count)"
  if [ "$locale" = "${LOCALES[0]}" ]; then reference_count="$count"; fi
  [ "$count" -eq "$reference_count" ] || fail "$locale has $count screenshots, ${LOCALES[0]} has $reference_count"
done

[ "$failed" -eq 0 ] && echo "F-Droid metadata fine: ${LOCALES[*]}"
exit "$failed"
