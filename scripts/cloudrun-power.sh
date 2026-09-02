#!/usr/bin/env bash
# cloudrun-power.sh — turn always-on Google Cloud Run services on and off.
#
# WHY THIS EXISTS
#   A Cloud Run service with "minimum instances" set to 1 keeps a machine alive
#   24 hours a day and bills for it even when nobody visits the page. Set the
#   minimum to 0 and the service still works — it just shuts the machine down
#   when idle and starts one on the next visit. The page stays up either way.
#   The only difference is a short delay on the first visit after a quiet spell.
#
#   Created 2026-09-02 after tracing an unexplained Google bill (card reference
#   CLOUD VBHV3N) to flightclub33-v3-demo, which had been holding a machine open
#   continuously since 8 June 2026.
#
# USAGE
#   ./cloudrun-power.sh status            what is on, what is off
#   ./cloudrun-power.sh off  <name>       stop paying (service still works)
#   ./cloudrun-power.sh on   <name>       instant response again, starts billing
#   ./cloudrun-power.sh on   <name> -y    same, without the confirmation question
#   ./cloudrun-power.sh list              show the services this script knows about
#
# ADDING A SERVICE
#   Append one line to the SERVICES list below:
#       nickname|service-name|project-id|region|minimum-when-on
#
set -uo pipefail

# nickname | cloud run service name | project id | region | minimum instances when ON
SERVICES=(
  "flightclub-demo|flightclub33-v3-demo|gen-lang-client-0822890649|us-west1|1"
)

STATE_DIR="${CLOUDRUN_POWER_STATE_DIR:-$HOME/claude-hq/run/cloudrun-state}"
LOG="$STATE_DIR/power-log.txt"
mkdir -p "$STATE_DIR"

bold() { printf '\033[1m%s\033[0m\n' "$1"; }

need_gcloud() {
  if ! command -v gcloud >/dev/null 2>&1; then
    echo "Cannot continue: the Google Cloud command line tool is not installed."
    echo "Install it with:  brew install --cask google-cloud-sdk"
    exit 1
  fi
  if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | grep -q .; then
    echo "Cannot continue: you are not signed in to Google Cloud."
    echo "Sign in with:  gcloud auth login"
    exit 1
  fi
}

lookup() {  # nickname -> sets SVC PROJ REG ONMIN, or returns 1
  local want="$1" row
  for row in "${SERVICES[@]}"; do
    IFS='|' read -r nick SVC PROJ REG ONMIN <<< "$row"
    [ "$nick" = "$want" ] && return 0
  done
  return 1
}

current_min() {  # echoes the minimum-instances number, 0 if unset
  local m
  m=$(gcloud run services describe "$SVC" --project="$PROJ" --region="$REG" \
        --format="value(spec.template.metadata.annotations['autoscaling.knative.dev/minScale'])" 2>/dev/null)
  echo "${m:-0}"
}

note() { printf '%s  %s\n' "$(date '+%Y-%m-%d %H:%M')" "$1" >> "$LOG"; }

cmd_list() {
  bold "Services this script can switch:"
  local row
  for row in "${SERVICES[@]}"; do
    IFS='|' read -r nick s p r m <<< "$row"
    printf '  %-18s  %s  (project %s, %s)\n' "$nick" "$s" "$p" "$r"
  done
}

cmd_status() {
  need_gcloud
  bold "Google Cloud Run — what is costing money right now"
  echo
  local row
  for row in "${SERVICES[@]}"; do
    IFS='|' read -r nick SVC PROJ REG ONMIN <<< "$row"
    local m; m=$(current_min)
    if [ "$m" = "0" ] || [ -z "$m" ]; then
      printf '  %-18s  OFF  — nothing is held open. Costs nothing while nobody visits.\n' "$nick"
      printf '  %-18s        The page still works; the first visit after a quiet spell is a little slower.\n' ""
    else
      printf '  %-18s  ON   — %s machine(s) held open around the clock. This bills every hour.\n' "$nick" "$m"
    fi
    echo
  done
  echo "Switch one off with:  $(basename "$0") off <name>"
  echo "Switch one on with:   $(basename "$0") on  <name>"
  echo
  echo "Exact charges are only visible here:"
  echo "  https://console.cloud.google.com/billing/01691F-377789-CD02C5/reports"
}

cmd_off() {
  need_gcloud
  lookup "$1" || { echo "Do not recognise '$1'. Run '$(basename "$0") list' to see the names."; exit 1; }
  local before; before=$(current_min)
  if [ "$before" = "0" ]; then
    echo "'$1' is already off. Nothing to do."
    exit 0
  fi
  echo "Switching '$1' off. The page keeps working; it just stops holding a machine open."
  gcloud run services describe "$SVC" --project="$PROJ" --region="$REG" --format=export \
    > "$STATE_DIR/$SVC.before-off-$(date +%Y-%m-%d-%H%M).yaml" 2>/dev/null
  if gcloud run services update "$SVC" --project="$PROJ" --region="$REG" --min-instances=0 --quiet >/dev/null 2>&1; then
    echo "Done. '$1' is now off and should stop appearing on the bill."
    note "OFF  $1 ($SVC) — minimum instances $before -> 0"
  else
    echo "That did not work. Nothing was changed. Try running it again, or check you are signed in."
    exit 1
  fi
}

cmd_on() {
  need_gcloud
  lookup "$1" || { echo "Do not recognise '$1'. Run '$(basename "$0") list' to see the names."; exit 1; }
  local skip="${2:-}"
  local before; before=$(current_min)
  if [ "$before" = "$ONMIN" ]; then
    echo "'$1' is already on. Nothing to do."
    exit 0
  fi
  echo "This will hold $ONMIN machine(s) open around the clock so the page answers instantly."
  echo "It starts charging again from the moment you say yes. Rough cost: a few pounds a month."
  if [ "$skip" != "-y" ] && [ "$skip" != "--yes" ]; then
    printf "Go ahead? [y/N] "
    read -r reply
    case "$reply" in [yY]*) ;; *) echo "Left off. Nothing changed."; exit 0 ;; esac
  fi
  if gcloud run services update "$SVC" --project="$PROJ" --region="$REG" --min-instances="$ONMIN" --quiet >/dev/null 2>&1; then
    echo "Done. '$1' is on and answering instantly. Remember to switch it off when you are finished."
    note "ON   $1 ($SVC) — minimum instances $before -> $ONMIN"
  else
    echo "That did not work. Nothing was changed. Try running it again, or check you are signed in."
    exit 1
  fi
}

case "${1:-status}" in
  status|"")  cmd_status ;;
  list)       cmd_list ;;
  off)        [ $# -ge 2 ] || { echo "Which one? Try: $(basename "$0") off flightclub-demo"; exit 1; }; cmd_off "$2" ;;
  on)         [ $# -ge 2 ] || { echo "Which one? Try: $(basename "$0") on flightclub-demo"; exit 1; }; cmd_on "$2" "${3:-}" ;;
  -h|--help|help) sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//' ;;
  *)          echo "Unknown command '$1'. Use: status, on, off, list"; exit 1 ;;
esac
