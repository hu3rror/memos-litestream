#!/bin/sh
set -e

use_memogram() {
	[ -f "./memogram" ] && \
	[ -f "./.env" ]
}

if use_memogram; then
	# Replace the MEMOGRAM_BOT_TOKEN placeholder in the .env file with the actual token value.
	if [ -n "$MEMOGRAM_BOT_TOKEN" ]; then
		sed -i 's/<MEMOGRAM_BOT_TOKEN>/'"$MEMOGRAM_BOT_TOKEN"'/g' ./.env
	fi

	# If the MEMOS_PORT environment variable is not set to the default value, replace it in the .env file.
	if [ "$MEMOS_PORT" != "5230" ]; then
		sed -i 's/5230/'"$MEMOS_PORT"'/g' ./.env
	fi

	# Start the memogram service.
	echo "Starting memogram service."
	exec ./memogram
fi
