#!/usr/bin/env bash
# Restores a dump made by backup.sh.
#
#   ./restore.sh --drill FILE   Restore into a scratch database next to the real one, print row
#                               counts, drop it. Nothing live is touched. Do this now and then:
#                               a backup you have never restored is only a hope.
#   ./restore.sh FILE           Replace the live database with the dump (asks first; --yes skips).
#
# The live restore: restores into a new database first (if that fails nothing has changed), then
# stops the API and the tunnel, renames the old database to lukitas_before_<time> (kept, so you can
# go back; drop it yourself once you are happy), puts the new one in its place, applies any newer
# migrations and starts everything again. It also works on a new server: bring the stack's
# database up (docker compose up -d postgres), then run this with the dump.
#
# Options: --keep (drill: keep the scratch database), --yes. Settings: ENV_FILE.
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

drill=0
keep=0
yes=0
file=""
for arg in "$@"; do
  case "$arg" in
    --drill) drill=1 ;;
    --keep) keep=1 ;;
    --yes) yes=1 ;;
    -h | --help)
      sed -n '2,16p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    -*) die "unknown option: $arg" ;;
    *) [ -z "$file" ] || die "one dump at a time"; file="$arg" ;;
  esac
done
[ -n "$file" ] || die "usage: restore.sh [--drill] [--yes] DUMP_FILE"
[ -f "$file" ] || die "no such file: $file"

need_env_file
need_docker
ensure_volume
stamp="$(date +%Y%m%d_%H%M%S)"
scratch="lukitas_restore_$stamp"

say "Starting the database (it keeps running; the API is not needed for a restore)"
compose up -d --wait postgres

say "Checking the dump"
compose exec -T postgres pg_restore -l <"$file" >/dev/null || die "pg_restore cannot read $file"

say "Making sure the lukas_app role exists (a dump's grants need it)"
compose run --rm migrate node dist/bootstrap.js --role-only

# The scratch database goes away on any exit, unless it became the live one or --keep says to keep it.
keep_scratch=$keep
drop_scratch() {
  psql_db postgres -qc "drop database if exists $scratch with (force)" >/dev/null 2>&1 || true
}
trap '[ "$keep_scratch" = 1 ] || drop_scratch' EXIT

say "Restoring into $scratch"
psql_db postgres -qc "create database $scratch" >/dev/null
compose exec -T postgres pg_restore -U lukitas -d "$scratch" --no-owner --exit-on-error --single-transaction <"$file" ||
  die "the restore failed; the live database was not touched"

say "Rows in the restored copy"
table_counts "$scratch" | awk '{ printf "%-18s %8s\n", $1, $2 }'

if [ "$drill" = 1 ]; then
  if [ "$keep" = 1 ]; then
    say "Drill done. Kept database $scratch (psql -U lukitas -d $scratch inside the postgres container)"
  else
    say "Drill done. The dump restores. Scratch database dropped."
  fi
  exit 0
fi

if [ "$yes" != 1 ]; then
  echo
  echo "This will make the dump above the live database. The current one is renamed and kept."
  printf 'Type "restore" to continue: '
  read -r answer
  if [ "$answer" != "restore" ]; then
    die "cancelled; nothing was changed"
  fi
fi

before="lukitas_before_$stamp"
say "Stopping the API and the tunnel"
compose stop cloudflared web api 2>/dev/null || true

say "Swapping databases (old one kept as $before)"
psql_db postgres -qc "select pg_terminate_backend(pid) from pg_stat_activity where datname in ('lukitas', '$scratch') and pid <> pg_backend_pid()" >/dev/null
psql_db postgres -qc "alter database lukitas rename to $before" >/dev/null
psql_db postgres -qc "alter database $scratch rename to lukitas" >/dev/null
keep_scratch=1 # it is the live database now

say "Applying migrations the dump may not have yet"
compose run --rm migrate

say "Starting the app again"
services="api web"
[ -n "$(cfg TUNNEL_ID)" ] && services="$services cloudflared"
# shellcheck disable=SC2086
compose up -d --wait $services

say "Restored from $file"
echo "The previous database is still there as $before. When you are sure, drop it:"
echo "  docker compose --env-file $ENV_FILE -f $DIR/docker-compose.yml exec postgres psql -U lukitas -d postgres -c 'drop database $before'"
