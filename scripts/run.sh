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

# Replace MEMOGRAM_BOT_TOKEN in .env
if [ -f "./memogram" ] && [ -f "./.env" ] && [ -n "$MEMOGRAM_BOT_TOKEN" ]; then
	# Replace MEMOGRAM_BOT_TOKEN in .env
	sed -i 's/<MEMOGRAM_BOT_TOKEN>/'"$MEMOGRAM_BOT_TOKEN"'/g' ./.env

	# Replace MEMOS_PORT in .env
	if [ "$MEMOS_PORT" != "5230" ]; then
		sed -i 's/5230/'"$MEMOS_PORT"'/g' ./.env
	fi
fi

# Run litestream with your app as the subprocess.
echo "Starting litestream & memos service."
exec litestream replicate -exec "./memos"
