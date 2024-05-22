#!/bin/sh
set -e

# Check if the required environment variables for Litestream are set.
check_litestream_env() {
	[ -n "$LITESTREAM_REPLICA_BUCKET" ] &&
		[ -n "$LITESTREAM_REPLICA_PATH" ] &&
		[ -n "$LITESTREAM_REPLICA_ENDPOINT" ] &&
		[ -n "$LITESTREAM_ACCESS_KEY_ID" ] &&
		[ -n "$LITESTREAM_SECRET_ACCESS_KEY" ]
}

# Main script logic
if check_litestream_env; then
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
exec litestream replicate -exec "./memos"
