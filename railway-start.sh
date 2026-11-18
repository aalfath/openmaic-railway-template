#!/bin/sh
# Start OpenMAIC on Railway.
set -e

# Defaults for a personal installation on Railway (each can be overridden by a
# service variable of the same name):
#   OWNER_SINGLE_USER=true   one owner and one course library, as upstream's
#                            Docker Compose setup; ACCESS_CODE is the lock
#   TRUST_PROXY_HEADERS=true Railway's edge sets X-Forwarded-For, so the
#                            access-code rate limit works per visitor
export OWNER_SINGLE_USER="${OWNER_SINGLE_USER:-true}"
export TRUST_PROXY_HEADERS="${TRUST_PROXY_HEADERS:-true}"
export HOSTNAME="${HOSTNAME:-0.0.0.0}"
export PORT="${PORT:-3000}"

# Without ACCESS_CODE, anyone who finds the URL owns the whole course library
# (upstream only logs a warning). The template generates one, so refuse to start
# when it was cleared, unless the deployer opts out on purpose.
if [ -z "${ACCESS_CODE:-}" ] && [ "${OPENMAIC_ALLOW_NO_ACCESS_CODE:-false}" != "true" ]; then
  echo "[railway] ACCESS_CODE is empty: refusing to start, because anyone with the URL would own this classroom." >&2
  echo "[railway] Set ACCESS_CODE in the service's Variables (letters and digits, 16+ characters) and redeploy." >&2
  echo "[railway] (To run without it, for example behind your own login proxy, set OPENMAIC_ALLOW_NO_ACCESS_CODE=true.)" >&2
  exit 1
fi

# A new Railway volume is owned by root and holds lost+found; the server writes
# uploaded materials, classroom media, usage records and its instance key here.
if [ "$(id -u)" = "0" ]; then
  mkdir -p /app/data
  rmdir /app/data/lost+found 2>/dev/null || true
  chown -R nextjs:nodejs /app/data
  exec su-exec nextjs:nodejs node server.js "$@"
fi
exec node server.js "$@"
