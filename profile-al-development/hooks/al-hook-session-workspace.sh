#!/usr/bin/env bash
# SessionStart hook: detects an AL project root and tells Claude to
# initialize bc-code-intelligence-mcp's workspace context for it.
#
# Hooks cannot call MCP tools directly — this only injects instructions
# into the session context; Claude must actually call set_workspace_info.
# Deliberately avoids jq (not guaranteed present on every synced machine);
# $CLAUDE_PROJECT_DIR is passed as an env var, no stdin JSON parsing needed.
set -euo pipefail

cat >/dev/null # drain stdin so the hook runner doesn't see a broken pipe

DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
while [[ "$DIR" != "/" ]]; do
    if [[ -f "$DIR/app.json" ]]; then
        cat <<EOF
AL project detected at $DIR (app.json present).
Before doing anything else this session, call the bc-code-intelligence-mcp
tool "set_workspace_info" with:
  workspace_root: "$DIR"
  available_mcps: ["al-mcp-server", "alcops", "bc-telemetry-buddy", "microsoft_docs_mcp"]
(list only the ones actually connected this session)
so BC specialist/knowledge tools have project context from the start.
EOF
        exit 0
    fi
    DIR=$(dirname "$DIR")
done

exit 0
