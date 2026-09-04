#!/usr/bin/env bash
# HQ Hermes pilot -- one-time Keychain setup for the Groq key (reproducibility
# only). PLAN v2 §2 operator step 1. DO NOT run this from a ticket/agent --
# the Keychain item "claude-hermes-groq" already exists on this Mac; this
# script exists so the setup step is documented and reproducible if the item
# ever needs to be recreated (new Mac, rotated key, etc.). It is a plain,
# interactive, operator-run script -- it is never invoked by Hermes or by any
# pilot automation.
#
# Usage (operator, interactively, at a real TTY):
#   bash hermes-keychain-setup.sh

set -euo pipefail

SERVICE="claude-hermes-groq"
SECURITY_BIN="/usr/bin/security"

echo "HQ Hermes pilot -- Groq API key Keychain setup"
echo "Service name: $SERVICE"
echo "Paste your Groq API key (console.groq.com) -- input is hidden, nothing is echoed:"

read -r -s KEY
echo

if [ -z "$KEY" ]; then
    echo "No key entered -- aborting, nothing written." >&2
    exit 1
fi

"$SECURITY_BIN" add-generic-password -a "$USER" -s "$SERVICE" -w "$KEY" -T /usr/bin/security -U

unset KEY

echo "Stored in Keychain item '$SERVICE'. Verify with:"
echo "  bash \$SK/scripts/hermes-secrets.sh"
echo "(that command only prints GROQ_API_KEY=<value> -- redact before pasting anywhere)"
