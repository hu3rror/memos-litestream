#!/bin/sh
set -e

# Restore the database if it does not already exist.
if [ -f "$DB_PATH" ]; then
	echo "Database exists, skipping restore."
else
	echo "No database found, attempt to restore from a replica."
	litestream restore -if-replica-exists "$DB_PATH"
	echo "Finished restoring the database."
fi

# Run litestream with your app as the subprocess.
echo "Starting litestream & memos service."
exec litestream replicate -exec "./memos"
