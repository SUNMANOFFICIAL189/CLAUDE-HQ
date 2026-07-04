#!/usr/bin/env bash
# handoff locator — deterministically find THE canonical HANDOFF.md for the current project,
# instead of guessing one path. Fixes the "wrong/duplicate doc" + "decoy on unmounted drive" failures.
#
# Usage:
#   locate.sh                 -> prints one of:
#                                  CANONICAL   <abs-path>   (use it / create at it)
#                                  UNREACHABLE <abs-path>   (recorded doc's volume is gone — DO NOT create a decoy)
#                                  NONE        <default>    (no handoff yet; default = repo-root/HANDOFF.md)
#                                  AMBIGUOUS               (then one candidate path per line, newest first)
#   locate.sh --set <path>    -> pins <path> as canonical in <repo-root>/.claude/handoff-path
#
# The pointer file <repo-root>/.claude/handoff-path (one absolute path per line, first line wins)
# makes the choice deterministic forever after the first disambiguation.

set -uo pipefail

repo_root() {
  git rev-parse --show-toplevel 2>/dev/null || pwd
}

ROOT="$(repo_root)"
POINTER="$ROOT/.claude/handoff-path"

if [ "${1:-}" = "--set" ]; then
  TARGET="${2:-}"
  if [ -z "$TARGET" ]; then echo "usage: locate.sh --set <abs-path>" >&2; exit 2; fi
  case "$TARGET" in /*) : ;; *) TARGET="$ROOT/$TARGET" ;; esac   # normalise to absolute
  mkdir -p "$ROOT/.claude"
  printf '%s\n' "$TARGET" > "$POINTER"
  echo "PINNED $TARGET"
  exit 0
fi

# 1) Recorded pointer wins.
if [ -f "$POINTER" ]; then
  P="$(head -1 "$POINTER" 2>/dev/null)"
  if [ -n "$P" ]; then
    if [ -f "$P" ]; then
      echo "CANONICAL $P"; exit 0
    elif [ -d "$(dirname "$P")" ]; then
      echo "CANONICAL $P"; exit 0          # file gone but its dir is reachable — safe to recreate here
    else
      echo "UNREACHABLE $P"; exit 0        # parent dir/volume missing — do NOT fork a decoy elsewhere
    fi
  fi
fi

# 2) No pointer — discover candidates across the known location patterns.
CANDS=()
add() { [ -f "$1" ] && CANDS+=("$1"); }
add "$ROOT/HANDOFF.md"
add "$ROOT/docs/HANDOFF.md"
for f in "$ROOT"/_NEXT_STEPS/*handoff*.md "$ROOT"/_NEXT_STEPS/*HANDOFF*.md; do [ -f "$f" ] && CANDS+=("$f"); done
for f in "$ROOT"/.continuity/*HANDOFF*.md "$ROOT"/.continuity/*handoff*.md; do [ -f "$f" ] && CANDS+=("$f"); done
for f in "$ROOT"/.paul/HANDOFF*.md "$ROOT"/.paul/*handoff*.md; do [ -f "$f" ] && CANDS+=("$f"); done
# also any handoff-shaped file at repo root we didn't already name — but NOT the skill's own
# sibling files (constitution, template, or a HANDOFF.<slug>.md sub-task baton), which live in the
# same dir and would otherwise make every correctly-configured project look AMBIGUOUS.
shopt -s nocasematch 2>/dev/null || true
for f in "$ROOT"/*[Hh][Aa][Nn][Dd][Oo][Ff][Ff]*.md; do
  [ -f "$f" ] || continue
  case "$(basename "$f")" in
    *constitution*|*.template.md|*.template|handoff.*.md) continue ;;
  esac
  CANDS+=("$f")
done
shopt -u nocasematch 2>/dev/null || true

# dedupe (preserve first-seen)
UNIQ=()
for c in "${CANDS[@]:-}"; do
  [ -z "$c" ] && continue
  dup=0; for u in "${UNIQ[@]:-}"; do [ "$u" = "$c" ] && dup=1 && break; done
  [ "$dup" -eq 0 ] && UNIQ+=("$c")
done

n=${#UNIQ[@]}
if [ "$n" -eq 0 ]; then
  echo "NONE $ROOT/HANDOFF.md"
elif [ "$n" -eq 1 ]; then
  echo "CANONICAL ${UNIQ[0]}"
else
  echo "AMBIGUOUS"
  # newest first, so the operator sees the likely-live one at the top
  ls -t "${UNIQ[@]}" 2>/dev/null || printf '%s\n' "${UNIQ[@]}"
fi
exit 0
