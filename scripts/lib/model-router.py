#!/usr/bin/env python3
"""
Model routing hook — PreToolUse handler for Agent dispatches.

Doctrine: ../commander/MODEL_ROUTING.md (single source of truth).
This script implements §3 (decision algorithm) and §5 (doctrine table).
Keep DOCTRINE / HARD_FLOOR_PATTERNS in sync with that file.

Reads hook JSON from stdin, decides the right tier, logs the decision to
the cost ledger, prints a transparency banner to stderr, and (where Claude
Code supports it) modifies tool_input.model.

Exit code: always 0 — never block dispatches. Degraded routing is the
failure mode, not a halted Agent call.

Modes:
  Normal   — invoked by Claude Code as a PreToolUse hook
  Dry-run  — set HQ_DRY_RUN=1, suppresses ledger writes + JSON output;
             still prints the transparency banner. Used by /route preview.
"""

from __future__ import annotations

import json
import os
import sqlite3
import sys
from datetime import datetime, timezone
from pathlib import Path

# --------------------------------------------------------------------------
# Doctrine — mirror of MODEL_ROUTING.md §4 + §5. Keep in sync.
# --------------------------------------------------------------------------

HARD_FLOOR_PATTERNS = [
    "red-team", "redteam", "adversarial",
    "reviewer",  # *-reviewer (security-, code-, cpp-, python-, etc.)
    "security-review",
    "investor-comms", "investor-materials", "investor-outreach",
    "legal-review",
    "architect", "code-architect",
]

# (priority, [keywords], tier, label) — higher priority wins on multi-match
DOCTRINE = [
    # Opus tier (priority 30)
    (30, ["red-team", "adversarial", "threat-model", "contradict"], "opus", "adversarial"),
    (30, ["architect", "design", "blueprint", "plan system"], "opus", "architecture"),
    (30, ["pitch", "deck", "memo", "investor", "fundraise"], "opus", "investor-comms"),
    (30, ["legal", "compliance", "regulatory", "license"], "opus", "legal/compliance"),
    (30, ["long-context"], "opus", "long-context"),

    # Sonnet tier (priority 20)
    (20, ["implement", "build", "add feature", "fix bug"], "sonnet", "implementation"),
    (20, ["review", "audit", "simplify"], "sonnet", "code-review"),
    (20, ["synthesise", "synthesize", "compile findings", "merge"], "sonnet", "synthesis"),
    (20, ["write tests", "tdd", "coverage"], "sonnet", "testing"),
    (20, ["refactor", "restructure", "decompose"], "sonnet", "refactor"),

    # Haiku tier (priority 10)
    (10, ["rename", "format", "lint", "prettier", "normalise", "normalize"], "haiku", "mechanical"),
    (10, ["summarise", "summarize", "extract", "condense", "tldr"], "haiku", "summarisation"),
    (10, ["classify", "categorise", "categorize", "tag", "label"], "haiku", "classification"),
]

DEFAULT_TIER = "sonnet"

# --- Top-tier placeholder switch (FABLE_ENABLED) ---------------------------
# Fable 5 (Mythos-class) was the explicit-only premium tier ABOVE Opus. Anthropic
# DISABLED Fable on 2026-06-14, so its slot is now a RESERVED PLACEHOLDER: kept in
# TIER_ORDER below so a future above-Opus model can slot straight in, but switched
# OFF today. While OFF, any explicit `model: fable`/`claude-fable-5` request is
# clamped DOWN to the active ceiling (Opus) instead of being honored — emitting a
# disabled model would otherwise fail the dispatch (see clamp_disabled_tier).
#
# Fable was ALSO always excluded from AUTOMATIC routing (no DOCTRINE keyword maps to
# it; HQ_MODEL_OVERRIDE/HQ_MODEL_FLOOR reject it). That stays true whether on or off:
# a top tier is never auto-selected (it would bill real $ once off the free promo).
#
# TO RE-ENABLE when a new top-tier model ships: set FABLE_ENABLED = True. If the new
# model has a different name, also update tier_for_model() + the emitted model id /
# bare alias. See MODEL_ROUTING.md §5.5.
FABLE_ENABLED = False
DISABLED_TIER_FALLBACK = "opus"  # active ceiling a disabled top tier falls back to

TIER_ORDER = {"haiku": 0, "sonnet": 1, "opus": 2, "fable": 3}
VALID_TIERS = set(TIER_ORDER.keys())
# Tiers eligible for AUTOMATIC routing (env override / floor / doctrine / default).
# Fable is EXCLUDED on purpose: it is explicit-caller-only — when enabled it may enter
# routing ONLY via an explicit `model: claude-fable-5` on a dispatch (decide() step 4).
AUTO_TIERS = {"haiku", "sonnet", "opus"}

# Banner hints — adapt to the on/off state so we never give stale advice.
FABLE_EXPLICIT_HINT = "Fable is explicit-only; pass model:claude-fable-5 per dispatch (§5.5)."
FABLE_DISABLED_HINT = (
    "Fable is parked (disabled 2026-06-14) — Opus is the current ceiling; "
    "the slot is reserved for a future above-Opus model (§5.5)."
)

# --------------------------------------------------------------------------
# Paths
# --------------------------------------------------------------------------

HQ_ROOT = Path(os.environ.get("HQ_ROOT", str(Path.home() / "claude-hq")))
LEDGER_PATH = HQ_ROOT / "run" / "cost-ledger.sqlite"
LOG_PATH = HQ_ROOT / "scripts" / ".model-router.log"

# --------------------------------------------------------------------------
# Helpers
# --------------------------------------------------------------------------


def log_debug(msg: str) -> None:
    try:
        LOG_PATH.parent.mkdir(parents=True, exist_ok=True)
        with LOG_PATH.open("a") as f:
            f.write(f"[{datetime.now().isoformat()}] {msg}\n")
    except Exception:
        pass


def banner(text: str) -> None:
    """Visible in conversation via stderr."""
    sys.stderr.write(f"→ {text}\n")
    sys.stderr.flush()


def normalise_tier(value: str | None) -> str | None:
    if not value:
        return None
    v = value.strip().lower()
    return v if v in VALID_TIERS else None


def normalise_auto_tier(value: str | None) -> str | None:
    """For AUTO surfaces (HQ_MODEL_OVERRIDE / HQ_MODEL_FLOOR): like normalise_tier
    but REJECTS 'fable'. Fable is never auto-routable — it enters only via an
    explicit caller model (decide() step 4). Returns None for fable/unknown."""
    t = normalise_tier(value)
    return t if t in AUTO_TIERS else None


def fable_hint() -> str:
    """Banner advice that tracks the on/off state — never tells a user to pass a
    model id that is currently disabled."""
    return FABLE_EXPLICIT_HINT if FABLE_ENABLED else FABLE_DISABLED_HINT


def clamp_disabled_tier(tier: str, reason: str) -> tuple[str, str]:
    """Clamp a disabled top-tier placeholder DOWN to the active ceiling.

    Matches the bare tier 'fable' ONLY. Router-off and non-Anthropic passthrough
    return a raw model string (not a tier), so they are intentionally left
    untouched — turning routing off means the operator's literal choice stands.
    No-op once FABLE_ENABLED is True (or for any other tier)."""
    if tier == "fable" and not FABLE_ENABLED:
        return DISABLED_TIER_FALLBACK, f"fable-disabled-placeholder → {DISABLED_TIER_FALLBACK}"
    return tier, reason


def is_anthropic_model(model: str) -> bool:
    """Heuristic: True if a model string looks like a Claude/Anthropic model.

    Examples that match: "claude-sonnet-4-6", "Claude-Haiku-4-5-20251001",
      "claude-opus-4-7", "claude-foo-99" (unknown but Claude-shaped),
      bare tier aliases "haiku" / "sonnet" / "opus".
    Examples that do NOT match: "gemini-2.5-flash", "gpt-4", "kimi-k2-instruct".

    Ported from Paperclip's modelRouting/router.ts (2026-05-08 safety rule).
    """
    if not model:
        return False
    m = model.lower().strip()
    if m.startswith("claude") or "anthropic" in m:
        return True
    # Bare tier aliases are treated as Anthropic-shaped (HQ accepts them today)
    if m in VALID_TIERS:
        return True
    return False


def tier_for_model(model: str) -> str | None:
    """Extract tier (haiku/sonnet/opus) from a Claude model string.

    Substring match. Returns None for non-Claude or unrecognised strings.
    """
    if not model:
        return None
    m = model.lower()
    if "haiku" in m:
        return "haiku"
    if "sonnet" in m:
        return "sonnet"
    if "opus" in m:
        return "opus"
    if "fable" in m:
        return "fable"
    return None


# --------------------------------------------------------------------------
# Decision logic — §3 algorithm
# --------------------------------------------------------------------------


def is_hard_floor(subagent_type: str) -> bool:
    if not subagent_type:
        return False
    name = subagent_type.lower()
    return any(p.lower() in name for p in HARD_FLOOR_PATTERNS)


def doctrine_match(prompt: str) -> tuple[str, str]:
    if not prompt:
        return DEFAULT_TIER, "default"
    p = prompt.lower()
    best: tuple[int, str, str] | None = None
    for priority, keywords, tier, label in DOCTRINE:
        for kw in keywords:
            if kw in p:
                if best is None or priority > best[0]:
                    best = (priority, tier, f"'{kw}' → {label}")
                break
    if best is None:
        return DEFAULT_TIER, "default"
    return best[1], best[2]


def apply_floor(tier: str, floor: str | None) -> tuple[str, bool]:
    """Return (resulting_tier, did_apply_floor)."""
    if not floor:
        return tier, False
    if TIER_ORDER.get(tier, -1) < TIER_ORDER[floor]:
        return floor, True
    return tier, False


def decide(tool_input: dict) -> tuple[str, str]:
    """
    Apply §3 decision algorithm. Returns (chosen_tier, reason).

    Order:
      1. HQ_ROUTER_OFF=1                     → pass-through, no routing applied
      2. Non-Anthropic passthrough           → if caller set a non-Claude model,
                                               preserve it verbatim (added
                                               2026-05-23, ported from Paperclip)
      3. Pick a candidate tier:
           a. HQ_MODEL_OVERRIDE if set       → that tier (explicit intent,
                                               skips current_tier_floor)
           b. else doctrine keyword match    → tier from §5 table
           c. else default                   → DEFAULT_TIER (sonnet)
      4. current_tier_floor                  → if caller's tier was HIGHER than
                                               doctrine's choice, keep caller's
                                               (added 2026-05-23, ported from
                                               Paperclip). Doctrine can escalate,
                                               never downgrade.
      5. Hard floor guard: if subagent kind is on the §4 list, force opus
         (this beats every choice in steps 3-4 except HQ_ROUTER_OFF).
      6. HQ_MODEL_FLOOR guard: never go below the user-set floor.
    """
    # 1. Router off entirely
    if os.environ.get("HQ_ROUTER_OFF") == "1":
        return tool_input.get("model") or DEFAULT_TIER, "router-off"

    # 2. Non-Anthropic passthrough — preserve cross-provider operator choices
    current_model = (tool_input.get("model") or "").strip()
    if current_model and not is_anthropic_model(current_model):
        return current_model, "non-anthropic-passthrough"

    subagent_type = tool_input.get("subagent_type", "") or ""
    current_tier = tier_for_model(current_model) if current_model else None

    # 3. Pick candidate tier
    candidate_tier: str | None = None
    candidate_reason = ""

    override = normalise_auto_tier(os.environ.get("HQ_MODEL_OVERRIDE"))
    if (os.environ.get("HQ_MODEL_OVERRIDE") or "").strip().lower() == "fable" and not override:
        banner(f"HQ_MODEL_OVERRIDE=fable IGNORED — {fable_hint()}")
    if override:
        candidate_tier = override
        candidate_reason = f"env-override (HQ_MODEL_OVERRIDE={override})"
        # env_override is explicit intent — skip current_tier_floor
    else:
        prompt = tool_input.get("prompt", "") or ""
        tier, label = doctrine_match(prompt)
        candidate_tier = tier
        candidate_reason = label

        # 4. current_tier_floor — doctrine can escalate above caller's choice,
        #    but never downgrade it. If caller specified a HIGHER tier than
        #    doctrine picked, keep caller's choice.
        if current_tier and TIER_ORDER[current_tier] > TIER_ORDER[candidate_tier]:
            candidate_reason = (
                f"current-tier-floor (caller={current_tier}; "
                f"doctrine wanted {candidate_tier})"
            )
            candidate_tier = current_tier

    # 5. Hard floor — Opus is the MINIMUM for these agent kinds (§4: refuse all
    #    DOWNgrades). haiku/sonnet are forced UP to opus. An explicit higher tier
    #    (Fable, via step 4) exceeds the floor, so decide() returns it here — BUT
    #    while FABLE_ENABLED=False, clamp_disabled_tier() in main() bumps that fable
    #    result DOWN to Opus before emission (Fable is disabled; see §5.5). Fable is
    #    never auto-applied here; it only reaches this point if explicitly requested.
    if is_hard_floor(subagent_type):
        if TIER_ORDER[candidate_tier] < TIER_ORDER["opus"]:
            return "opus", f"hard-floor ({subagent_type}; candidate was {candidate_tier})"
        return candidate_tier, f"hard-floor satisfied ({subagent_type} → {candidate_tier})"

    # 6. HQ_MODEL_FLOOR
    floor = normalise_auto_tier(os.environ.get("HQ_MODEL_FLOOR"))
    if (os.environ.get("HQ_MODEL_FLOOR") or "").strip().lower() == "fable" and not floor:
        banner(f"HQ_MODEL_FLOOR=fable IGNORED — {fable_hint()}")
    new_tier, applied = apply_floor(candidate_tier, floor)
    if applied:
        return new_tier, f"floor (HQ_MODEL_FLOOR={floor}; candidate was {candidate_tier})"

    return candidate_tier, candidate_reason


# --------------------------------------------------------------------------
# Cost ledger
# --------------------------------------------------------------------------

LEDGER_SCHEMA = """
CREATE TABLE IF NOT EXISTS routing_decisions (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    ts              TEXT    NOT NULL,
    session_id      TEXT,
    project         TEXT,
    agent_kind      TEXT,
    task_summary    TEXT,
    model_requested TEXT,
    model_chosen    TEXT    NOT NULL,
    override_reason TEXT,
    matched_keyword TEXT,
    input_tokens    INTEGER,
    output_tokens   INTEGER,
    cost_usd        REAL,
    duration_ms     INTEGER,
    status          TEXT
);
CREATE INDEX IF NOT EXISTS idx_ts      ON routing_decisions(ts);
CREATE INDEX IF NOT EXISTS idx_session ON routing_decisions(session_id);
CREATE INDEX IF NOT EXISTS idx_project ON routing_decisions(project);
"""


def write_decision(record: dict) -> None:
    try:
        LEDGER_PATH.parent.mkdir(parents=True, exist_ok=True)
        conn = sqlite3.connect(LEDGER_PATH)
        try:
            conn.executescript(LEDGER_SCHEMA)
            conn.execute(
                """
                INSERT INTO routing_decisions (
                    ts, session_id, project, agent_kind, task_summary,
                    model_requested, model_chosen, override_reason,
                    matched_keyword, status
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    record["ts"],
                    record.get("session_id"),
                    record.get("project"),
                    record.get("agent_kind"),
                    record.get("task_summary"),
                    record.get("model_requested"),
                    record["model_chosen"],
                    record.get("override_reason"),
                    record.get("matched_keyword"),
                    "queued",
                ),
            )
            conn.commit()
        finally:
            conn.close()
    except Exception as e:
        log_debug(f"ledger write failed: {e}")


# --------------------------------------------------------------------------
# Entry
# --------------------------------------------------------------------------


def main() -> int:
    dry_run = os.environ.get("HQ_DRY_RUN") == "1"

    try:
        raw = sys.stdin.read()
        if not raw.strip():
            log_debug("empty stdin; no-op")
            return 0
        hook_input = json.loads(raw)
    except Exception as e:
        log_debug(f"parse error: {e}")
        return 0

    tool_name = hook_input.get("tool_name", "")
    if tool_name != "Agent":
        return 0

    tool_input = hook_input.get("tool_input", {}) or {}
    session_id = hook_input.get("session_id")
    cwd = hook_input.get("cwd") or os.getcwd()
    project = Path(cwd).name

    chosen_tier, reason = decide(tool_input)
    # Disabled top-tier placeholder (Fable, while FABLE_ENABLED=False) → clamp to Opus.
    chosen_tier, reason = clamp_disabled_tier(chosen_tier, reason)
    requested = tool_input.get("model")
    subagent_kind = tool_input.get("subagent_type") or "general-purpose"
    prompt_text = (tool_input.get("prompt") or "").strip().replace("\n", " ")
    prompt_summary = prompt_text[:120]

    # Transparency banner — always prints
    if requested and normalise_tier(requested) != chosen_tier:
        banner(
            f"Routed {subagent_kind} → {chosen_tier} "
            f"({reason}; caller asked for {requested})"
        )
    else:
        banner(f"Routed {subagent_kind} → {chosen_tier} ({reason})")

    if dry_run:
        # Don't log, don't emit hook output — preview only
        return 0

    # Log decision
    write_decision({
        "ts": datetime.now(timezone.utc).isoformat(),
        "session_id": session_id,
        "project": project,
        "agent_kind": subagent_kind,
        "task_summary": prompt_summary,
        "model_requested": requested,
        "model_chosen": chosen_tier,
        "override_reason": reason.split(" (", 1)[0],
        "matched_keyword": reason,
    })

    # Hook output — allow + (forward-compatible) modifyToolInput
    output: dict = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "allow",
            "permissionDecisionReason": f"routed → {chosen_tier} ({reason})",
        }
    }
    # Best-effort tool_input override for newer Claude Code versions
    if normalise_tier(requested) != chosen_tier:
        output["modifyToolInput"] = {"model": chosen_tier}

    print(json.dumps(output))
    return 0


if __name__ == "__main__":
    sys.exit(main())
