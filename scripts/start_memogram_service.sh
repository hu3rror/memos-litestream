#!/bin/sh
set -e

# ── memogram launcher ─────────────────────────
# Waits for memos TCP port, then execs memogram.
# Used directly by entrypoint.sh, or standalone.

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [MemogramService] $1"
}

MEMOS_PORT="${MEMOS_PORT:-5230}"

[ -x /usr/local/memos/memogram ] && [ -n "$BOT_TOKEN" ] || {
    log "[INFO] Prerequisites not met (binary missing or BOT_TOKEN not set) — exiting."
    exit 0
}

log "[INFO] Waiting for memos on port $MEMOS_PORT..."

for i in $(seq 1 60); do
    nc -z localhost "$MEMOS_PORT" 2>/dev/null && {
        log "[INFO] Memos is ready — starting memogram."
        exec /usr/local/memos/memogram
    }
    sleep 5
done

log "[ERROR] Timed out waiting for memos on port $MEMOS_PORT."
exit 1