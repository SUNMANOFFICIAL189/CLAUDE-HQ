#!/usr/bin/env bash
# Proof Gate v2 — minimal "Layer-3 watchdog" for the /proof-check discipline.
# Hardened 2026-06-10 after /proof-check on v1 found 2 CRITICAL bypasses.
#
# Roles (dispatched by tool):
#   • PostToolUse Edit|Write|MultiEdit|NotebookEdit — if a SECURITY-CRITICAL file
#     was changed, record it to ~/.claude/.proof-needed + remind.
#   • PreToolUse Bash — if security-critical work this session is NOT proof-checked,
#     BLOCK any push/merge (git push | git merge | gh pr merge | git branch -f main).
#     Rationale: a secret leaks via ANY push (not just to main), so when the flag is
#     set we block ALL pushes/merges — over-blocking is the SAFE direction. PROOF_OK=1
#     overrides; /proof-check clears the flag on a clean pass.
#
# Fixes vs v1: (C1) no longer relies on a literal "main" token — blocks all
# push/merge forms incl. `gh pr merge`, bare `git push`, `-u origin HEAD`. (C2)
# parse failure FAILS CLOSED for push-shaped raw input when the flag is set
# (was: silently allowed). Still fail-open for non-push commands (never bricks the loop).
#
# Exit: 0 = allow, 2 = block (stderr reason).
set -uo pipefail

FLAG="${PROOF_NEEDED_FILE:-$HOME/.claude/.proof-needed}"
LOG="${PROOF_GATE_LOG:-$HOME/claude-hq/scripts/.proof-gate.log}"
log() { echo "[proof-gate $(date +%H:%M:%S)] $*" >> "$LOG" 2>/dev/null || true; }

INPUT="$(cat)"; export INPUT

# Any push/merge form that could publish content to a remote (over-match = safe).
PUSH_RX='git[[:space:]].*push|git[[:space:]].*merge([[:space:]]|$)|gh[[:space:]].*pr[[:space:]].*merge|git[[:space:]].*branch[[:space:]].*-f.*(main|master)'

# Security-critical file paths whose edit requires a proof-check before any push.
# Anchored auth/token/guard to avoid AUTHORS.md / TokenList-style false positives;
# added money-path / migration / login / ssh-key categories (were missed in v1).
SEC_RX='secret|scrub|credential|password|passwd|\.env|vault|trust-gate|proof-gate|proof-check|model-router|session-end|session-start|settings\.json|/hooks/|risk-manager|position-lifecycle|wallet|api[_-]?key|\.pem$|\.key$|id_rsa|/migrations?/|[/._-]migration|payment|charge|billing|/login|(^|/|[._-])auth([./_-]|$)|(^|[/._-])token([/._-]|$)|(^|[/._-])guard([/._-]|$)|\.sql$'

parse() {
  python3 - <<'PY' 2>/dev/null
import json, os, sys
try: d = json.loads(os.environ.get("INPUT","") or "{}")
except Exception: d = {}
ti = d.get("tool_input") or {}
ti = ti if isinstance(ti, dict) else {}
out = [d.get("tool_name") or "", ti.get("file_path") or ti.get("notebook_path") or "", ti.get("command") or ""]
sys.stdout.buffer.write(b"\x00".join(s.encode("utf-8","replace") for s in out))
PY
}
TOOL=""; FP=""; CMD=""
{ IFS= read -r -d '' TOOL && IFS= read -r -d '' FP && IFS= read -r -d '' CMD; } < <(parse) || true

flag_set() { [[ -s "$FLAG" && "${PROOF_OK:-}" != "1" ]]; }
emit_block() {
  { echo "🛑 proof-gate BLOCK: security-critical changes this session are NOT proof-checked:"
    sed 's/^/    • /' "$FLAG" 2>/dev/null
    echo "Run  /proof-check  first (clears this gate on a clean pass), or re-run with  PROOF_OK=1  to override."
  } >&2
}

# CRITICAL-2: if parsing failed (empty TOOL) but the raw command looks like a
# push/merge and the flag is set, FAIL CLOSED rather than silently allow.
if [[ -z "$TOOL" ]]; then
  if flag_set && printf '%s' "$INPUT" | grep -qiE "$PUSH_RX"; then
    log "BLOCK (parse-failed, push-shaped raw input, flag set)"; emit_block; exit 2
  fi
  exit 0
fi

case "$TOOL" in
  Edit|Write|MultiEdit|NotebookEdit)
    if [[ -n "$FP" ]] && printf '%s' "$FP" | grep -qiE "$SEC_RX"; then
      mkdir -p "$(dirname "$FLAG")" 2>/dev/null || true
      if ! { [[ -f "$FLAG" ]] && grep -qxF "$FP" "$FLAG" 2>/dev/null; }; then
        echo "$FP" >> "$FLAG" 2>/dev/null || true
      fi
      log "flagged security-critical edit: $FP"
      echo "⚠️ proof-gate: security-critical file changed ($FP). Run /proof-check before pushing/merging." >&2
    fi
    exit 0
    ;;
  Bash)
    if printf '%s' "$CMD" | grep -qiE "$PUSH_RX"; then
      if flag_set; then
        log "BLOCKED push/merge — unproofed: $CMD"; emit_block; exit 2
      fi
      log "allow push/merge (flag empty or PROOF_OK=1): $CMD"
    fi
    exit 0
    ;;
  *)
    exit 0
    ;;
esac
