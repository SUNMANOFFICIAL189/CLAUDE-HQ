#!/usr/bin/env bash
# handoff secret gate — fail-closed single-file secret scan run BEFORE any HANDOFF write.
# The handoff doc is committed to git, so a leaked secret is permanent. This is a STRUCTURAL
# guard, not a writing convention (graft: mattpocock "keep it out of git" mindset).
#
# Usage:   secret-gate.sh <file>
# Exit:    0 = clean (or heuristic-warning only — allowed, warning printed)
#          1 = HIGH-CONFIDENCE secret found → caller MUST NOT write
#          2 = usage error / file missing → caller treats as fail-closed (do not write)
#
# High-confidence patterns mirror + broaden ~/claude-hq/scripts/lib/secret-scan.sh:SECRET_PATTERNS.
# Never echoes a secret value — only the line number + pattern name.
# LIMITATION (line-based): a secret WRAPPED across multiple lines (e.g. a JWT or a header-stripped
# PEM body split over several lines) is not detected. Callers must not paste multi-line credential
# blobs into a handoff at all (env-var NAMES only). NUL-bearing files are refused outright (below).

set -uo pipefail

FILE="${1:-}"
if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
  echo "secret-gate: no readable file to scan ('${FILE:-}')" >&2
  exit 2
fi

# FAIL-CLOSED on NUL bytes: grep classifies a file with any NUL as "binary" and returns NO match
# for every pattern (silent pass). A handoff must be text; refuse rather than scan-and-miss.
if ! LC_ALL=C tr -d '\000' < "$FILE" | cmp -s - "$FILE"; then
  echo "SECRET[binary]: file contains NUL bytes — cannot reliably scan; refusing (fail-closed)." >&2
  echo "secret-gate: BLOCK — a handoff must be plain text; remove binary/NUL content, then re-run." >&2
  exit 1
fi

# name|ERE  — high-confidence, structural. HARD FAIL (exit 1).
HIGH=(
  'openai|sk-[a-zA-Z0-9]{20,}'
  'anthropic|sk-ant-[a-zA-Z0-9_-]{20,}'
  'stripe-secret|(sk|rk)_(live|test)_[a-zA-Z0-9]{16,}'
  'stripe-webhook|whsec_[a-zA-Z0-9]{16,}'
  'github-pat|ghp_[a-zA-Z0-9]{30,}'
  'github-oauth|gho_[a-zA-Z0-9]{30,}'
  'github-server|ghs_[a-zA-Z0-9]{30,}'
  'github-finegrained|github_pat_[A-Za-z0-9_]{20,}'
  'aws-access|AKIA[0-9A-Z]{16}'
  'google-api|AIza[0-9A-Za-z_-]{35}'
  'slack|xox[baprs]-[0-9a-zA-Z-]{10,}'
  'private-key|-----BEGIN [A-Z ]*PRIVATE KEY-----'
  'jwt|eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{6,}'
  'url-inline-password|[a-zA-Z][a-zA-Z0-9+.-]*://[^/[:space:]:@]+:[^/[:space:]:@]+@'
)

# name|ERE — heuristic. WARN only (does not block). Requires a quoted value that does NOT
# start with $ { < ( or the word REDACTED/process.env — so env-var NAMES and placeholders pass.
HEUR=(
  'assigned-secret|(password|passwd|secret|token|api[_-]?key|access[_-]?key)["'"'"']?[[:space:]]*[:=][[:space:]]*["'"'"'][^"'"'"'${<][^"'"'"']{5,}["'"'"']'
)

found_high=0
for entry in "${HIGH[@]}"; do
  name="${entry%%|*}"; pat="${entry#*|}"
  # -n line numbers, -E ERE, -I skip binary; suppress the secret value from output.
  hits=$(grep -naE "$pat" "$FILE" 2>/dev/null | cut -d: -f1 | tr '\n' ' ')
  if [ -n "$hits" ]; then
    echo "SECRET[$name]: high-confidence match on line(s): $hits (value redacted)" >&2
    found_high=1
  fi
done

if [ "$found_high" -eq 1 ]; then
  echo "secret-gate: BLOCK — remove the secret (env-var NAMES only), then re-run." >&2
  exit 1
fi

for entry in "${HEUR[@]}"; do
  name="${entry%%|*}"; pat="${entry#*|}"
  hits=$(grep -naE "$pat" "$FILE" 2>/dev/null | cut -d: -f1 | tr '\n' ' ')
  if [ -n "$hits" ]; then
    echo "secret-gate: WARNING[$name]: possible inline secret on line(s): $hits — verify it is an env-var NAME, not a value." >&2
  fi
done

echo "secret-gate: clean ($FILE)"
exit 0
