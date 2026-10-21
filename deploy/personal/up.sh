#!/usr/bin/env bash
# Builds and starts the personal install: the web app, the images, the database, the migrations,
# then the API, the web server and the tunnel. Safe to run again; it never removes volumes.
#
#   ./up.sh                 everything
#   ./up.sh --no-tunnel     everything except the tunnel (checking it on 127.0.0.1 first)
#   ./up.sh --skip-web      reuse the last web build (apps/web/build-personal)
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

with_tunnel=1
build_web=1
for arg in "$@"; do
  case "$arg" in
    --no-tunnel) with_tunnel=0 ;;
    --skip-web) build_web=0 ;;
    -h | --help)
      sed -n '2,8p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) die "unknown option: $arg" ;;
  esac
done

need_env_file
need_docker
host="$(cfg PUBLIC_HOSTNAME app-lukas.andersonlaverde.com)"
web_port="$(cfg WEB_PORT 8088)"

if [ "$with_tunnel" = 1 ]; then
  tunnel_id="$(cfg TUNNEL_ID)"
  [ -n "$tunnel_id" ] || die "TUNNEL_ID is empty in $ENV_FILE. Create the tunnel first (README.md), or run ./up.sh --no-tunnel."
  creds="$(cfg CLOUDFLARED_DIR "$HOME/.cloudflared")/$tunnel_id.json"
  [ -f "$creds" ] || die "Tunnel credentials not found: $creds (README.md, 'The tunnel')."
fi

if [ "$build_web" = 1 ]; then
  say "Building the web app for https://$host"
  command -v pnpm >/dev/null 2>&1 || die "pnpm is not installed (corepack enable)"
  (
    cd "$REPO_DIR"
    pnpm install --frozen-lockfile
    # Its own folder: apps/web/build/client holds the landing release and must stay as it is.
    rm -rf apps/web/build-personal
    VITE_SITE_URL="https://$host" VITE_LANDING_ONLY=false LUKAS_BUILD_DIR=build-personal \
      pnpm --filter @lukas/web build
  )
fi
[ -f "$REPO_DIR/apps/web/build-personal/client/index.html" ] ||
  die "No web build in apps/web/build-personal. Run ./up.sh without --skip-web."

say "Building the images"
compose build

say "Starting the database"
compose up -d --wait postgres

say "Applying migrations (creates the lukas_app role the first time)"
compose run --rm migrate

services="api web"
[ "$with_tunnel" = 1 ] && services="$services cloudflared"
say "Starting: $services"
# shellcheck disable=SC2086
compose up -d --wait $services

say "Running"
compose ps
echo
echo "Check it from this machine:  ./smoke.sh   (http://127.0.0.1:$web_port)"
[ "$with_tunnel" = 1 ] && echo "On the internet:             https://$host"
exit 0
