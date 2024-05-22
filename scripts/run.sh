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

use_memogram() {
	[ -f "./telegram_bot/memogram" ] && [ -f "./telegram_bot/.env" ]
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

if use_memogram; then
	# Replace the MEMOGRAM_BOT_TOKEN placeholder in the .env file with the actual token value.
	if [ -n "$MEMOGRAM_BOT_TOKEN" ]; then
		sed -i 's/<MEMOGRAM_BOT_TOKEN>/'"$MEMOGRAM_BOT_TOKEN"'/g' ./telegram_bot/.env
	fi

	# If the MEMOS_PORT environment variable is not set to the default value, replace it in the .env file.
	if [ "$MEMOS_PORT" != "5230" ]; then
		sed -i 's/5230/'"$MEMOS_PORT"'/g' ./telegram_bot/.env
	fi

	timeout=30
	while [ $timeout -gt 0 ]; do
		if pgrep -x "memos" >/dev/null && [ -f "$DB_PATH" ]; then
			./telegram_bot/memogram
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
