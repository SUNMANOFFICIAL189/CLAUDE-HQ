#!/usr/bin/env bash
# fable-spend.sh — Fable 5 metered-dispatch visibility from the routing ledger.
# Read-only. Counts DECISIONS, not tokens (cost columns are unpopulated — BACKLOG).
# Estimate basis: curated-brief soft cap from MODEL_ROUTING.md §5.5 (~30k in / ~4k out
# ≈ $0.50/dispatch at $10/$50 per MTok). Real spend can differ — check the billing page.

set -uo pipefail

LEDGER="${HQ_ROOT:-$HOME/claude-hq}/run/cost-ledger.sqlite"
EST_PER_DISPATCH=0.50

if [[ ! -f "$LEDGER" ]]; then
  echo "No ledger at $LEDGER — nothing to report."
  exit 0
fi

q() { sqlite3 -readonly "$LEDGER" "$1"; }

f7=$(q "SELECT count(*) FROM routing_decisions WHERE model_chosen='fable' AND datetime(ts) >= datetime('now','-7 days');")
f30=$(q "SELECT count(*) FROM routing_decisions WHERE model_chosen='fable' AND datetime(ts) >= datetime('now','-30 days');")
d7=$(q "SELECT count(*) FROM routing_decisions WHERE override_reason='fable-denied' AND datetime(ts) >= datetime('now','-7 days');")
d30=$(q "SELECT count(*) FROM routing_decisions WHERE override_reason='fable-denied' AND datetime(ts) >= datetime('now','-30 days');")

echo "Fable 5 metered-dispatch report ($(date +%F))"
echo ""
echo "Fable dispatches ALLOWED:  last 7 days: $f7   last 30 days: $f30"
echo "Fable dispatches DENIED:   last 7 days: $d7   last 30 days: $d30   (blocked: no valid FABLE-OK:<nonce> consent token, or a reused nonce — the drift signal; investigate if this grows)"
echo ""
est7=$(echo "$f7 $EST_PER_DISPATCH" | awk '{printf "%.2f", $1*$2}')
echo "ESTIMATED spend last 7 days: ~\$$est7  (ESTIMATE ONLY: tokens are not logged — assumes ≤30k in / ~4k out ≈ \$$EST_PER_DISPATCH per dispatch. Verify real charges on the Anthropic billing page.)"
echo ""
echo "Per-day breakdown (last 14 days, allowed fable dispatches):"
q "SELECT substr(ts,1,10) AS day, count(*) FROM routing_decisions WHERE model_chosen='fable' AND datetime(ts) >= datetime('now','-14 days') GROUP BY day ORDER BY day;" | awk -F'|' '{printf "  %s  %s dispatch(es)\n", $1, $2}'
echo ""
echo "Last 5 fable rows (ts | agent | reason):"
q "SELECT substr(ts,1,19), agent_kind, matched_keyword FROM routing_decisions WHERE model_chosen='fable' OR override_reason='fable-denied' ORDER BY ts DESC LIMIT 5;" | awk -F'|' '{printf "  %s | %s | %s\n", $1, $2, $3}'
exit 0
