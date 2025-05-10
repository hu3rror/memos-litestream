#!/bin/sh
set -e

# Function to log messages with timestamp
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [MemogramService] $1"
}

# Function to check if the required environment variables for Memogram are set.
use_memogram_check() {
    [ -x /usr/local/memos/memogram ] && [ -n "$BOT_TOKEN" ]
}

cd /usr/local/memos # Ensure we are in the correct working directory

if ! use_memogram_check; then
    log "[INFO] Memogram prerequisites not met (executable missing or BOT_TOKEN not set). Memogram will not start."
    # Exit normally, so supervisor doesn't consider this an error and doesn't restart indefinitely.
    # If you want supervisor not to attempt to start when the conditions are not met, you can dynamically generate the supervisor configuration in run.sh, but this is more complex.
    exit 0
fi

log "[INFO] Found BOT_TOKEN, now attempt to start Memogram service."

# Wait for memos to start and create the database file
# Using nc (netcat) or similar tools to check if the memos port is reachable might be more reliable.
# But pgrep and file checking are also a method.
timeout=300 # Increase timeout
attempt=0
max_attempts=$((timeout / 5))
retry_delay=5 # Retry interval, in seconds

while [ $attempt -lt $max_attempts ]; do
    # Check if the memos port is reachable
    if nc -z localhost "$MEMOS_PORT" 2>/dev/null; then
        log "[INFO] Memos port $MEMOS_PORT is reachable."
        # Further check if DB_PATH exists, because memos might still be initializing
        if [ -f "$DB_PATH" ]; then
            log "[INFO] Database file $DB_PATH found. Now starting Memogram service."
            exec /usr/local/memos/memogram # Use exec to replace the current shell
        else
            log "[WARNING] Memos port reachable, but DB_PATH $DB_PATH not yet found. Waiting..."
        fi
    else
        log "[WARNING] Memos port $MEMOS_PORT is not reachable. Waiting..."
    fi
    sleep $retry_delay
    attempt=$((attempt + 1))
done

log "[ERROR] Timeout ($timeout seconds) reached. Memos service not fully ready or DB_PATH not found. Memogram will not start."
exit 1 # Exit with an error, so supervisor will try to restart (according to autorestart=true)