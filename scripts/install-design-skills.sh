#!/usr/bin/env bash
# Tier C install for two external design skills, vendored into claude-hq/tools/.
# Reuses the canonical gate libraries (advisory / magika / secret / socket).
# Non-standard repo layouts (impeccable: skill/SKILL.src.md + plugin; taste-skill:
# multiple skills under skills/) mean the generic skill-install.sh can't place them,
# so this script does the same scan layers and vendors into the design-skill cluster.
#
# Usage: install-design-skills.sh
# Exit: 0 = both vendored clean; non-zero = at least one blocked (nothing installed for it)

set -uo pipefail

HQ_ROOT="${HQ_ROOT:-/Users/sunil_rajput/claude-hq}"
LIB="$HQ_ROOT/scripts/lib"
LOG="$HQ_ROOT/scripts/.trust-gate.log"
TOOLS="$HQ_ROOT/tools"

source "$LIB/advisory-check.sh"
source "$LIB/magika-core.sh"
source "$LIB/secret-scan.sh"
source "$LIB/socket-core.sh"

# The sourced libs each run `set -euo pipefail`; -e would abort this script the
# moment a gate function returns non-zero (e.g. advisory UNKNOWN=2) before we can
# capture $?. Disable -e here and rely on explicit rc capture (same as skill-install.sh).
set +e

log() { echo "[design-skills $(date +%H:%M:%S)] $*" | tee -a "$LOG"; }

# repo-owner/name  ->  vendored dir name
REPOS=(
  "pbakaus/impeccable=impeccable"
  "Leonxlnx/taste-skill=taste-skill"
)

OVERALL_RC=0

for entry in "${REPOS[@]}"; do
  OWNER_REPO="${entry%%=*}"
  VDIR="${entry##*=}"
  echo ""
  echo "════════════════════════════════════════════════════════"
  echo "  TIER C: $OWNER_REPO  →  tools/$VDIR"
  echo "════════════════════════════════════════════════════════"
  log "START $OWNER_REPO"

  STAGING="$(mktemp -d /tmp/design-skill-XXXXXX)"
  export TRUST_GATE_TMP="$STAGING/reports"
  mkdir -p "$TRUST_GATE_TMP"

  # ---- Layer 0.5: advisory / cooling-off ----
  advisory_check "$OWNER_REPO"
  adv_rc=$?
  if [[ "$adv_rc" == "1" ]]; then
    log "BLOCK: cooling-off active for $OWNER_REPO"
    echo "❌ BLOCKED: $OWNER_REPO in cooling-off."
    rm -rf "$STAGING"; OVERALL_RC=1; continue
  fi
  # adv_rc=2 (UNKNOWN) is expected for these authors → full Tier C continues.

  # ---- Clone (URL built from var; depth 1) ----
  if ! git clone --depth 1 "https://github.com/$OWNER_REPO.git" "$STAGING/src" 2>"$STAGING/clone.err"; then
    log "ERROR clone failed $OWNER_REPO"; cat "$STAGING/clone.err"
    echo "❌ clone failed for $OWNER_REPO"
    rm -rf "$STAGING"; OVERALL_RC=1; continue
  fi

  # ---- Layer 1: Magika ----
  magika_scan "$STAGING/src"; magika_rc=$?
  # ---- Layer 2: secret / prompt-injection ----
  secret_scan "$STAGING/src"; secret_rc=$?

  # ---- Layer 3: Socket (only if npm manifest) ----
  socket_rc=0; socket_note="n/a (no package.json)"
  if [[ -f "$STAGING/src/package.json" ]]; then
    if socket_scan_npm "$STAGING/src" 2>"$STAGING/socket.err"; then
      socket_rc=0; socket_note="PASS"
    else
      socket_rc=$?
      # Distinguish a real finding from an auth/network failure (fail-closed in lib).
      if grep -qiE "scan failed|not installed|unauthor|forbidden|login|token|network" "$STAGING/socket.err"; then
        socket_rc=99; socket_note="INCOMPLETE (socket could not run — manual dep review required)"
      else
        socket_note="FAIL (high/critical issue)"
      fi
    fi
  fi

  echo ""
  echo "  Layer results for $OWNER_REPO:"
  echo "    advisory : $([ $adv_rc -eq 0 ] && echo ALLOWLISTED || echo 'UNKNOWN→full-scan')"
  echo "    magika   : $([ $magika_rc -eq 0 ] && echo PASS || echo FAIL)"
  echo "    secret   : $([ $secret_rc -eq 0 ] && echo PASS || echo FAIL)"
  echo "    socket   : $socket_note"

  # ---- Decision: hard-block on magika or secret fail, or real socket fail ----
  if [[ "$magika_rc" != "0" || "$secret_rc" != "0" || ( "$socket_rc" != "0" && "$socket_rc" != "99" ) ]]; then
    log "BLOCK $OWNER_REPO magika=$magika_rc secret=$secret_rc socket=$socket_rc"
    echo "❌ NOT INSTALLED: $OWNER_REPO failed a hard gate. Reports in $TRUST_GATE_TMP"
    echo "   (staging kept for review: $STAGING)"
    OVERALL_RC=1; continue
  fi

  if [[ "$socket_rc" == "99" ]]; then
    log "WARN socket incomplete for $OWNER_REPO — dumping dependency manifest for manual review"
    echo ""
    echo "  ⚠️  Socket incomplete. Dependency manifest for manual review:"
    python3 -c "import json,sys; d=json.load(open('$STAGING/src/package.json')); print('    deps:', json.dumps(d.get('dependencies',{}),indent=6)); print('    devDeps:', json.dumps(d.get('devDependencies',{}),indent=6))" 2>/dev/null || echo "    (could not parse package.json)"
  fi

  # ---- Vendor into tools/ (strip .git so it isn't an embedded repo) ----
  mkdir -p "$TOOLS"
  rm -rf "$TOOLS/$VDIR"
  cp -R "$STAGING/src" "$TOOLS/$VDIR"
  rm -rf "$TOOLS/$VDIR/.git"
  log "VENDORED $OWNER_REPO → tools/$VDIR"
  echo "  ✅ vendored → tools/$VDIR"

  rm -rf "$STAGING"
done

echo ""
echo "════════════════════════════════════════════════════════"
echo "  DONE (overall rc=$OVERALL_RC)"
echo "════════════════════════════════════════════════════════"
exit $OVERALL_RC
