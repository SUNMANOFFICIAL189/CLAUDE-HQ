#!/usr/bin/env bash
# HQ Hermes pilot — T8b config renderer (bash + sed + a self-check python
# invocation, no other tools).
#
# Usage: render-config.sh {ollama|groq} [--model <name>]
#   ollama -> fully resolves $SK/templates/config.yaml.tmpl and writes it
#             atomically (temp file + mv) to $HH/config.yaml, where $HH is
#             $HERMES_HOME if set in the environment, else the pilot's real
#             HERMES_HOME. Rejects a --model argument (T7 already pinned the
#             Ollama model; it is never overridden here).
#   groq   -> resolves BASE_URL/SECRETS_ENABLED/KEY_ENV_BLOCK/@@MODEL@@ for
#             the Groq arm using the REQUIRED --model <name> argument (the
#             real Groq model is chosen at T10 from live rate-limit headers,
#             never hardcoded here) and writes atomically to $HH/config.yaml
#             ONLY -- the same $HH resolution as the ollama arm. It NEVER
#             writes $SK/templates/config.groq.yaml.tmpl.pending (HQ pilot
#             T8b fix for proof-check-s3-2026-09-04.md's MEDIUM-6: the old
#             groq branch wrote into that TRACKED path and never installed a
#             config at all).
#   Missing --model on the groq arm -> exit 2. Any other first argument
#   (including none, or more than one positional) -> exit 2.
#
# Self-check (C1b, proof-check-s3-2026-09-04.md CRITICAL fix): after every
# substitution pass and BEFORE the atomic mv, the rendered file must (1)
# contain zero unresolved @@ placeholders and (2) parse as YAML with
# terminal.backend == "docker", secrets.command.enabled a real bool, hooks a
# list/dict, and _config_version an int (H3). Any failure -> a message on
# stderr, exit 1, and the target file left UNCHANGED (the EXIT trap only
# ever removes this script's own temp files, never $OUT — the atomic mv is
# the last statement in the script, after both checks pass).
#
# TEMPLATE=<path> overrides the template file. Test-only escape hatch for
# proving the self-check can fail on a broken template without touching the
# real one; never used by a normal ollama/groq render.

set -euo pipefail

SK="/Users/sunil_rajput/claude-hq/run/pilot-tree/skills/hq-hermes"
HH="${HERMES_HOME:-/Users/sunil_rajput/claude-hq/run/hermes-hq}"
TMPL="${TEMPLATE:-$SK/templates/config.yaml.tmpl}"
PY="/Users/sunil_rajput/claude-hq/repos/hermes-agent/.venv/bin/python"

usage() {
    echo "usage: render-config.sh {ollama|groq} [--model <name>]" >&2
}

ARM="${1:-}"
shift || true

MODEL_ARG=""
if [ "$#" -gt 0 ]; then
    if [ "$1" = "--model" ] && [ "$#" -eq 2 ] && [ -n "$2" ]; then
        MODEL_ARG="$2"
    else
        usage
        exit 2
    fi
fi

case "$ARM" in
    ollama)
        if [ -n "$MODEL_ARG" ]; then
            usage
            exit 2
        fi
        MODEL="hq-coder-64k"
        BASE_URL="http://127.0.0.1:11434/v1"
        SECRETS_ENABLED="false"
        KEY_ENV_BLOCK=""
        ;;
    groq)
        if [ -z "$MODEL_ARG" ]; then
            usage
            exit 2
        fi
        MODEL="$MODEL_ARG"
        BASE_URL="https://api.groq.com/openai/v1"
        SECRETS_ENABLED="true"
        KEY_ENV_BLOCK="providers:
  groq:
    base_url: \"https://api.groq.com/openai/v1\"
    key_env: \"GROQ_API_KEY\""
        ;;
    *)
        usage
        exit 2
        ;;
esac

OUT="$HH/config.yaml"

if [ ! -f "$TMPL" ]; then
    echo "render-config.sh: template not found: $TMPL" >&2
    exit 2
fi

OUT_DIR="$(dirname "$OUT")"
mkdir -p "$OUT_DIR"

TMP_MAIN="$(mktemp "$OUT_DIR/.render-config.XXXXXX")"
TMP_FINAL="$(mktemp "$OUT_DIR/.render-config-final.XXXXXX")"
cleanup() {
    rm -f "$TMP_MAIN" "$TMP_FINAL"
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
    sed -e '/^@@KEY_ENV_BLOCK@@$/d' "$TMP_MAIN" > "$TMP_FINAL"
else
    KEYENV_BLOCK_FILE="$(mktemp "$OUT_DIR/.render-config-keyenv.XXXXXX")"
    trap 'rm -f "$TMP_MAIN" "$TMP_FINAL" "$KEYENV_BLOCK_FILE"' EXIT
    printf '%s\n' "$KEY_ENV_BLOCK" > "$KEYENV_BLOCK_FILE"
    sed -e "/^@@KEY_ENV_BLOCK@@\$/{
r ${KEYENV_BLOCK_FILE}
d
}" "$TMP_MAIN" > "$TMP_FINAL"
    rm -f "$KEYENV_BLOCK_FILE"
fi

# ---- C1b self-check: BEFORE the mv. $OUT is untouched by anything below;
# only $TMP_MAIN/$TMP_FINAL (cleaned up by the trap) are read or written. ----
PLACEHOLDER_COUNT="$(grep -c '@@' "$TMP_FINAL" || true)"
if [ "$PLACEHOLDER_COUNT" -ne 0 ]; then
    echo "render-config.sh: refusing to install -- $PLACEHOLDER_COUNT unresolved @@ placeholder(s) remain in the rendered file ($OUT left unchanged)" >&2
    exit 1
fi

if ! HERMES_HOME="$HH" "$PY" - "$TMP_FINAL" <<'PY'
import sys

import yaml

path = sys.argv[1]
with open(path, encoding="utf-8") as f:
    text = f.read()

try:
    d = yaml.safe_load(text)
except Exception as e:
    print(f"render-config.sh: rendered file failed to parse as YAML: {e}", file=sys.stderr)
    sys.exit(1)

errors = []
if not isinstance(d, dict):
    errors.append("top-level YAML is not a mapping")
else:
    if (d.get("terminal") or {}).get("backend") != "docker":
        errors.append('terminal.backend != "docker"')
    secrets_enabled = ((d.get("secrets") or {}).get("command") or {}).get("enabled")
    if not isinstance(secrets_enabled, bool):
        errors.append("secrets.command.enabled is not a real bool")
    if not isinstance(d.get("hooks"), (list, dict)):
        errors.append("hooks is not a list or dict")
    cfg_version = d.get("_config_version")
    if isinstance(cfg_version, bool) or not isinstance(cfg_version, int):
        errors.append("_config_version is not an int")

if errors:
    for e in errors:
        print(f"render-config.sh: self-check failed: {e}", file=sys.stderr)
    sys.exit(1)
PY
then
    echo "render-config.sh: self-check failed -- refusing to install $OUT ($OUT left unchanged)" >&2
    exit 1
fi

mv "$TMP_FINAL" "$OUT"
chmod 600 "$OUT" 2>/dev/null || true

echo "$OUT"
