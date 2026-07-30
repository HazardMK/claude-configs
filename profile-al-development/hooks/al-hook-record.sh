#!/usr/bin/env bash
# PostToolUse hook: records AL project roots when .al files are edited
# Reads tool call info from stdin as JSON, writes project root to queue file

set -euo pipefail

INPUT=$(cat)

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null) || SESSION_ID=""
QUEUE_FILE="/tmp/al-compile-queue-${USER}-${SESSION_ID:-default}"

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null) || FILE_PATH=""

[[ -z "$FILE_PATH" ]] && exit 0
[[ "$FILE_PATH" != *.al ]] && exit 0
[[ ! -e "$FILE_PATH" ]] && exit 0

# Walk up from file to find app.json
DIR=$(dirname "$(realpath "$FILE_PATH")")
while [[ "$DIR" != "/" ]]; do
    if [[ -f "$DIR/app.json" ]]; then
        echo "$DIR" >> "$QUEUE_FILE"
        exit 0
    fi
    DIR=$(dirname "$DIR")
done

exit 0
