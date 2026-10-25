#!/bin/sh
# Starts the web container: fills /.well-known/assetlinks.json (Android App Links and passkeys) from
# ANDROID_CERT_SHA256, then runs Caddy. POSIX sh: this is Alpine's busybox.
#
# ANDROID_CERT_SHA256 is the SHA-256 fingerprint of each certificate the Android app is signed with,
# comma-separated, as release.sh prints it (AA:BB:...:FF, 32 pairs). With none set the file is `[]`:
# a valid answer that links nothing, never a 404. A value that is not a fingerprint is skipped with
# a warning, so one typo cannot take the web app down or put junk in the file.
set -eu

template=/etc/caddy/assetlinks.json.template
dir=/srv/.well-known
mkdir -p "$dir"

fingerprints=""
set -f # no globbing while the list is split
old_ifs="$IFS"
IFS=','
for raw in ${ANDROID_CERT_SHA256:-}; do
  value="$(printf '%s' "$raw" | tr -d ' \t\r\n"' | tr 'a-f' 'A-F')"
  [ -n "$value" ] || continue
  if printf '%s' "$value" | grep -Eq '^([0-9A-F]{2}:){31}[0-9A-F]{2}$'; then
    fingerprints="${fingerprints:+$fingerprints,}\"$value\""
  else
    echo "web: ANDROID_CERT_SHA256 has a value that is not a SHA-256 fingerprint (AA:BB:...); skipped" >&2
  fi
done
IFS="$old_ifs"
set +f

if [ -n "$fingerprints" ]; then
  # The fingerprints hold only 0-9, A-F, ":" and ",", so they are safe in the sed replacement.
  sed "s|__SHA256_CERT_FINGERPRINTS__|$fingerprints|" "$template" >"$dir/assetlinks.json"
else
  printf '[]\n' >"$dir/assetlinks.json"
fi

exec "$@"
