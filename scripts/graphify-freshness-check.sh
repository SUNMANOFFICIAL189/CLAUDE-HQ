#!/usr/bin/env bash
# Weekly graphify freshness check — BACKLOG graphify follow-up #2 (2026-06-25).
#
# Detects how many docs have drifted since the last knowledge-graph build and, if
# enough have changed, NUDGES (macOS notification + log) to run `/graphify --update`
# in a Claude session.
#
# It deliberately does NOT auto-run semantic extraction: that step needs a Claude
# session (subagents) and would auto-burn tokens every week — the exact 2026-04-28
# quota-incident pattern. Code changes are already auto-refreshed for free by the
# post-commit hook (AST) + the session-end hook (vault re-export); this job only
# covers DOC drift, which is the part that needs a deliberate, cost-gated refresh.
#
# Cost: ~$0 (detection only, no LLM). Fail-safe: never errors out the schedule.
set -uo pipefail

HQ="$HOME/claude-hq"
ROOT="$HQ"                              # absolute root — MUST match the manifest's path form
LOG="$HQ/run/graphify-freshness.log"
DOC_THRESHOLD="${DOC_THRESHOLD:-3}"     # nudge when this many docs (or more) have drifted
mkdir -p "$HQ/run"
TS=$(date '+%Y-%m-%d %H:%M')

# Need a built graph + the resolved interpreter; if absent, log and bail (don't error).
if [ ! -f "$HQ/graphify-out/.graphify_python" ] || [ ! -f "$HQ/graphify-out/graph.json" ]; then
  echo "[$TS] skipped — no graph built yet" >> "$LOG"
  exit 0
fi
PY=$(cat "$HQ/graphify-out/.graphify_python")

# Detect drift (free, no LLM). Run from $HQ so the relative manifest path resolves.
COUNTS=$(cd "$HQ" && "$PY" - "$ROOT" <<'PYEOF' 2>/dev/null
import sys, json
from pathlib import Path
from graphify.detect import detect_incremental
try:
    r = detect_incremental(Path(sys.argv[1]))
    nf = r.get('new_files', {}) or {}
    docs = sum(len(nf.get(k, [])) for k in ('document', 'paper', 'image'))
    code = len(nf.get('code', []))
    deleted = len(r.get('deleted_files', []))
    print(f"{docs} {code} {deleted}")
except Exception as e:
    print(f"ERR {e}")
PYEOF
)

if [[ "$COUNTS" == ERR* ]]; then
  echo "[$TS] detect failed: ${COUNTS#ERR }" >> "$LOG"
  exit 0
fi

read -r DOCS CODE DELETED <<< "$COUNTS"
echo "[$TS] drift since last graph build — docs:${DOCS:-?} code:${CODE:-?} deleted:${DELETED:-?}" >> "$LOG"

if [ "${DOCS:-0}" -ge "$DOC_THRESHOLD" ] || [ "${DELETED:-0}" -ge "$DOC_THRESHOLD" ]; then
  echo "[$TS] NUDGE: $DOCS doc(s) changed — to refresh: open Claude Code and run /graphify --update (manual; will NOT auto-run)" >> "$LOG"
  # Plain-English nudge via macOS notification (no credentials, $0, local).
  # Spells out the manual steps — the refresh does NOT run on its own.
  osascript -e "display notification \"${DOCS} docs changed. To refresh: open Claude Code, then run /graphify --update. It will not run by itself.\" with title \"HQ knowledge graph is stale — manual refresh needed\"" 2>/dev/null || true
fi
exit 0
