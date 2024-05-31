#!/bin/sh
set -e

# Check if the required environment variables for Litestream are set.
use_litestream() {
    [ -n "$LITESTREAM_REPLICA_BUCKET" ] &&
        [ -n "$LITESTREAM_REPLICA_PATH" ] &&
        [ -n "$LITESTREAM_REPLICA_ENDPOINT" ] &&
        [ -n "$LITESTREAM_ACCESS_KEY_ID" ] &&
        [ -n "$LITESTREAM_SECRET_ACCESS_KEY" ]
}

# Check if the required environment variables for Memogram are set.
use_memogram() {
    [ -n "$BOT_TOKEN" ] && [ -n "$SERVER_ADDR" ]
}

# Main script logic
if use_litestream; then
    if [ -f "$DB_PATH" ]; then
        echo "Database exists, skipping restore."
        echo "Tips: If you want to restore the latest version of database from S3/B2, please delete the $DB_PATH file and restart."
        echo "Warning: Deleting the $DB_PATH file may cause data loss. Make sure to backup your database before deleting the $DB_PATH file."
    else
        echo "No local database found, attempt to restore the latest version of database from S3/B2."
        litestream restore -if-replica-exists "$DB_PATH"
        echo "Database restored successfully!"
    fi
fi

# Start Litestream with the Memos service as the subprocess.
echo "Starting litestream replicate with the Memos service as the subprocess."
litestream replicate -exec "./memos" &

# Start Memogram if the required environment variables are set.
if use_memogram; then
    timeout=30
    while [ $timeout -gt 0 ]; do
        if pgrep -x "memos" >/dev/null && [ -f "$DB_PATH" ]; then
            ./memogram
            break
        else
            echo "memos is not running, waiting for 5 seconds before retrying"
            sleep 5
            timeout=$((timeout - 5))
        fi
    done

    if [ $timeout -eq 0 ]; then
        echo "over 30 seconds, memos is still not running, exiting"
        exit 1
    fi
fi
