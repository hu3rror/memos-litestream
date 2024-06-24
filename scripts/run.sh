#!/bin/sh
set -e

# Function to check if the required environment variables for Litestream are set.
use_litestream() {
    [ -n "$LITESTREAM_REPLICA_BUCKET" ] && [ -n "$LITESTREAM_REPLICA_PATH" ] && [ -n "$LITESTREAM_REPLICA_ENDPOINT" ] && [ -n "$LITESTREAM_ACCESS_KEY_ID" ] && [ -n "$LITESTREAM_SECRET_ACCESS_KEY" ]
}

# Function to check if the required environment variables for Memogram are set.
use_memogram() {
    [ -x ./memogram ] && [ -n "$BOT_TOKEN" ]
}

# Function to log messages with timestamp
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1"
}

# Function to start Memogram.
start_memogram() {
    log "[INFO] Found BOT_TOKEN, now attempt to start Memogram service."

    timeout=60
    while [ $timeout -gt 0 ]; do
        if pgrep -x "memos" >/dev/null && [ -f "$DB_PATH" ]; then
            log "[INFO] Now starting Memogram service."
            ./memogram
            break
        else
            log "[WARNING] memos is not running, waiting for 5 seconds before retrying"
            sleep 5
            timeout=$((timeout - 5))
        fi
    done

    # Exit if memos is still not running
    if [ $timeout -eq 0 ]; then
        log "[ERROR] Timeout over 60 seconds, memos is still not running, exiting"
        exit 1
    fi
}

# Start Litestream to restore the database.
if use_litestream; then
    if [ -f "$DB_PATH" ]; then
        log "[WARNING] Local Database exists, skipping restore."
        log "[INFO] If you want to restore the latest version of the database from S3/B2 instead of using the local database, please delete the $DB_PATH file and restart the service."
        log "[WARNING] Deleting the $DB_PATH file may cause data loss. Make sure to backup your database before deleting the $DB_PATH file."
    else
        log "[WARNING] No local database found, attempt to restore the latest version of database from S3/B2."
        litestream restore -if-replica-exists "$DB_PATH"
        if [ ! -f "$DB_PATH" ]; then
            log "[WARNING] No database found in S3/B2."
            log "[INFO] It seems that you are using memos for the first time, the database will be created after the first run."
        fi
    fi
fi

# Start Memos with Litestream but without Memogram
if use_litestream && ! use_memogram; then
    echo "[Scheme] Memos ✓ | Litestream ✓ | Memogram ✕"
    log "[INFO] Now starting Memos service with Litestream."
    exec litestream replicate -exec "./memos"

# Start Memos with Litestream and Memogram
elif use_litestream && use_memogram; then
    echo "[Scheme] Memos ✓ | Litestream ✓ | Memogram ✓"
    log "[INFO] Now starting Memos service with Litestream."
    litestream replicate -exec "./memos" &
    start_memogram

# Start Memos without Litestream but with Memogram
elif ! use_litestream && use_memogram; then
    echo "[Scheme] Memos ✓ | Litestream ✕ | Memogram ✓"
    log "[INFO] Now starting Memos service."
    ./memos &
    start_memogram

# Start Memos solely
elif ! use_litestream && ! use_memogram; then
    echo "[Scheme] Memos ✓ | Litestream ✕ | Memogram ✕"
    log "[INFO] Now starting Memos service."
    exec ./memos
fi
