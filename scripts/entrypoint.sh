#!/bin/sh
set -e

# ──────────────────────────────────────────────
# memos-litestream entrypoint
# Orchestrates: DB restore, memos (via litestream
# or direct), and optional memogram.
# ──────────────────────────────────────────────

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [Entrypoint] $1"
}

# Defaults
MEMOS_PORT="${MEMOS_PORT:-5230}"
DB_PATH="${DB_PATH:-/var/opt/memos/memos_prod.db}"

# ── helpers ───────────────────────────────────

use_litestream() {
    [ -n "$LITESTREAM_REPLICA_BUCKET" ] && \
    [ -n "$LITESTREAM_REPLICA_PATH" ] && \
    [ -n "$LITESTREAM_REPLICA_ENDPOINT" ] && \
    { [ -n "$AWS_ACCESS_KEY_ID" ] || [ -n "$LITESTREAM_ACCESS_KEY_ID" ]; } && \
    { [ -n "$AWS_SECRET_ACCESS_KEY" ] || [ -n "$LITESTREAM_SECRET_ACCESS_KEY" ]; }
}

use_memogram() {
    [ -x /usr/local/memos/memogram ] && [ -n "$BOT_TOKEN" ]
}

cd /usr/local/memos

# ── save MEMOS_TOKEN + TG_ID ──────────────────

if [ -n "$MEMOS_TOKEN" ] && [ -n "$TG_ID" ]; then
    DATA_FILE="/usr/local/memos/data.txt"
    log "[INFO] Found MEMOS_TOKEN and TG_ID — saving to $DATA_FILE"
    echo "$TG_ID:$MEMOS_TOKEN" > "$DATA_FILE" && \
        log "[INFO] TG_ID:MEMOS_TOKEN saved successfully" || \
        log "[ERROR] Failed to save TG_ID:MEMOS_TOKEN"
elif [ -n "$MEMOS_TOKEN" ] && [ -z "$TG_ID" ]; then
    log "[WARNING] MEMOS_TOKEN set but TG_ID is not — skipping data.txt"
elif [ -z "$MEMOS_TOKEN" ] && [ -n "$TG_ID" ]; then
    log "[WARNING] TG_ID set but MEMOS_TOKEN is not — skipping data.txt"
fi

# ── database restore ──────────────────────────

if use_litestream; then
    if [ -f "$DB_PATH" ]; then
        log "[WARNING] Local database exists — skipping restore."
        log "[INFO]  Delete $DB_PATH and restart to restore from S3/B2."
    else
        log "[WARNING] No local database found — attempting restore from S3/B2."
        /usr/local/bin/litestream restore \
            -config /etc/litestream.yml \
            -if-replica-exists "$DB_PATH"

        if [ ! -f "$DB_PATH" ]; then
            log "[WARNING] No database found in S3/B2 or restore failed."
            log "[INFO]  Memos will create a fresh database on first run."
        else
            log "[INFO] Database restored successfully."
        fi
    fi
else
    log "[INFO] Litestream not configured — skipping database restore."
fi

# ── start memogram (background) ───────────────

if use_memogram; then
    log "[INFO] BOT_TOKEN found — will start memogram once memos is ready."
    (
        for i in $(seq 1 60); do
            nc -z localhost "$MEMOS_PORT" 2>/dev/null && \
                exec /usr/local/memos/memogram
            sleep 5
        done
        log "[ERROR] Timed out waiting for memos on port $MEMOS_PORT."
        exit 1
    ) &
fi

# ── start memos ───────────────────────────────

if use_litestream; then
    log "[INFO] Starting memos with Litestream replication."
    exec /usr/local/bin/litestream replicate -exec /usr/local/memos/memos
else
    log "[INFO] Starting memos directly."
    exec /usr/local/memos/memos
fi
