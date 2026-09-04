#!/usr/bin/env bash
# HQ Hermes pilot — T8 config renderer (bash + sed only, no other tools).
#
# Usage: render-config.sh {ollama|groq}
#   ollama -> fully resolves $SK/templates/config.yaml.tmpl and writes it
#             atomically (temp file + mv) to $HH/config.yaml.
#   groq   -> resolves BASE_URL/SECRETS_ENABLED/KEY_ENV_BLOCK for the Groq
#             arm but leaves @@MODEL@@ as the literal string @@GROQ_MODEL@@
#             (the real Groq model is chosen at T10 from live rate-limit
#             headers, not here) and writes atomically to
#             $SK/templates/config.groq.yaml.tmpl.pending -- it NEVER
#             touches $HH/config.yaml.
# Any other argument (including none, or more than one) exits 2.
#
# Never invoked with "groq" during T8 itself (PLAN v2.1l: "Do not render
# groq now") -- the branch exists for T10 to call once a live Groq model is
# selected through the T9 proxy.

set -euo pipefail

SK="/Users/sunil_rajput/claude-hq/run/pilot-tree/skills/hq-hermes"
HH="/Users/sunil_rajput/claude-hq/run/hermes-hq"
TMPL="$SK/templates/config.yaml.tmpl"

usage() {
    echo "usage: render-config.sh {ollama|groq}" >&2
}

if [ "$#" -ne 1 ]; then
    usage
    exit 2
fi

case "$1" in
    ollama)
        MODEL="hq-coder-64k"
        BASE_URL="http://127.0.0.1:11434/v1"
        SECRETS_ENABLED="false"
        KEY_ENV_BLOCK=""
        OUT="$HH/config.yaml"
        ;;
    groq)
        MODEL="@@GROQ_MODEL@@"
        BASE_URL="https://api.groq.com/openai/v1"
        SECRETS_ENABLED="true"
        KEY_ENV_BLOCK="providers:
  groq:
    base_url: \"https://api.groq.com/openai/v1\"
    key_env: \"GROQ_API_KEY\""
        OUT="$SK/templates/config.groq.yaml.tmpl.pending"
        ;;
    *)
        usage
        exit 2
        ;;
esac

if [ ! -f "$TMPL" ]; then
    echo "render-config.sh: template not found: $TMPL" >&2
    exit 2
fi

OUT_DIR="$(dirname "$OUT")"
mkdir -p "$OUT_DIR"

TMP_MAIN="$(mktemp "$OUT_DIR/.render-config.XXXXXX")"
KEYENV_FILE="$(mktemp "$OUT_DIR/.render-config-keyenv.XXXXXX")"
cleanup() {
    rm -f "$TMP_MAIN" "$KEYENV_FILE"
}
trap cleanup EXIT

# Single-line placeholders first (pipe delimiter -- BASE_URL contains slashes).
sed \
    -e "s|@@MODEL@@|${MODEL}|g" \
    -e "s|@@BASE_URL@@|${BASE_URL}|g" \
    -e "s|@@SECRETS_ENABLED@@|${SECRETS_ENABLED}|g" \
    "$TMPL" > "$TMP_MAIN"

# @@KEY_ENV_BLOCK@@ is a whole-line marker. Empty block -> delete the line.
# Non-empty block -> read its contents in after the marker line, then delete
# the marker line itself (classic sed r/d idiom -- no other tool needed).
if [ -z "$KEY_ENV_BLOCK" ]; then
    sed -e '/^@@KEY_ENV_BLOCK@@$/d' "$TMP_MAIN" > "$KEYENV_FILE"
else
    printf '%s\n' "$KEY_ENV_BLOCK" > "${KEYENV_FILE}.block"
    sed -e "/^@@KEY_ENV_BLOCK@@\$/{
r ${KEYENV_FILE}.block
d
}" "$TMP_MAIN" > "$KEYENV_FILE"
    rm -f "${KEYENV_FILE}.block"
fi

mv "$KEYENV_FILE" "$OUT"
chmod 600 "$OUT" 2>/dev/null || true

echo "$OUT"
