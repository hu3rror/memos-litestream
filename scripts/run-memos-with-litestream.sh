#!/bin/sh
set -e

# Check if the environment variables required for Litestream are set.
use_litestream() {
	# Check if all the required environment variables are set.
	[ -n "$LITESTREAM_REPLICA_BUCKET" ] && \
	[ -n "$LITESTREAM_REPLICA_PATH" ] && \
	[ -n "$LITESTREAM_REPLICA_ENDPOINT" ] && \
	[ -n "$LITESTREAM_ACCESS_KEY_ID" ] && \
	[ -n "$LITESTREAM_SECRET_ACCESS_KEY" ]
}

# Restore the database if it does not already exist.
if use_litestream; then
    # Check if the database file exists.
    if [ -f "$DB_PATH" ]; then
    	# If the database exists, back it up to the backup directory.
    	echo "An old local database was found and will be backed up to the $BACKUP_DIR directory."
    	BACKUP_DIR="/var/opt/memos/.backup/$(date +'%Y-%m-%d_%H-%M-%S')"
    	mkdir -p "$BACKUP_DIR"
    	mv /var/opt/memos/memos_prod.db* "$BACKUP_DIR"
	fi
else
	# If the database does not exist, attempt to restore it from a replica.
	echo "No database found, attempt to restore from a replica."
	litestream restore -if-replica-exists "$DB_PATH"
	echo "Database restore completed!"

	# Run Litestream with the Memos service as the subprocess.
	echo "Starting litestream & memos service."
	exec litestream replicate -exec "./memos"
fi
