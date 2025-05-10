#!/bin/sh
set -e

# Function to log messages with timestamp
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [Entrypoint] $1"
}

# Function to check if the required environment variables for Litestream are set.
use_litestream_check() {
    [ -n "$LITESTREAM_REPLICA_BUCKET" ] && [ -n "$LITESTREAM_REPLICA_PATH" ] && [ -n "$LITESTREAM_REPLICA_ENDPOINT" ] && [ -n "$LITESTREAM_ACCESS_KEY_ID" ] && [ -n "$LITESTREAM_SECRET_ACCESS_KEY" ]
}

cd /usr/local/memos # Ensure we are in the correct working directory

# Check for MEMOS_TOKEN and TG_ID and save it to data.txt
if [ -n "$MEMOS_TOKEN" ] && [ -n "$TG_ID" ]; then
  DATA_FILE="/usr/local/memos/data.txt" # Ensure the path is correct

  log "[INFO] Found MEMOS_TOKEN and TG_ID environment variables. Saving to $DATA_FILE"
  echo "$TG_ID:$MEMOS_TOKEN" > "$DATA_FILE"
  if [ $? -ne 0 ]; then
    log "[ERROR] Failed to save TG_ID:MEMOS_TOKEN to $DATA_FILE"
  else
    log "[INFO] TG_ID:MEMOS_TOKEN saved successfully to $DATA_FILE"
  fi
elif [ -n "$MEMOS_TOKEN" ] && [ -z "$TG_ID" ]; then
  log "[WARNING] Found MEMOS_TOKEN but TG_ID is not set. Not saving to data.txt"
elif [ -z "$MEMOS_TOKEN" ] && [ -n "$TG_ID" ]; then
  log "[WARNING] Found TG_ID but MEMOS_TOKEN is not set. Not saving to data.txt"
fi

# Start Litestream to restore the database if configured and DB doesn't exist.
if use_litestream_check; then
    if [ -f "$DB_PATH" ]; then
        log "[WARNING] Local Database exists, skipping restore."
        log "[INFO] If you want to restore the latest version of the database from S3/B2 instead of using the local database, please delete the $DB_PATH file and restart the service."
    else
        log "[WARNING] No local database found, attempt to restore the latest version of database from S3/B2."
        # Use the -config parameter to ensure litestream knows the location of its configuration file
        /usr/local/bin/litestream restore -config /etc/litestream.yml -if-replica-exists "$DB_PATH"
        if [ ! -f "$DB_PATH" ]; then
            log "[WARNING] No database found in S3/B2 or restore failed."
            log "[INFO] The database will be created by Memos on its first run if it's still missing."
        else
            log "[INFO] Database restored successfully to $DB_PATH."
        fi
    fi
else
    log "[INFO] Litestream is not configured. Skipping database restore check."
fi

log "[INFO] Initial setup complete. Handing over to supervisord."
exec "$@"
