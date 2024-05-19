#!/bin/sh
set -e

# Replace MEMOGRAM_BOT_TOKEN in .env
if [ -f "./memogram" ] && [ -f "./.env" ] && [ -n "$MEMOGRAM_BOT_TOKEN" ]; then
	# Replace MEMOGRAM_BOT_TOKEN in .env
	sed -i 's/<MEMOGRAM_BOT_TOKEN>/'"$MEMOGRAM_BOT_TOKEN"'/g' ./.env

	# Replace MEMOS_PORT in .env
	if [ "$MEMOS_PORT" != "5230" ]; then
		sed -i 's/5230/'"$MEMOS_PORT"'/g' ./.env
	fi

    # Run memogram
    echo "Starting memogram service."
    exec ./memogram
fi