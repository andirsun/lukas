#!/usr/bin/env bash
# Shared by the scripts in this directory. Source it; do not run it. Works with macOS's bash 3.2.

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$DIR/../.." && pwd)"
# The file with this install's settings. Tests and drills can point ENV_FILE somewhere else.
ENV_FILE="${ENV_FILE:-$DIR/.env}"

say() { printf '==> %s\n' "$*"; }
die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

# cfg KEY [DEFAULT]: the value of KEY from the environment, else from ENV_FILE (quotes removed),
# else DEFAULT. The same order docker compose uses when it reads ENV_FILE.
cfg() {
  local key="$1" default="${2:-}" value
  value="${!key:-}"
  if [ -z "$value" ] && [ -f "$ENV_FILE" ]; then
    value="$(grep -E "^${key}=" "$ENV_FILE" | tail -n 1 | cut -d= -f2- || true)"
    value="${value%\"}"
    value="${value#\"}"
    value="${value%\'}"
    value="${value#\'}"
  fi
  printf '%s' "${value:-$default}"
}

need_env_file() {
  [ -f "$ENV_FILE" ] || die "$ENV_FILE not found. Copy .env.example to .env and fill it in (see README.md)."
}

need_docker() {
  command -v docker >/dev/null 2>&1 || die "docker is not installed or not on PATH"
  docker info >/dev/null 2>&1 || die "Docker is not running. Start Docker Desktop and try again."
}

# compose ARGS...: docker compose for this install. Refuses `down -v` (and `rm -v`): the database
# lives in a volume, and nothing here should ever remove it.
compose() {
  local arg removes=0 volumes=0
  for arg in "$@"; do
    case "$arg" in
      down | rm) removes=1 ;;
      -v | --volumes) volumes=1 ;;
    esac
  done
  [ "$removes$volumes" != "11" ] || die "refusing to run 'docker compose $*': it would delete the database volume"
  docker compose --env-file "$ENV_FILE" -f "$DIR/docker-compose.yml" "$@"
}

# db_running: true when the postgres service is up.
db_running() {
  [ -n "$(compose ps --status running --services 2>/dev/null | grep -x postgres || true)" ]
}

# psql_db DATABASE ARGS...: psql as the database owner, inside the postgres container.
psql_db() {
  local db="$1"
  shift
  compose exec -T postgres psql -v ON_ERROR_STOP=1 -U lukitas -d "$db" "$@"
}

# The tables whose rows backups are checked by (name as SQL writes it).
MAIN_TABLES='"user" passkey accounts categories category_budgets recurrences imports transactions'

# table_counts DATABASE: one "table count" line per main table.
table_counts() {
  local db="$1" table query="" sep=""
  for table in $MAIN_TABLES; do
    query="${query}${sep}select '$(printf '%s' "$table" | tr -d '"')' as t, count(*) as n from ${table}"
    sep=" union all "
  done
  psql_db "$db" -At -F ' ' -c "$query"
}

# guard_checkout FORCE: this install is built from the checkout you develop in, so refuse to deploy
# edits that are not committed, or a branch that is not PERSONAL_BRANCH, unless FORCE is 1. Prints
# what is about to be deployed either way.
guard_checkout() {
  local force="$1" branch wanted commit dirty problems=""
  wanted="$(cfg PERSONAL_BRANCH main)"
  branch="$(git -C "$REPO_DIR" symbolic-ref --short -q HEAD || echo "(detached HEAD)")"
  commit="$(git -C "$REPO_DIR" rev-parse --short HEAD)"
  dirty="$(git -C "$REPO_DIR" status --porcelain --untracked-files=no)"

  if [ "$branch" != "$wanted" ]; then
    problems="${problems}  - the repository is on branch '$branch', but this install deploys '$wanted' (PERSONAL_BRANCH in .env).
"
  fi
  if [ -n "$dirty" ]; then
    problems="${problems}  - there are uncommitted changes to tracked files, and they would be built into the app and
    their migrations applied to your real data:
$(printf '%s\n' "$dirty" | head -n 8 | sed 's/^/      /')
"
  fi
  if [ -n "$problems" ] && [ "$force" != 1 ]; then
    printf 'Not deploying:\n%s\nFix that (commit or stash, and switch to %s), or pass --force if you really mean it.\n' \
      "$problems" "$wanted" >&2
    exit 1
  fi
  [ -z "$problems" ] || printf 'WARNING (--force): deploying anyway:\n%s' "$problems" >&2
  say "Deploying $branch at $commit"
}

# ensure_volume: the database volume is external to the compose project (so `down -v` cannot
# delete it); create it on first use.
ensure_volume() {
  local name
  name="$(cfg DB_VOLUME_NAME lukitas-personal-db)"
  docker volume inspect "$name" >/dev/null 2>&1 || {
    say "Creating the database volume $name"
    docker volume create "$name" >/dev/null
  }
}

# --- Backup retention (backup.sh; tested by test-retention.sh) ------------------------------------

# The dumps backup.sh writes: daily, and the ones taken before an update.
DAILY_DUMP='^lukitas-[0-9]{4}-[0-9]{2}-[0-9]{2}\.dump'
PREUPDATE_DUMP='^lukitas-[0-9]{4}-[0-9]{2}-[0-9]{2}-preupdate-[0-9]{4}\.dump'

# prune_newest DIR REGEX KEEP: delete all but the newest KEEP files in DIR whose names match REGEX
# (names sort by date). Other files in the folder are left alone.
prune_newest() {
  local dir="$1" regex="$2" n="$3" old
  old="$(ls -1 "$dir" | grep -E "$regex" | sort | awk -v keep="$n" '{ l[NR] = $0 } END { for (i = 1; i <= NR - keep; i++) print l[i] }' || true)"
  [ -z "$old" ] || printf '%s\n' "$old" | while read -r f; do
    rm -f "$dir/$f"
    say "Removed old backup $dir/$f"
  done
}

# No dump is kept longer than this many days, daily or pre-update, encrypted copy or not: the app
# tells a person who deletes their account that backups holding it delete themselves within 14 days.
MAX_BACKUP_DAYS=14

# prune_older DIR REGEX DAYS: delete the files in DIR whose names match REGEX and that were last
# modified DAYS days ago or earlier. An hour early, so the 03:00 run DAYS days after a dump removes
# it even if that dump finished a little after 03:00.
prune_older() {
  local dir="$1" regex="$2" days="$3" path newest
  # The newest dump always stays, however old: after weeks of failed backups it is the last good
  # one, and losing it would leave none at all (the failures notify every day meanwhile).
  newest="$(ls -1t "$dir" | grep -E "$regex" | head -n 1 || true)"
  find "$dir" -maxdepth 1 -type f -mmin +"$((days * 1440 - 60))" | while read -r path; do
    printf '%s\n' "${path##*/}" | grep -Eq "$regex" || continue
    [ "${path##*/}" != "$newest" ] || continue
    rm -f "$path"
    say "Removed backup older than $days days: $path"
  done
}

# apply_retention DIR SUFFIX KEEP KEEP_PREUPDATE: the retention of the dumps in DIR (SUFFIX is a
# regex for what follows ".dump": "" for the dumps, '\.age' for the encrypted copies). Nothing
# older than MAX_BACKUP_DAYS; under that, the newest KEEP daily and KEEP_PREUPDATE pre-update dumps,
# counted separately, so a pre-update dump never pushes a daily one out.
apply_retention() {
  local dir="$1" suffix="$2" keep="$3" keep_preupdate="$4"
  [ -d "$dir" ] || return 0
  prune_older "$dir" "($DAILY_DUMP|$PREUPDATE_DUMP)$suffix\$" "$MAX_BACKUP_DAYS"
  prune_newest "$dir" "$DAILY_DUMP$suffix\$" "$keep"
  prune_newest "$dir" "$PREUPDATE_DUMP$suffix\$" "$keep_preupdate"
}
