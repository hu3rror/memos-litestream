#!/bin/sh
set -e

# Check if the required environment variables for Litestream are set.
use_litestream() {
    [ -n "$LITESTREAM_REPLICA_BUCKET" ] && [ -n "$LITESTREAM_REPLICA_PATH" ] && [ -n "$LITESTREAM_REPLICA_ENDPOINT" ] && [ -n "$LITESTREAM_ACCESS_KEY_ID" ] && [ -n "$LITESTREAM_SECRET_ACCESS_KEY" ]
}

# Check if the required environment variables for Memogram are set.
use_memogram() {
    [ -x /usr/local/memos/memogram ] && [ -n "$BOT_TOKEN" ]
}

# Main script logic
if use_litestream; then
    if [ -f "$DB_PATH" ]; then
        echo "WARNING: Local Database exists, skipping restore."
        echo "INFO: If you want to restore the latest version of database from S3/B2 instead of the local database, please delete the $DB_PATH file and restart."
        echo "WARNING: Deleting the $DB_PATH file may cause data loss. Make sure to backup your database before deleting the $DB_PATH file."
    else
        echo "WARNING: No local database found, attempt to restore the latest version of database from S3/B2."
        litestream restore -if-replica-exists "$DB_PATH"
        if [ ! -f "$DB_PATH" ]; then
            echo "WARNING: No database found in S3/B2."
            echo "INFO: It seems that you are using memos for the first time, the database will be created after the first run."
        fi
    fi
fi

# # Start Memogram if the required environment variables are set.
if ! use_memogram; then
    echo "INFO: Now starting Memos service with Litestream."
    exec litestream replicate -exec "./memos"
else
    echo "INFO: Now starting Memos service with Litestream."
    litestream replicate -exec "./memos" &
    echo "INFO: Found BOT_TOKEN, now trying to start Memos service with Memogram."
    timeout=30
    while [ $timeout -gt 0 ]; do
        if pgrep -x "memos" >/dev/null && [ -f "$DB_PATH" ]; then
            ./memogram
            break
        else
            echo "WARNING: memos is not running, waiting for 5 seconds before retrying"
            sleep 5
            timeout=$((timeout - 5))
        fi
    done

    if [ $timeout -eq 0 ]; then
        echo "ERROR: Timeout over 30 seconds, memos is still not running, exiting"
        exit 1
    fi
fi
