#!/usr/bin/env bash
# Backs up the database to $BACKUP_DIR/lukitas-YYYY-MM-DD.dump (default ~/Backups/lukitas). No dump
# is kept longer than 14 days, daily or pre-update (the app promises that backups holding a deleted
# account delete themselves within 14 days); under that, the newest 14 daily dumps.
#
#   ./backup.sh               the daily backup (what launchd runs)
#   ./backup.sh --pre-update  a backup taken before an update: lukitas-YYYY-MM-DD-preupdate-HHMM.dump.
#                             Its own name, so it never replaces the daily dump; not counted by the
#                             14-daily rule (the newest 10 of them are kept, none past 14 days).
#
# Every run applies the 14-day limit, even one that fails (a failure notifies you every time).
#
# The dump is taken as the database owner, which bypasses row-level security (every table here is
# FORCE ROW LEVEL SECURITY, so a dump by the API's own role would come out empty). A backup is only
# kept after it passes: pg_restore can list it, and restoring it into a scratch database gives rows
# in every main table that has rows in the live one. Otherwise the new file is deleted, the old
# ones younger than 14 days stay, and the script exits with an error (and a macOS notification when
# run by launchd).
#
# Optional encrypted second copy: set BACKUP_COPY_DIR (a folder, e.g. in iCloud Drive) and
# BACKUP_AGE_RECIPIENT (an age public key, "age1...") in .env. After a good backup, the dump is
# encrypted with `age` (brew install age) into BACKUP_COPY_DIR/<name>.age, and the same retention
# applies there (tested by test-retention.sh). Without `age` the copy is skipped with a warning.
# The dump itself is checked before it is encrypted. See README, "Backup and restore".
#
# Needs the stack running (Docker Desktop up). Settings: BACKUP_DIR, KEEP (default 14),
# BACKUP_COPY_DIR, BACKUP_AGE_RECIPIENT, ENV_FILE.
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

umask 077
need_env_file

pre_update=0
for arg in "$@"; do
  case "$arg" in
    --pre-update) pre_update=1 ;;
    -h | --help)
      sed -n '2,27p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) die "unknown option: $arg" ;;
  esac
done

# A leading ~ in a value from .env is the home folder.
expand_home() { case "$1" in "~"*) printf '%s' "$HOME${1#\~}" ;; *) printf '%s' "$1" ;; esac; }

backup_dir="$(expand_home "$(cfg BACKUP_DIR "$HOME/Backups/lukitas")")"
copy_dir="$(expand_home "$(cfg BACKUP_COPY_DIR)")"
age_recipient="$(cfg BACKUP_AGE_RECIPIENT)"
keep="${KEEP:-14}"
keep_preupdate=10
stamp="$(date +%Y-%m-%d)"
if [ "$pre_update" = 1 ]; then
  name="lukitas-$stamp-preupdate-$(date +%H%M).dump"
else
  name="lukitas-$stamp.dump"
fi
final="$backup_dir/$name"
partial="$backup_dir/.$name.partial"
scratch="lukitas_verify"

case "$keep" in '' | *[!0-9]*) die "KEEP must be a number" ;; esac
[ "$keep" -ge 1 ] || die "KEEP must be at least 1"

# retain: the retention of the dumps and of the encrypted copies (lib.sh, apply_retention).
retain() {
  apply_retention "$backup_dir" "" "$keep" "$keep_preupdate"
  [ -z "$copy_dir" ] || apply_retention "$copy_dir" '\.age' "$keep" "$keep_preupdate"
}

fail() {
  printf 'BACKUP FAILED: %s\n' "$*" >&2
  # Old dumps still age out: the 14-day promise does not wait for a good backup.
  retain || true
  # When launchd runs this nobody is watching the log; tell the person.
  osascript -e "display notification \"$*\" with title \"Lukitas backup failed\"" >/dev/null 2>&1 || true
  exit 1
}

cleanup() {
  rm -f "$partial"
  if db_running; then
    psql_db postgres -qc "drop database if exists $scratch with (force)" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

command -v docker >/dev/null 2>&1 || fail "docker is not installed or not on PATH"
docker info >/dev/null 2>&1 || fail "Docker is not running"
db_running || fail "the database container is not running (is the stack up?)"
[ "$backup_dir" != "$HOME" ] && [ "$backup_dir" != "/" ] || fail "BACKUP_DIR must be a folder of its own, not $backup_dir"
if [ ! -d "$backup_dir" ]; then
  mkdir -p "$backup_dir"
  chmod 700 "$backup_dir" # only a folder this script made; an existing one keeps its mode
fi

say "Counting rows in the live database"
live="$(table_counts lukitas)" || fail "could not read the live database"

say "Dumping (pg_dump -Fc, as the database owner)"
compose exec -T postgres pg_dump -U lukitas -d lukitas -Fc >"$partial" || fail "pg_dump failed"
[ -s "$partial" ] || fail "the dump is empty"

say "Checking the dump lists"
toc="$(compose exec -T postgres pg_restore -l <"$partial")" || fail "pg_restore cannot read the dump"
for table in $MAIN_TABLES; do
  table_name="$(printf '%s' "$table" | tr -d '"')"
  printf '%s\n' "$toc" | grep -q "TABLE DATA public $table_name " || fail "the dump has no data section for table $table_name"
done

say "Checking the dump restores (scratch database $scratch)"
psql_db postgres -qc "drop database if exists $scratch with (force)" >/dev/null 2>&1
psql_db postgres -qc "create database $scratch" >/dev/null
compose exec -T postgres pg_restore -U lukitas -d "$scratch" --no-owner --exit-on-error --single-transaction <"$partial" ||
  fail "the dump does not restore"
restored="$(table_counts "$scratch")" || fail "could not read the restored copy"

printf '%-18s %8s %8s\n' table live restored
problems=""
while read -r table live_n; do
  restored_n="$(printf '%s\n' "$restored" | awk -v t="$table" '$1 == t { print $2 }')"
  printf '%-18s %8s %8s\n' "$table" "$live_n" "${restored_n:-?}"
  if [ "$live_n" -gt 0 ] && [ "${restored_n:-0}" -eq 0 ]; then
    problems="$problems $table"
  fi
done <<EOF2
$live
EOF2
[ -z "$problems" ] || fail "tables with rows are empty in the dump:$problems"

mv -f "$partial" "$final"
chmod 600 "$final"

# Retention (lib.sh): nothing older than 14 days; under that, daily and pre-update dumps are counted
# separately, so a pre-update backup never pushes a daily one out, and never replaces it.
retain

say "Backup saved: $final ($(du -h "$final" | cut -f1))"

# --- The optional encrypted second copy. The primary backup above is already safe. -------------
copy_failed=""
if [ -n "$copy_dir" ] || [ -n "$age_recipient" ]; then
  if [ -z "$copy_dir" ] || [ -z "$age_recipient" ]; then
    echo "WARNING: set both BACKUP_COPY_DIR and BACKUP_AGE_RECIPIENT for the encrypted copy; skipping it." >&2
  elif ! command -v age >/dev/null 2>&1; then
    echo "WARNING: 'age' is not installed (brew install age); skipping the encrypted copy." >&2
  else
    case "$age_recipient" in
      age1*) ;;
      *) copy_failed="BACKUP_AGE_RECIPIENT is not an age public key (it starts with age1)" ;;
    esac
    if [ -z "$copy_failed" ]; then
      mkdir -p "$copy_dir" || copy_failed="cannot create $copy_dir"
    fi
    if [ -z "$copy_failed" ]; then
      tmp="$copy_dir/.$name.age.partial"
      if age -r "$age_recipient" -o "$tmp" "$final" && [ -s "$tmp" ]; then
        mv -f "$tmp" "$copy_dir/$name.age"
        retain
        say "Encrypted copy saved: $copy_dir/$name.age"
      else
        rm -f "$tmp"
        copy_failed="age could not encrypt the backup into $copy_dir"
      fi
    fi
    [ -z "$copy_failed" ] || fail "the backup is saved, but the encrypted copy failed: $copy_failed"
  fi
fi
