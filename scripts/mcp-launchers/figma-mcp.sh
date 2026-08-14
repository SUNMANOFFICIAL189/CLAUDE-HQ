#!/usr/bin/env bash
# Launcher for figma-developer-mcp — fetches FIGMA_API_KEY from Keychain at spawn time.
# Pattern: per LESSONS.md rules 14-15, the secret never appears in any config file.
# The MCP registration points here; this launcher pulls the token fresh from
# Keychain on every server start. --stdio is REQUIRED (defaults to HTTP otherwise).
set -euo pipefail

SECRET=$(security find-generic-password -a "$USER" -s "claude-mcp-figma-api-key" -w 2>/dev/null) || {
  cat >&2 <<EOF
[figma-mcp-launcher] Keychain entry 'claude-mcp-figma-api-key' not found.

To set the key (one time):
  security add-generic-password -U -a "\$USER" -s claude-mcp-figma-api-key -w <YOUR_FIGMA_TOKEN>

Then start a new Claude session.
EOF
  exit 1
}

export FIGMA_API_KEY="$SECRET"
exec npx -y figma-developer-mcp@0.13.2 --figma-api-key="$FIGMA_API_KEY" --stdio
