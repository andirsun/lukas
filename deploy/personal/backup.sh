#!/usr/bin/env bash
# Backs up the database to $BACKUP_DIR/lukitas-YYYY-MM-DD.dump (default ~/Backups/lukitas) and keeps
# the newest 14 daily dumps.
#
# The dump is taken as the database owner, which bypasses row-level security (every table here is
# FORCE ROW LEVEL SECURITY, so a dump by the API's own role would come out empty). A backup is only
# kept after it passes: pg_restore can list it, and restoring it into a scratch database gives rows
# in every main table that has rows in the live one. Otherwise the new file is deleted, the old
# ones stay, and the script exits with an error (and a macOS notification when run by launchd).
#
# Needs the stack running (Docker Desktop up). Settings: BACKUP_DIR, KEEP (default 14), ENV_FILE.
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

umask 077
need_env_file

backup_dir="$(cfg BACKUP_DIR "$HOME/Backups/lukitas")"
case "$backup_dir" in "~"*) backup_dir="$HOME${backup_dir#\~}" ;; esac
keep="${KEEP:-14}"
stamp="$(date +%Y-%m-%d)"
final="$backup_dir/lukitas-$stamp.dump"
partial="$backup_dir/.lukitas-$stamp.dump.partial"
scratch="lukitas_verify"

fail() {
  printf 'BACKUP FAILED: %s\n' "$*" >&2
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
mkdir -p "$backup_dir"
chmod 700 "$backup_dir"

say "Counting rows in the live database"
live="$(table_counts lukitas)" || fail "could not read the live database"

say "Dumping (pg_dump -Fc, as the database owner)"
compose exec -T postgres pg_dump -U lukitas -d lukitas -Fc >"$partial" || fail "pg_dump failed"
[ -s "$partial" ] || fail "the dump is empty"

say "Checking the dump lists"
toc="$(compose exec -T postgres pg_restore -l <"$partial")" || fail "pg_restore cannot read the dump"
for table in $MAIN_TABLES; do
  name="$(printf '%s' "$table" | tr -d '"')"
  printf '%s\n' "$toc" | grep -q "TABLE DATA public $name " || fail "the dump has no data section for table $name"
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

# Keep the newest $keep daily dumps (names sort by date). Other files in the folder are left alone.
old="$(ls -1 "$backup_dir" | grep -E '^lukitas-[0-9]{4}-[0-9]{2}-[0-9]{2}\.dump$' | sort | awk -v keep="$keep" '{ l[NR] = $0 } END { for (i = 1; i <= NR - keep; i++) print l[i] }')"
if [ -n "$old" ]; then
  printf '%s\n' "$old" | while read -r name; do
    rm -f "$backup_dir/$name"
    say "Removed old backup $name"
  done
fi

say "Backup saved: $final ($(du -h "$final" | cut -f1))"
