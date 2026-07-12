#!/bin/bash
# Layer 3+4: Fires on every Claude Code session start
# Injects git context + Hindsight behavioral patterns

HINDSIGHT_URL="${HINDSIGHT_URL:-http://localhost:8888}"

echo "## Live Context (auto-injected)"
echo ""

# --- Metered-model guard: warn if the default session model bills per-token ---
# Fable 5 left Max flat-rate coverage ~2026-07-13 ($10/M in, $50/M out). MODEL_ROUTING.md §5.5.
SETTINGS_MODEL=$(grep -o '"model"[[:space:]]*:[[:space:]]*"[^"]*"' "$HOME/.claude/settings.json" 2>/dev/null | head -1)
if echo "$SETTINGS_MODEL" | grep -qi "fable"; then
  echo "### ⚠️ METERED MODEL WARNING"
  echo "Your default session model is Fable 5, which bills per-token (\$10/M in, \$50/M out) — not covered by the Max subscription. Unless this is deliberate, switch with /model to Opus 4.8. Doctrine: commander/MODEL_ROUTING.md §5.5."
  echo ""
fi

# --- Layer 3: Git context ---
if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo "### Git Status"
  echo "**Branch:** $(git branch --show-current 2>/dev/null)"
  echo "**Last 5 commits:**"
  git log --oneline -5 2>/dev/null
  echo ""
  MODIFIED=$(git status --short 2>/dev/null)
  if [ -n "$MODIFIED" ]; then
    echo "**Modified files:**"
    echo "$MODIFIED"
    echo ""
  fi
  REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
  if [ -f "$REPO_ROOT/.claude-memory.md" ]; then
    echo "**Recent commit log:**"
    tail -10 "$REPO_ROOT/.claude-memory.md"
    echo ""
  fi
fi

# --- Handoff surface: auto-detect this project's canonical HANDOFF and show where you left off ---
# Read-only. Only surfaces when a real handoff exists (no noise on fresh dirs). Never blocks start.
HANDOFF_LOCATE="$HOME/.claude/skills/handoff/scripts/locate.sh"
if [ -x "$HANDOFF_LOCATE" ]; then
  HO_OUT=$(bash "$HANDOFF_LOCATE" 2>/dev/null | head -1)
  HO_KIND=$(echo "$HO_OUT" | cut -d' ' -f1)
  HO_PATH=$(echo "$HO_OUT" | cut -d' ' -f2-)
  if [ "$HO_KIND" = "CANONICAL" ] && [ -f "$HO_PATH" ]; then
    echo "### 📋 Handoff found — run \`/handoff\` to resume (code wins on any doc-vs-code conflict)"
    grep -m1 '^- Last refreshed:' "$HO_PATH" 2>/dev/null
    GOAL=$(awk '/^## Goal/{g=1;next} g&&NF{print;exit}' "$HO_PATH" 2>/dev/null)
    [ -n "$GOAL" ] && echo "**Goal:** $GOAL"
    NEXT=$(grep -m1 '⭐' "$HO_PATH" 2>/dev/null | sed 's/^[0-9]*\.[[:space:]]*//')
    [ -z "$NEXT" ] && NEXT=$(grep -m1 'NEXT (operator' "$HO_PATH" 2>/dev/null | sed 's/^[0-9]*\.[[:space:]]*//')
    [ -n "$NEXT" ] && echo "**Next:** $NEXT"
    MARK="$(dirname "$HO_PATH")/.handoff-last-session"
    if [ -f "$MARK" ] && [ "$MARK" -nt "$HO_PATH" ]; then
      echo "⚠ A session ran after the last saved handoff — it may not be fully checkpointed; reconstruct from git + code before trusting the doc."
    fi
    echo ""
  elif [ "$HO_KIND" = "UNREACHABLE" ]; then
    echo "### 📋 Handoff unreachable"
    echo "Your handoff is at \`$HO_PATH\` but its drive isn't mounted. Mount it, then run \`/handoff\`."
    echo ""
  fi
fi

# --- Layer 4: Hindsight recall ---
RECALL_JSON=$(curl -sf -X POST "$HINDSIGHT_URL/v1/default/banks/claude-sessions/memories/recall" \
  -H 'Content-Type: application/json' \
  -d '{"query": "behavioral patterns, corrections, and preferences for Claude Code sessions"}' \
  2>/dev/null)

if [ -n "$RECALL_JSON" ] && [ "$RECALL_JSON" != "null" ]; then
  PATTERNS=$(echo "$RECALL_JSON" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    seen = set()
    for r in data.get('results', []):
        t = r.get('text', '')
        if t and t not in seen:
            seen.add(t)
            print(f'- {t}')
except: pass
" 2>/dev/null)

  if [ -n "$PATTERNS" ]; then
    echo "### Hindsight Behavioral Patterns"
    echo "$PATTERNS"
    echo ""
  fi
fi

exit 0
