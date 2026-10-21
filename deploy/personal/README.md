# Personal install

Run your own Lukitas on one machine (a Mac, to start), reach it from your phone through a Cloudflare
tunnel at `https://app-lukas.andersonlaverde.com`, and keep your real data safe with a daily backup.
Later the same files move to a server and the data comes with them (see
[Moving to a server](#moving-to-a-server)).

It is a separate stack from the development one in the repository root: its own Docker project
(`lukitas-personal`), database volume (`lukitas-personal-db`) and private network. Nothing is shared
with `docker compose up` in the root (ports 5433, 3000, 5173, 8025, 1026), so both can run together.

```
 phone ──https──> Cloudflare ──tunnel──> cloudflared ──> web (Caddy) ──/api/*──> api ──> postgres
                  (TLS, DNS)             (outbound only)   │ static app + landing      │ role lukas_app,
                                                           │                           │ row-level security
                                                           └ http://127.0.0.1:8088     └ the volume lukitas-personal-db
                                                             (this Mac only)
```

- **One origin.** The app and the API share `app-lukas.andersonlaverde.com` (the API is under
  `/api`), so the session cookie is first-party and secure. No CORS.
- **Allowlist.** Only the emails in `SIGN_IN_ALLOWLIST` can ask for a sign-in code. Anyone else
  gets "Lukitas todavía no está abierto al público" and no email is sent. The landing page at `/`
  stays public (a search-engine `noindex` header is set).
- **No open ports.** Postgres and the API publish nothing. Caddy publishes `127.0.0.1:8088` for
  checking on this Mac. The tunnel is outbound only.
- **Mail** goes out as `hola@andersonlaverde.com` through Proton Bridge on the host.
- **The API never holds the owner password.** A one-shot `migrate` service creates the `lukas_app`
  role and applies the migrations; the API connects as `lukas_app` only.

## First-time setup

You need Docker Desktop, Node 22 with pnpm (`corepack enable`), `cloudflared`
(`brew install cloudflared`) and Proton Bridge, signed in to the `hola@andersonlaverde.com` account.

### 1. Proton Bridge credentials

Bridge gives each account its own SMTP password; your Proton password does not work with it.

1. Open Proton Mail Bridge, click the account, then **Mailbox configuration**.
2. Under **SMTP** note the **Username** (the address) and the **Password** (a random string).
   Hostname `127.0.0.1`, port `1025`, security **STARTTLS**.
3. You will put them in `.env` as `SMTP_URL` (below). Containers reach Bridge on the Mac as
   `host.docker.internal:1025`. Bridge must be running whenever someone asks for a code.

Bridge's certificate is self-signed. `SMTP_TLS_INSECURE=true` tells the API to accept it, and only
for this mail connection: STARTTLS is still required, and the API refuses to start with the flag
unless `SMTP_URL` points at this machine (`localhost`, `127.0.0.1`, `[::1]` or
`host.docker.internal`).

### 2. `.env`

```sh
cd deploy/personal
cp .env.example .env
```

Fill it in (every variable is explained in the file; `.env` is ignored by git and never committed):

| Variable | Value |
|---|---|
| `POSTGRES_PASSWORD` | `openssl rand -hex 24` |
| `APP_DB_PASSWORD` | `openssl rand -hex 24` |
| `BETTER_AUTH_SECRET` | `openssl rand -hex 32` |
| `SIGN_IN_ALLOWLIST` | your email(s), comma-separated |
| `SMTP_URL` | `smtp://hola%40andersonlaverde.com:BRIDGE_PASSWORD@host.docker.internal:1025` (the `@` of the user is written `%40`) |
| `TUNNEL_ID` | from step 3 |

Keep a copy of `.env` in your password manager: `BETTER_AUTH_SECRET` and the database passwords are
needed again when you move to a server.

### 3. The tunnel

Run these yourself, once. They talk to your Cloudflare account.

```sh
cloudflared tunnel login                       # opens the browser: choose andersonlaverde.com
cloudflared tunnel create lukitas-personal     # prints the tunnel id, writes ~/.cloudflared/<id>.json
cloudflared tunnel route dns lukitas-personal app-lukas.andersonlaverde.com
```

Put the id in `.env` as `TUNNEL_ID`. The stack mounts `~/.cloudflared/<TUNNEL_ID>.json` read-only
into the `cloudflared` container; it does not see `cert.pem` (the login certificate). Treat the
`.json` as a secret: anyone with it can run your tunnel. `cloudflared.yml` already routes
`app-lukas.andersonlaverde.com` to the web container.

### 4. First start

```sh
./up.sh --no-tunnel     # build, migrate, start; nothing is on the internet yet
./smoke.sh              # checks http://127.0.0.1:8088
```

`up.sh` builds the web app for your hostname into `apps/web/build-personal` (the landing release in
`apps/web/build` is not touched), builds the images, starts Postgres, runs the one-shot `migrate`
service (it creates the `lukas_app` role the first time), then starts the API and Caddy. If
`smoke.sh` passes, start the tunnel too:

```sh
./up.sh --skip-web      # adds cloudflared; reuses the web build
```

Open `https://app-lukas.andersonlaverde.com` on your phone and sign in with an allowlisted email:
the code arrives from `hola@andersonlaverde.com`.

### 5. The daily backup

```sh
./backup.sh             # try it once, by hand
./install-backup.sh     # then schedule it: every day at 03:00, as a launchd agent
```

See [Backup and restore](#backup-and-restore).

## Daily use

Run these from `deploy/personal` (compose reads `.env` there):

```sh
docker compose ps                  # what is running
docker compose logs -f api         # follow the API (also: web, cloudflared, postgres)
docker compose restart api
docker compose stop                # stop everything, keep everything
./up.sh --skip-web                 # start it again
```

Everything has `restart: unless-stopped`, so it comes back after a reboot once Docker Desktop is up.
In Docker Desktop settings, turn on **Start Docker Desktop when you sign in to your computer**.

**Never run `docker compose down -v`** (or `docker volume rm lukitas-personal-db`): that deletes the
database. `docker compose down` is safe. The scripts here refuse `down -v` on purpose.

### Who can sign in

Edit `SIGN_IN_ALLOWLIST` in `.env`, then `docker compose up -d api`. Case does not matter. Passkeys
of existing users keep working whatever the list says; the list only gates asking for a code.

### Keeping the Mac awake

While the Mac sleeps, the tunnel is down and your phone shows a Cloudflare error (1033). To stay
reachable:

- Plugged in (the wording varies by macOS version): **System Settings > Battery > Options > Prevent automatic sleeping on power adapter
  when the display is off** (on desktop Macs: **Energy > Prevent automatic sleeping...**).
  Enable **Wake for network access** as well.
- Or hold it awake from a terminal: `caffeinate -s` (stays awake on AC power while it runs;
  `Ctrl-C` stops it). With the lid closed a laptop sleeps anyway unless it is plugged in with an
  external display, or you use a tool such as Amphetamine.

The backup does not need the Mac to be awake at 03:00: launchd runs a missed backup when the Mac wakes.

## Update

```sh
./update.sh
```

It backs up first, runs `git pull --ff-only` on the branch the repository is on, rebuilds the web
app and the images, applies new migrations, and restarts. It never removes volumes. Options:
`--skip-backup`, `--no-pull`. If the pull cannot fast-forward (you have local commits) it stops
before changing anything.

Migrations should be backward compatible with the previous version, because the new API starts
after the migration but a failed deploy leaves the old API running against the new schema. To go
back to the code you had: `git checkout <old commit>`, `./update.sh --no-pull`; to go back to the
data you had, restore the backup `update.sh` made.

## Backup and restore

`backup.sh` writes `~/Backups/lukitas/lukitas-YYYY-MM-DD.dump` (`BACKUP_DIR` in `.env` changes the
folder), keeps the newest 14, and checks every dump before keeping it:

1. `pg_dump -Fc` as the database owner, which bypasses row-level security. (Every table here is
   `FORCE ROW LEVEL SECURITY`; a dump as `lukas_app` fails, as it should. Do not change the role.)
2. `pg_restore -l` lists it and has a data section for every main table.
3. It restores into a scratch database and compares row counts with the live one for `user`,
   `passkey`, `accounts`, `categories`, `category_budgets`, `recurrences`, `imports` and
   `transactions`: a table with rows that restores empty fails the backup.

If a check fails, the new file is deleted, the older dumps stay, the script exits non-zero and (from
the scheduled run) macOS shows a notification "Lukitas backup failed". Log of the scheduled run:
`~/Library/Logs/lukitas-backup.log`.

**Schedule.** `./install-backup.sh` installs `com.lukitas.backup` for your user (check what it
installs first with `./install-backup.sh --render`; remove it with `./uninstall-backup.sh`). Runs at
03:00, or on wake if the Mac was asleep. If the Mac is switched off at 03:00 that day is skipped.
Docker Desktop must be running. `launchctl kickstart gui/$(id -u)/com.lukitas.backup` runs it now.

**Where the dumps are.** On the same Mac, so they do not protect you from losing the Mac. They
hold your real data and are not encrypted: keep **FileVault** on, and copy the folder somewhere else
now and then (an external disk, or an encrypted cloud folder). The files are readable by you only.

**Restore drill** (do it after the first backup and every month or two): restores the dump into a
scratch database next to the real one, prints the row counts, drops it. Nothing live changes.

```sh
./restore.sh --drill ~/Backups/lukitas/lukitas-2026-10-21.dump
```

**Restore for real** (the data in the dump replaces the live data):

```sh
./restore.sh ~/Backups/lukitas/lukitas-2026-10-21.dump
```

It restores into a new database first (if that fails nothing has changed), asks you to type
`restore`, stops the API and the tunnel, renames the old database to `lukitas_before_<time>` (kept:
drop it yourself when you are sure), puts the new one in its place, applies newer migrations, and
starts everything. `--yes` skips the question.

## Moving to a server

The same files run on any Linux server with Docker. Keep the hostname: **passkeys are bound to
`app-lukas.andersonlaverde.com`**, so a new hostname invalidates every passkey (email codes still
work).

1. On the Mac: `./backup.sh`, and copy the newest dump and your `.env` to the server.
2. On the server: clone the repository, put `.env` in `deploy/personal/` (same
   `BETTER_AUTH_SECRET` so sessions survive; email by `RESEND_API_KEY` with `SMTP_URL` empty and
   `SMTP_TLS_INSECURE=false`, since Bridge stays on the Mac), then `./up.sh --no-tunnel`.
   (`up.sh` needs Node and pnpm for the web build; or copy `apps/web/build-personal` from the Mac
   and use `--skip-web`.)
3. `./restore.sh --yes lukitas-YYYY-MM-DD.dump` loads the data (the database is empty, so nothing is
   lost; the empty one is kept as `lukitas_before_...`).
4. Move the tunnel: copy `~/.cloudflared/<TUNNEL_ID>.json` to the server, then **stop the Mac's
   stack first** (`docker compose stop cloudflared`) and run `./up.sh --skip-web` on the server. Or
   create a new tunnel there and re-point the name with
   `cloudflared tunnel route dns --overwrite-dns <new tunnel> app-lukas.andersonlaverde.com`.
5. Check `./smoke.sh` and sign in. Keep the Mac's last dump until the server has its own.

Install `backup.sh` on the server with cron or a systemd timer (`install-backup.sh` is macOS only).

## Files

| File | What |
|---|---|
| `docker-compose.yml` | The stack: postgres, migrate, api, web, cloudflared |
| `Caddyfile` | Static app, SPA fallback, cache rules, `/api` proxy and the client address |
| `cloudflared.yml` | Tunnel ingress for `app-lukas.andersonlaverde.com` |
| `Dockerfile.web` | Caddy with the web build inside (the API image is `apps/api/Dockerfile.prod`) |
| `.env.example` | Every setting, documented |
| `up.sh` `update.sh` `smoke.sh` | Start, update, check |
| `backup.sh` `restore.sh` | Verified backups; restore and drill |
| `install-backup.sh` `uninstall-backup.sh` `com.lukitas.backup.plist` | The 03:00 launchd agent |

## How the client address gets to the API

Sign-in limits (5 codes per 10 minutes per address) count by client address. Cloudflare puts the
visitor's address in `CF-Connecting-IP` and overwrites any value the visitor sent; cloudflared hands
it to Caddy; Caddy writes it as the only `X-Forwarded-For` entry and the API trusts exactly one
proxy: Caddy's fixed address `172.28.77.10` (`TRUSTED_PROXIES`). A request that reaches Caddy
without that header (curl on this Mac) is counted by the address Docker shows. Nothing from outside
can reach the API without passing through Caddy. See `docs/deploy/api.md`.

## Troubleshooting

- **Error 1033 / 530 on the phone**: the tunnel is down. Is the Mac awake, Docker running, and
  `docker compose ps` showing `cloudflared` up? `docker compose logs cloudflared`.
- **No email arrives**: Bridge not running or not signed in; wrong password in `SMTP_URL`
  (`docker compose logs api | tail`); the address is not in `SIGN_IN_ALLOWLIST` (the app says so).
- **`up.sh` says port or subnet in use**: change `WEB_PORT` or `NETWORK_PREFIX` in `.env`.
- **API restarts at start**: `docker compose logs api` prints which variable is wrong.
- **Backup fails with "Docker is not running"**: start Docker Desktop; the next run is tomorrow, or
  run `./backup.sh` now.
