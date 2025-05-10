#!/bin/sh
set -e

# Function to log messages with timestamp
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [MemosService] $1"
}

# Function to check if the required environment variables for Litestream are set.
use_litestream() {
    [ -n "$LITESTREAM_REPLICA_BUCKET" ] && \
    [ -n "$LITESTREAM_REPLICA_PATH" ] && \
    [ -n "$LITESTREAM_REPLICA_ENDPOINT" ] && \
    [ -n "$LITESTREAM_ACCESS_KEY_ID" ] && \
    [ -n "$LITESTREAM_SECRET_ACCESS_KEY" ]
}

cd /usr/local/memos # Ensure we are in the correct working directory

if use_litestream; then
    log "[INFO] Now starting Memos service with Litestream."
    # exec litestream replicate -exec "./memos --mode ${MEMOS_MODE} --port ${MEMOS_PORT}"
    # Litestream's -exec will pass memos' stdout/stderr to litestream, and then litestream will pass it to supervisor.
    # Ensure that memos uses environment variables or configuration files to obtain its settings, rather than relying on parameters here (unless you are sure these parameters are always fixed).
    # Memos will listen on 0.0.0.0:$MEMOS_PORT by default.
    exec /usr/local/bin/litestream replicate -exec "/usr/local/memos/memos"
else
    log "[INFO] Now starting Memos service directly."
    exec /usr/local/memos/memos
fi
