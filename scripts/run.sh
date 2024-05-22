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

# Backup the database to a specified directory.
backup_database() {
	BACKUP_DIR="/var/opt/memos/.backup/$(date +'%Y-%m-%d_%H-%M-%S')"
	echo "Backing up the database to $BACKUP_DIR directory."
	mkdir -p "$BACKUP_DIR"
	mv "$DB_PATH"* "$BACKUP_DIR"
}

# Restore the database from the replica or backup.
restore_database() {
	litestream restore -if-replica-exists "$DB_PATH"
	if [ $? -ne 0 ]; then
		echo "Database restore from replica failed!"
		echo "Attempting to restore from backup..."
		mv "$BACKUP_DIR/*" "/var/opt/memos/" && rm -rf "$BACKUP_DIR"
		if ! [ -f "$DB_PATH" ]; then
			echo "Database restore from backup failed! Exiting..."
			exit 1
		fi
	fi
}

# Main script logic
if check_litestream_env; then
	if [ -f "$DB_PATH" ]; then
		backup_database
		restore_database
	else
		restore_database
	fi
fi

# Start Litestream with the Memos service as the subprocess.
echo "Starting litestream & memos service."
exec litestream replicate -exec "./memos"