#!/usr/bin/env bash
# Tests backup.sh's retention (apply_retention in lib.sh) on fake dumps with old modification
# times, in a temporary folder: no Docker, no database, no .env. Run: ./test-retention.sh
#
# What it checks: no dump older than 14 days stays, daily or pre-update, encrypted copy or not (the
# app promises that backups holding a deleted account delete themselves within 14 days); the count
# limits still cap what is younger; files that are not dumps are left alone.
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
failures=0

# aged FILE DAYS: create FILE, last modified DAYS days ago (a fraction is fine).
aged() {
  : >"$1"
  perl -e '$t = time - $ARGV[0] * 86400; utime $t, $t, $ARGV[1] or die "utime $ARGV[1]: $!"' "$2" "$1"
}

# expect DIR NAMES...: the folder holds exactly NAMES (sorted), nothing else.
expect() {
  local dir="$1" want got
  shift
  want="$(printf '%s\n' "$@" | sort)"
  got="$(ls -1A "$dir" | sort)"
  if [ "$want" != "$got" ]; then
    printf 'FAIL %s\n  expected:\n%s\n  got:\n%s\n' "$dir" "$(printf '%s\n' "$want" | sed 's/^/    /')" \
      "$(printf '%s\n' "$got" | sed 's/^/    /')" >&2
    failures=$((failures + 1))
  else
    printf 'ok   %s\n' "${dir#"$tmp"/}"
  fi
}

# Daily dumps from today back 20 days, one a day: the ones from 14 days ago and older go (KEEP is
# 30 here, so the age is what removes them).
daily="$tmp/daily"
mkdir "$daily"
kept=()
for i in $(seq 0 20); do
  name="lukitas-2026-10-$(printf '%02d' $((22 - i))).dump"
  aged "$daily/$name" "$i.01"
  [ "$i" -ge 14 ] || kept+=("$name")
done
apply_retention "$daily" "" 30 10 >/dev/null
expect "$daily" "${kept[@]}"

# Pre-update dumps have no daily run of their own to age them: a 30-day-old one goes even though
# there are fewer than 10.
pre="$tmp/preupdate"
mkdir "$pre"
aged "$pre/lukitas-2026-10-21-preupdate-1200.dump" 1
aged "$pre/lukitas-2026-10-09-preupdate-0900.dump" 13
aged "$pre/lukitas-2026-10-08-preupdate-0900.dump" 14
aged "$pre/lukitas-2026-09-22-preupdate-1830.dump" 30
apply_retention "$pre" "" 14 10 >/dev/null
expect "$pre" lukitas-2026-10-21-preupdate-1200.dump lukitas-2026-10-09-preupdate-0900.dump

# The count limits still apply to young dumps: KEEP daily, 10 pre-update (newest by name).
counts="$tmp/counts"
mkdir "$counts"
young=()
for d in 01 02 03 04 05 06 07 08 09 10 11 12; do
  aged "$counts/lukitas-2026-10-$d.dump" 0.1
  aged "$counts/lukitas-2026-10-$d-preupdate-1000.dump" 0.1
done
apply_retention "$counts" "" 5 10 >/dev/null
for d in 08 09 10 11 12; do young+=("lukitas-2026-10-$d.dump"); done
for d in 03 04 05 06 07 08 09 10 11 12; do young+=("lukitas-2026-10-$d-preupdate-1000.dump"); done
expect "$counts" "${young[@]}"

# The encrypted copies follow the same rules; other files in the folder are never touched.
copies="$tmp/copies"
mkdir "$copies"
aged "$copies/lukitas-2026-10-21.dump.age" 1
aged "$copies/lukitas-2026-10-01.dump.age" 21
aged "$copies/lukitas-2026-09-01-preupdate-0800.dump.age" 51
aged "$copies/lukitas-2026-09-01.dump" 51
aged "$copies/notes.txt" 300
aged "$copies/.lukitas-2026-09-01.dump.age.partial" 51
apply_retention "$copies" '\.age' 14 10 >/dev/null
expect "$copies" lukitas-2026-10-21.dump.age lukitas-2026-09-01.dump notes.txt \
  .lukitas-2026-09-01.dump.age.partial

# Backups failing for weeks: every dump is past 14 days. The newest one stays, so a long run of
# failed backups never leaves none at all; the rest still go. Same for the encrypted copies.
stale="$tmp/stale"
mkdir "$stale"
aged "$stale/lukitas-2026-09-20.dump" 32
aged "$stale/lukitas-2026-09-25-preupdate-0800.dump" 27
aged "$stale/lukitas-2026-09-28.dump" 24
aged "$stale/lukitas-2026-09-28.dump.age" 24
aged "$stale/lukitas-2026-09-20.dump.age" 32
apply_retention "$stale" "" 14 10 >/dev/null
apply_retention "$stale" '\.age' 14 10 >/dev/null
expect "$stale" lukitas-2026-09-28.dump lukitas-2026-09-28.dump.age

# A folder that does not exist (no copies set up yet) is fine.
apply_retention "$tmp/missing" "" 14 10 >/dev/null
expect "$tmp" copies counts daily preupdate stale

[ "$failures" = 0 ] || die "$failures retention check(s) failed"
say "Retention: all checks passed"
