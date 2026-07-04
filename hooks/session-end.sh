#!/bin/bash
# Layer 4+5: Fires on every Claude Code session end
# Stores session summary in Hindsight + mines project into MemPalace

HINDSIGHT_URL="${HINDSIGHT_URL:-http://localhost:8888}"

BRANCH=""
LAST_COMMIT=""
PROJECT_DIR=""
if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  BRANCH=$(git branch --show-current 2>/dev/null)
  LAST_COMMIT=$(git log -1 --pretty='%s' 2>/dev/null)
  PROJECT_DIR=$(git rev-parse --show-toplevel 2>/dev/null)
fi

CONTENT="Session ended $(date). Branch: ${BRANCH:-none}. Last commit: ${LAST_COMMIT:-none}."

# --- Layer 4: Hindsight recall ---
JSON_BODY=$(python3 -c "
import json, sys
print(json.dumps({'items': [{'content': sys.argv[1]}]}))
" "$CONTENT" 2>/dev/null)

if [ -n "$JSON_BODY" ]; then
  curl -sf -X POST "$HINDSIGHT_URL/v1/default/banks/claude-sessions/memories" \
    -H 'Content-Type: application/json' \
    -d "$JSON_BODY" \
    2>/dev/null
fi

# --- Layer 5: MemPalace auto-mine ---
# Safety hardening (added 2026-05-08 after chroma segment_id drift incident):
#   1. Precheck — abort if palace shows corruption signatures (orphan
#      embeddings, on-disk UUID dirs without segments, stuck queue)
#   2. Lockfile — only one mine ever runs at a time across all sessions,
#      preventing concurrent-write corruption
#   3. nohup + setsid — mine survives parent shell exit so it can't be
#      SIGKILL'd mid-write when Terminal closes
# Recovery runbook for future incidents: ~/claude-hq/docs/mempalace-corruption-runbook.md
if [ -n "$PROJECT_DIR" ]; then
  if [ ! -f "$PROJECT_DIR/mempalace.yaml" ]; then
    mempalace init --yes "$PROJECT_DIR" > /dev/null 2>&1
  fi
  PRECHECK="$HOME/claude-hq/scripts/mempalace-precheck.py"
  MINE_LOCK="$HOME/.mempalace/.mine.lock"
  MINE_LOG="$HOME/.mempalace/mine.log"
  # Pre-check first; only proceed if palace is healthy.
  if [ -x "$PRECHECK" ] && python3 "$PRECHECK" >> "$MINE_LOG" 2>&1; then
    # Atomic lock acquire via noclobber. If another mine is running, skip
    # rather than queue — keeps idempotent and concurrency-safe.
    # nohup makes the mine ignore SIGHUP when Terminal closes; disown removes
    # it from this shell's job table. Together they survive parent exit on
    # macOS without needing setsid (which isn't installed by default).
    (
      if ( set -o noclobber; echo "$$" > "$MINE_LOCK" ) 2>/dev/null; then
        trap 'rm -f "$MINE_LOCK"' EXIT
        nohup mempalace mine "$PROJECT_DIR" >> "$MINE_LOG" 2>&1
      fi
    ) &
    disown 2>/dev/null || true
  fi
fi

# --- Layer 6: graphify Obsidian re-export ---
# If a graph already exists for this project, re-export to Obsidian vault.
# Lightweight — no LLM extraction, just re-exports the existing graph.
# Canonical target: JARVIS-BRAIN/Projects/<project>/Graph/  (per ~/claude-hq/docs/ORGANIZATION.md)
OBSIDIAN_VAULT="$HOME/Vaults/Jarvis-Brain/JARVIS-BRAIN"
VAULT_ROOT="$HOME/Vaults/Jarvis-Brain"
if [ -n "$PROJECT_DIR" ] && [ -f "$PROJECT_DIR/graphify-out/graph.json" ]; then
  PROJECT_NAME=$(basename "$PROJECT_DIR")
  GRAPHIFY_PYTHON="python3"
  if [ -f "$PROJECT_DIR/graphify-out/.graphify_python" ]; then
    GRAPHIFY_PYTHON=$(cat "$PROJECT_DIR/graphify-out/.graphify_python")
  fi
  "$GRAPHIFY_PYTHON" -c "
import json, sys
from pathlib import Path
try:
    from graphify.build import build_from_json
    from graphify.export import to_obsidian, to_canvas
    from networkx.readwrite import json_graph
    import networkx as nx

    graph_path = Path('$PROJECT_DIR/graphify-out/graph.json')
    data = json.loads(graph_path.read_text())
    G = json_graph.node_link_graph(data, edges='links')

    labels_path = Path('$PROJECT_DIR/graphify-out/.graphify_labels.json')
    labels = {}
    if labels_path.exists():
        labels = {int(k): v for k, v in json.loads(labels_path.read_text()).items()}

    communities = {}
    for n, d in G.nodes(data=True):
        c = d.get('community', 0)
        communities.setdefault(c, []).append(n)

    # Canonical per-project Graph/ folder (NOT vault root — see docs/ORGANIZATION.md)
    obsidian_dir = '$OBSIDIAN_VAULT/Projects/$PROJECT_NAME/Graph'
    Path(obsidian_dir).mkdir(parents=True, exist_ok=True)
    to_obsidian(G, communities, obsidian_dir, community_labels=labels or None)
    to_canvas(G, communities, f'{obsidian_dir}/graph.canvas', community_labels=labels or None)
except Exception as e:
    # Was a silent 'pass' — re-export failures were invisible. Fixed 2026-06-25
    # (BACKLOG graphify follow-up #1): record the failure so a broken vault
    # re-export surfaces, while still never blocking session end.
    import traceback, datetime
    try:
        _log = Path('$PROJECT_DIR/graphify-out/graphify-export-errors.log')
        with _log.open('a') as _fh:
            _fh.write('[' + datetime.datetime.now().isoformat() + '] graphify vault re-export FAILED: ' + repr(e) + '\n')
            _fh.write(traceback.format_exc() + '\n')
    except Exception:
        pass  # logging itself must never block session end
" > /dev/null 2>&1 &
fi

# --- Handoff mechanical backstop: record a last-session marker beside the canonical HANDOFF ---
# A bash hook has no LLM, so it CANNOT write the rich handoff. It leaves only a mechanical trail
# (git delta) BESIDE the doc so the next resume knows a session happened and whether it was
# rich-checkpointed. It NEVER edits HANDOFF.md — that stays single-writer (the /handoff skill).
HANDOFF_LOCATE="$HOME/.claude/skills/handoff/scripts/locate.sh"
HANDOFF_GATE="$HOME/.claude/skills/handoff/scripts/secret-gate.sh"
if [ -x "$HANDOFF_LOCATE" ]; then
  HO=$(bash "$HANDOFF_LOCATE" 2>/dev/null | head -1)
  if [ "${HO%% *}" = "CANONICAL" ]; then
    HO_PATH="${HO#CANONICAL }"
    if [ -f "$HO_PATH" ]; then
      MOD_COUNT=$(git status --short 2>/dev/null | wc -l | tr -d ' ')
      MARK="$(dirname "$HO_PATH")/.handoff-last-session"
      TMP="$MARK.tmp.$$"
      {
        echo "# mechanical last-session marker (auto, UNCONFIRMED) — the rich handoff is HANDOFF.md"
        echo "ended: $(date '+%F %H:%M')"
        echo "branch: ${BRANCH:-none}"
        echo "last_commit: ${LAST_COMMIT:-none}"
        echo "uncommitted_changes: ${MOD_COUNT:-0}"
        echo "note: if this is newer than HANDOFF.md 'Last refreshed', the last session was NOT rich-checkpointed — reconstruct from git + code, then run /handoff save."
      } > "$TMP" 2>/dev/null
      # secret-gate the marker before it lands (a commit subject could in theory carry a secret)
      if [ -x "$HANDOFF_GATE" ] && bash "$HANDOFF_GATE" "$TMP" >/dev/null 2>&1; then
        mv -f "$TMP" "$MARK" 2>/dev/null
      else
        rm -f "$TMP" 2>/dev/null
      fi
    fi
  fi
fi

# --- Layer 6.5: Secret scrubber (INCREMENTAL — scrubs only content NEW since the
# last run, watermarked, so it finishes in ~0.02s inside the SessionEnd budget
# instead of being killed mid-scan ~94% of the time). Redacts secret-shaped
# strings from new CC transcripts (~/.claude/projects/**) + new claude-mem DB
# rows, detects in MemPalace, and writes a .scrub-halt sentinel if the vault
# still contains secrets. LOCAL disk only — cannot reach Anthropic backend logs.
# Full re-scan: rm ~/claude-hq/run/scrub-state.json then run it.
# Legacy full scrubber still available at scripts/lib/secret-scrub.sh.
SCRUB_INCR="$HOME/claude-hq/scripts/lib/secret-scrub-incremental.py"
if [ -f "$SCRUB_INCR" ]; then
  # FAIL-CLOSED: raise the push gate BEFORE scrubbing. The scrubber lowers it only
  # on a proven-clean pass; if it crashes / python is missing / it's SIGKILLed, the
  # sentinel stays and Layer 7 below refuses to push. Guard defaults to BLOCK.
  [ -d "$VAULT_ROOT/.git" ] && : > "$VAULT_ROOT/.scrub-halt"
  python3 "$SCRUB_INCR" > /dev/null 2>&1
fi

# --- Layer 7: Obsidian vault git backup (auto-commit + push) ---
# Vault is a private git repo at github.com/SUNMANOFFICIAL189/jarvis-brain
# Auto-commit every session so knowledge is never at single-disk risk.
# Silent: runs in background, doesn't block session end, doesn't surface errors.
# Refuses to push if the scrubber left a .scrub-halt sentinel in the vault.
if [ -d "$VAULT_ROOT/.git" ] && [ ! -f "$VAULT_ROOT/.scrub-halt" ]; then
  (
    cd "$VAULT_ROOT" || exit 0
    # Only commit if there are changes (tracked changes or new untracked files)
    if ! git diff --quiet HEAD 2>/dev/null || [ -n "$(git ls-files --others --exclude-standard 2>/dev/null)" ]; then
      git add -A > /dev/null 2>&1
      git commit -q -m "Session $(date '+%F %H:%M')" > /dev/null 2>&1
      git push -q origin main > /dev/null 2>&1
    fi
  ) &
fi

exit 0
