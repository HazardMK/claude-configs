---
name: install-status
description: Check whether the profile-al-development plugin's Windows install (prerequisites + all 4 installable MCP servers) is actually working. Use when the user asks to verify, check, or debug the plugin install, or reports an MCP server not working.
---

# /install-status — Installation Health Check

Runs the same `health-check.ps1` used by the Windows installer (`install/main.ps1`), so this
always reflects the real, currently-loaded install rather than a separate reimplementation.

## Procedure

1. Resolve the script path: `${CLAUDE_PLUGIN_ROOT}/install/health-check.ps1`. Note that
   `${CLAUDE_PLUGIN_ROOT}` points at the *installed cache copy* of the plugin — this is
   deliberate, the script itself always re-resolves the live `.mcp.json` from
   `~/.claude/plugins/cache/claude-configs/profile-al-development/<version>/.mcp.json`
   regardless of where it's invoked from.
2. Detect whether a Windows PowerShell runtime is available: try `powershell -NoProfile -Command "$PSVersionTable.PSVersion"` (or `pwsh` if `powershell` isn't found).
   - **If found:** run
     `powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/install/health-check.ps1"`
     via the Bash tool and show the output verbatim.
   - **If neither `powershell` nor `pwsh` is found:** this health check is Windows-specific by
     design (it validates `winget`-installed prerequisites and Windows-only paths like
     `BCDEVELOPMENTTOOLSPATH`). Tell the user plainly that the automated check only covers
     Windows, and point them at the plugin README's "MCP Server Configuration" and
     "Troubleshooting" sections for manual verification on this platform. Do not attempt to
     fabricate a substitute check.
3. Summarize the result for the user: which components PASS/WARN/FAIL/SKIP, and for any FAIL,
   the one-line remediation hinted at in the script's output (e.g. re-running the installer, or
   the specific README troubleshooting anchor).
4. `bc-telemetry-buddy` reporting `SKIP` is expected and not a problem — there is no public
   package for it, by design. Don't present it to the user as a failure.
