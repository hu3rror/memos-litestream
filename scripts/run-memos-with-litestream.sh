#!/bin/sh
set -e

# Check if the environment variables required for Litestream are set.
use_litestream() {
	# Check if all the required environment variables are set.
	[ -n "$LITESTREAM_REPLICA_BUCKET" ] &&
		[ -n "$LITESTREAM_REPLICA_PATH" ] &&
		[ -n "$LITESTREAM_REPLICA_ENDPOINT" ] &&
		[ -n "$LITESTREAM_ACCESS_KEY_ID" ] &&
		[ -n "$LITESTREAM_SECRET_ACCESS_KEY" ]
}

# Restore the database if it does not already exist.
if use_litestream; then
	# Check if the database file exists.
	if [ -f "$DB_PATH" ]; then
		# If the database exists, back it up to the backup directory.
		BACKUP_DIR="/var/opt/memos/.backup/$(date +'%Y-%m-%d_%H-%M-%S')"
		echo "An old local database was found and will be backed up to the $BACKUP_DIR directory."
		mkdir -p "$BACKUP_DIR"
		mv "$DB_PATH"* "$BACKUP_DIR"

		# Restore the database from the replica.
		if ! litestream restore -if-replica-exists "$DB_PATH"; then
			echo "Database restore from replica failed!"
			echo "Attempting to restore from $BACKUP_DIR..."
			mv "$BACKUP_DIR/*" "/var/opt/memos/" && rm -rf "$BACKUP_DIR"
			if ! [ -f "$DB_PATH" ]; then
				echo "Database restore from backup failed! Exiting..."
				exit 1
			fi
		fi
	fi
fi

# Run Litestream with the Memos service as the subprocess.
echo "Everything looks good. Starting litestream & memos service."
exec litestream replicate -exec "./memos"
