#!/usr/bin/env bash
# HQ Hermes pilot -- T8 secrets.command helper.
#
# Contract (Hermes secrets.command mechanism, cli-config.yaml.example):
# Hermes runs this command ONCE at startup and expects KEY=VALUE lines on
# stdout, which it merges into the process environment for provider api_key
# / key_env resolution. It must be fast (secrets.command.helper_timeout_seconds
# in config.yaml, set to 5 here) and it must never fail loudly for the
# "no secret configured" case -- absence is not an error.
#
# Behaviour:
#   - Groq key present in Keychain item "claude-hermes-groq" -> print exactly
#     one line: GROQ_API_KEY=<value>
#   - Item absent -> print nothing, exit 0 (Hermes then has no GROQ_API_KEY
#     and the custom/groq provider entry falls back per its own config)
#   - Never echoes anything else (no logging, no error text on stdout/stderr
#     that could be mistaken for a KEY=VALUE line); wall time budget <2s.

set -euo pipefail

SERVICE="claude-hermes-groq"
SECURITY_BIN="/usr/bin/security"

if VALUE="$("$SECURITY_BIN" find-generic-password -s "$SERVICE" -w 2>/dev/null)"; then
    printf 'GROQ_API_KEY=%s\n' "$VALUE"
fi

exit 0
