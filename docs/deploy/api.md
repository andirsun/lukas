# Deploying the API: client addresses and rate limits

The API limits sign-in per client address: 5 code emails per 10 minutes and 3 sign-ins per
10 seconds (Better Auth), on top of 5 code emails per address per 15 minutes. Those limits are
only as good as the address the API believes, and it reads that address from a header, never from
the connection.

- **`CLIENT_IP_HEADER`**: the header to read. Prefer a header your edge sets and overwrites, such
  as `cf-connecting-ip` (Cloudflare) or `fly-client-ip` (Fly.io). Then `TRUSTED_PROXIES` isn't
  needed.
- **`TRUSTED_PROXIES`**: with `X-Forwarded-For`, list the exact egress ranges of the proxies in
  front of the API (comma-separated IPs or CIDRs), and only proxies that append the real client
  address. The API strips them from the right and counts the first address that isn't one of them.
  Don't list loopback unless the proxy runs on the same host.
- **Port 3000 must not be reachable from outside.** Firewall it so only your proxy reaches it:
  anyone who can talk to the API directly can write any `X-Forwarded-For` they like.

Production refuses to start with a bare `X-Forwarded-For` and no `TRUSTED_PROXIES`.

`.env.example` leaves `TRUSTED_PROXIES` empty on purpose. For local development,
`docker-compose.yml` sets it to `127.0.0.1,::1` in the `api` service, because there the proxy is
Vite's dev server on the same machine. CI needs the same setting for the e2e suite, which gives each
browser its own address.
