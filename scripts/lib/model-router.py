#!/usr/bin/env python3
"""
Model routing hook — PreToolUse handler for Agent dispatches.

Doctrine: ../commander/MODEL_ROUTING.md (single source of truth).
This script implements §3 (decision algorithm) and §5 (doctrine table).
Keep DOCTRINE / HARD_FLOOR_PATTERNS in sync with that file.

Reads hook JSON from stdin, decides the right tier, logs the decision to
the cost ledger, prints a transparency banner to stderr, and (where Claude
Code supports it) modifies tool_input.model.

Exit code: always 0. Routing never blocks dispatches, with ONE deliberate
exception (2026-07-12): an unauthorized METERED-Fable dispatch (model resolves
to fable, no FABLE-OK consent sentinel in the prompt) is DENIED via
permissionDecision — because modifyToolInput enforcement was disproven on this
build, deny is the only real cap on a real-dollar dispatch. Everything else:
degraded routing is the failure mode, not a halted Agent call.

Modes:
  Normal   — invoked by Claude Code as a PreToolUse hook
  Dry-run  — set HQ_DRY_RUN=1, suppresses ledger writes + JSON output;
             still prints the transparency banner. Used by /route preview.
"""

from __future__ import annotations

import json
import os
import re
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

# --- Top-tier switch (FABLE_ENABLED) + metering gate (FABLE_METERED) -------
# Fable 5 (Mythos-class) is the explicit-only premium tier ABOVE Opus. Enabled
# (re-enabled 2026-07-03 when Anthropic restored claude-fable-5) AND METERED:
# Anthropic removed Fable from Pro/Max flat-rate coverage (verified 2026-07-12,
# $10/M in · $50/M out — 2× Opus). While metered, a dispatch whose requested
# model resolves to fable is DENIED by main()'s deny gate UNLESS the prompt
# carries a valid single-use `FABLE-OK:<nonce>` consent token — the in-transcript
# consent artifact (Lesson 17). An inherited/casual `model: fable` stamp (the
# current-tier-floor leak, 49 ledger rows pre-fix) has no token → denied. The
# token lives in the PROMPT, not the model field, because
# a Fable main loop stamps the model field reflexively — the harness never
# auto-fills prompts, so the sentinel is unambiguous intent.
#
# Fable is ALSO always excluded from AUTOMATIC routing (no DOCTRINE keyword maps to
# it; HQ_MODEL_OVERRIDE/HQ_MODEL_FLOOR reject it). A top tier is never auto-selected.
#
# TO DISABLE (if Anthropic pulls the model): set FABLE_ENABLED = False —
# clamp_disabled_tier() bumps explicit fable requests down to Opus.
# TO UN-METER (if Fable returns to flat-rate): set FABLE_METERED = False — the
# sentinel gate becomes a no-op, pre-metering behavior restored. One-line rollback.
# See MODEL_ROUTING.md §5.5.
FABLE_ENABLED = True  # re-enabled 2026-07-03: Anthropic restored Claude Fable 5 (claude-fable-5)
FABLE_METERED = True  # metered from ~2026-07-13 ($10/M in, $50/M out; verified 2026-07-12)
# Consent sentinel (H1 fix, 2026-07-12): the token is `FABLE-OK:<nonce>` where <nonce>
# is ≥4 alnum/hyphen chars the Commander MINTS PER OPERATOR APPROVAL. A regex (not a bare
# substring) is required so that PROSE quoting the doctrine — which contains the bare
# string "FABLE-OK" and the template "FABLE-OK:<nonce>" (angle brackets, unmatchable) —
# can NEVER self-authorize a dispatch. `<nonce>` in docs has literal `<>` so it won't match.
FABLE_SENTINEL_PREFIX = "FABLE-OK"  # human-readable name for banners/messages
FABLE_SENTINEL_RE = re.compile(r"FABLE-OK:([A-Za-z0-9][A-Za-z0-9-]{3,})")
DISABLED_TIER_FALLBACK = "opus"  # active ceiling a disabled top tier falls back to

TIER_ORDER = {"haiku": 0, "sonnet": 1, "opus": 2, "fable": 3}
VALID_TIERS = set(TIER_ORDER.keys())
# Tiers eligible for AUTOMATIC routing (env override / floor / doctrine / default).
# Fable is EXCLUDED on purpose: it is explicit-caller-only — when enabled it may enter
# routing ONLY via an explicit `model: claude-fable-5` on a dispatch (decide() step 4).
AUTO_TIERS = {"haiku", "sonnet", "opus"}

# Banner hints — adapt to the on/off state so we never give stale advice.
FABLE_EXPLICIT_HINT = (
    "Fable is explicit-only AND metered; pass model:claude-fable-5 per dispatch "
    "plus a per-approval consent token 'FABLE-OK:<nonce>' in the dispatch prompt (§5.5)."
)
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
NONCE_STORE = HQ_ROOT / "run" / ".fable-nonces"  # consumed consent nonces (single-use, H3)

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


def fable_authorized(tool_input: dict) -> str | None:
    """Return the consent NONCE if the dispatch prompt carries a valid
    `FABLE-OK:<nonce>` sentinel, else None. The sentinel lives in the PROMPT (a
    channel only a deliberate caller writes — the harness never auto-fills
    prompts, whereas a Fable main loop stamps the model field reflexively).
    The nonce form (not a bare substring) means prose that merely QUOTES the
    doctrine — which contains bare "FABLE-OK" and the "FABLE-OK:<nonce>" template
    (unmatchable angle brackets) — cannot self-authorize. Exception-safe."""
    m = FABLE_SENTINEL_RE.search(str(tool_input.get("prompt") or ""))
    return m.group(1) if m else None


def nonce_already_used(nonce: str) -> bool:
    """Single-use enforcement (H3): has this consent nonce been consumed before?
    One operator approval mints one nonce → one dispatch. FAIL-OPEN on a store
    read error for THIS sub-check only (reuse is a narrow risk — a fresh nonce
    per approval is minted by the Commander; the primary defence is the
    unforgeable nonce FORMAT above, and the core deny still fails CLOSED). A read
    error should not block a legitimate first-use dispatch."""
    try:
        if not NONCE_STORE.exists():
            return False
        return nonce in NONCE_STORE.read_text().split()
    except Exception as e:
        log_debug(f"nonce read failed (treating as unused): {e}")
        return False


def consume_nonce(nonce: str) -> None:
    """Record a consent nonce as spent. Best-effort; never raises."""
    try:
        NONCE_STORE.parent.mkdir(parents=True, exist_ok=True)
        with NONCE_STORE.open("a") as f:
            f.write(nonce + "\n")
    except Exception as e:
        log_debug(f"nonce write failed: {e}")


def coerce_str_field(tool_input: dict, key: str) -> None:
    """Fail-closed hygiene (C1): coerce a tool_input field to str in place so
    downstream .strip()/.lower()/regex never crash on a dict/list/number. For the
    model field this makes fable detection MORE inclusive (str(dict) still
    contains 'claude-fable-5' → detected → denied), i.e. it errs toward blocking."""
    v = tool_input.get(key)
    if v is not None and not isinstance(v, str):
        try:
            tool_input[key] = str(v)
        except Exception:
            tool_input[key] = ""


def raw_fable_unauthorized(hook_input: dict) -> bool:
    """Exception-safe last-ditch check used by the C1 fail-closed backstop: is
    this an Agent dispatch that requests metered Fable with no valid consent
    sentinel and no router-off? If we can't tell, return False (only deny when we
    can positively identify an unauthorized metered-fable request)."""
    try:
        if not isinstance(hook_input, dict):
            return False
        if hook_input.get("tool_name") != "Agent":
            return False
        if not (FABLE_ENABLED and FABLE_METERED):
            return False
        if os.environ.get("HQ_ROUTER_OFF") == "1":
            return False
        ti = hook_input.get("tool_input") or {}
        if not isinstance(ti, dict):
            return False
        if tier_for_model(str(ti.get("model") or "").strip()) != "fable":
            return False
        return FABLE_SENTINEL_RE.search(str(ti.get("prompt") or "")) is None
    except Exception:
        return False


def deny_output(reason_detail: str) -> dict:
    """The single deny payload for an unauthorized metered-fable dispatch."""
    return {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": (
                f"Fable 5 is METERED ($10/M in, $50/M out) and this dispatch {reason_detail}. "
                "Either re-dispatch on a subscription tier (model: opus/sonnet/haiku), or get "
                "operator approval and include a fresh 'FABLE-OK:<nonce>' token in the dispatch "
                "prompt (MODEL_ROUTING.md §5.5)."
            ),
        }
    }


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
    """Extract tier (haiku/sonnet/opus/fable) from a Claude model string.

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

        # 4a. Metered top-tier cap (§5.5, metering 2026-07) — a fable caller tier
        #     without a valid consent sentinel is capped to opus for the LEDGER's
        #     chosen_tier, so a denied dispatch is never miscounted as an allowed
        #     fable run (fable-spend.sh keys ALLOWED on model_chosen='fable'). The
        #     actual refusal is main()'s deny gate; this cap is bookkeeping + the
        #     inheritance backstop. No banner here — main() owns all messaging.
        fable_capped = False
        if (
            current_tier == "fable"
            and FABLE_ENABLED
            and FABLE_METERED
            and not fable_authorized(tool_input)
        ):
            current_tier = "opus"
            fable_capped = True

        # 4. current_tier_floor — doctrine can escalate above caller's choice,
        #    but never downgrade it. If caller specified a HIGHER tier than
        #    doctrine picked, keep caller's choice.
        if current_tier and TIER_ORDER[current_tier] > TIER_ORDER[candidate_tier]:
            if current_tier == "fable" and FABLE_METERED:
                candidate_reason = "fable-explicit (FABLE-OK:<nonce>; caller requested fable)"
            elif fable_capped:
                candidate_reason = "fable-capped (metered; no FABLE-OK:<nonce>) → opus"
            else:
                candidate_reason = (
                    f"current-tier-floor (caller={current_tier}; "
                    f"doctrine wanted {candidate_tier})"
                )
            candidate_tier = current_tier
        elif fable_capped:
            # Capped fable landed at/below doctrine's own pick — doctrine tier
            # stands, but the ledger must still show the cap fired.
            candidate_reason = f"{candidate_reason}; fable-capped (metered; no FABLE-OK:<nonce>)"

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


def _run(hook_input: dict, dry_run: bool) -> int:
    """Core processing. May raise; main() wraps it with the C1 fail-closed backstop."""
    if hook_input.get("tool_name", "") != "Agent":
        return 0

    tool_input = hook_input.get("tool_input") or {}
    if not isinstance(tool_input, dict):
        tool_input = {}
    # C1 fail-closed hygiene: coerce the fields downstream code will
    # .strip()/.lower()/regex, so a schema-violating dispatch can't crash the
    # gate into its historical allow-by-default posture. For `model`, coercion
    # errs toward BLOCKING (str(dict) still contains 'claude-fable-5' → denied).
    coerce_str_field(tool_input, "model")
    coerce_str_field(tool_input, "prompt")
    coerce_str_field(tool_input, "subagent_type")

    session_id = hook_input.get("session_id")
    cwd = hook_input.get("cwd") or os.getcwd()
    project = Path(cwd).name

    chosen_tier, reason = decide(tool_input)
    # Disabled top-tier placeholder (Fable, while FABLE_ENABLED=False) → clamp to Opus.
    chosen_tier, reason = clamp_disabled_tier(chosen_tier, reason)

    requested = tool_input.get("model")
    router_off = os.environ.get("HQ_ROUTER_OFF") == "1"
    subagent_kind = tool_input.get("subagent_type") or "general-purpose"
    prompt_text = (tool_input.get("prompt") or "").strip().replace("\n", " ")
    prompt_summary = prompt_text[:120]

    # ---- Metered-fable DENY gate (2026-07-12) -----------------------------
    # Verified 2026-07-12 (transcript forensics): this Claude Code build does NOT
    # honor modifyToolInput — a "capped" dispatch would still RUN fable at real
    # cost. Denying is the only real cap. The router's SINGLE deny case; keyed on
    # the RAW request so no decide() branch can route around it. Two deny reasons:
    # no valid FABLE-OK:<nonce> sentinel, or a reused nonce (one approval = one
    # dispatch). HQ_ROUTER_OFF=1 bypasses (operator's literal choice stands).
    requested_is_fable = (
        FABLE_ENABLED and FABLE_METERED and not router_off
        and tier_for_model((requested or "").strip()) == "fable"
    )
    auth_nonce = fable_authorized(tool_input) if requested_is_fable else None
    deny_detail = None
    if requested_is_fable:
        if not auth_nonce:
            deny_detail = "lacks a valid 'FABLE-OK:<nonce>' consent sentinel"
        elif nonce_already_used(auth_nonce):
            deny_detail = "reuses an already-spent FABLE-OK nonce (one approval = one dispatch)"

    if deny_detail is not None:
        # Loud, unambiguous refusal banner (M1) — not the old "Routed → opus".
        banner(
            f"DENIED: metered Fable dispatch — {deny_detail}. Re-dispatch on "
            "opus/sonnet/haiku, or get operator consent + a fresh FABLE-OK:<nonce> (§5.5)."
        )
        if dry_run:
            banner("(dry-run) preview only — no refusal emitted")
            return 0
        # Ledger: model_chosen='opus' (nothing ran as fable) keeps fable-spend.sh's
        # ALLOWED count (model_chosen='fable') clean; override_reason='fable-denied'
        # is the DENIED signal for BOTH deny reasons.
        write_decision({
            "ts": datetime.now(timezone.utc).isoformat(),
            "session_id": session_id, "project": project, "agent_kind": subagent_kind,
            "task_summary": prompt_summary, "model_requested": requested,
            "model_chosen": "opus", "override_reason": "fable-denied",
            "matched_keyword": f"DENIED ({'nonce-reused' if auth_nonce else 'no-sentinel'}); {reason}",
        })
        print(json.dumps(deny_output(deny_detail)))
        return 0

    # ---- ALLOW path -------------------------------------------------------
    # EFFECTIVE tier (2026-07-12 re-review MEDIUM fix): an authorized fable
    # request (valid unused sentinel) that we're allowing WILL run Fable at
    # runtime, because the honored control is the explicit `model:` param — even
    # if decide() picked a lower tier (e.g. HQ_MODEL_OVERRIDE=opus makes
    # chosen_tier=opus). So the money-path mechanisms — metered cost banner,
    # nonce consumption (single-use), and the ledger's model_chosen — key on the
    # REQUEST being an allowed fable dispatch, NOT on decide()'s chosen_tier.
    # Otherwise an override would silently: not spend the nonce (reuse), log
    # 'opus', and hide the spend from fable-spend.sh, while Fable really billed.
    allowed_fable = requested_is_fable and auth_nonce is not None
    effective_tier = "fable" if allowed_fable else chosen_tier

    if effective_tier == "fable" and FABLE_METERED:
        banner(
            "METERED DISPATCH: Fable 5 bills $10/M input, $50/M output — "
            "keep the brief curated (soft cap ~30k input tokens ≈ $0.30)."
        )
    if requested and normalise_tier(requested) != effective_tier:
        banner(f"Routed {subagent_kind} → {effective_tier} ({reason}; caller asked for {requested})")
    else:
        banner(f"Routed {subagent_kind} → {effective_tier} ({reason})")

    if dry_run:
        return 0

    # Spend the consent nonce for any ALLOWED authorized fable dispatch (H3),
    # regardless of what decide() picked.
    if allowed_fable and auth_nonce is not None:
        consume_nonce(auth_nonce)

    write_decision({
        "ts": datetime.now(timezone.utc).isoformat(),
        "session_id": session_id, "project": project, "agent_kind": subagent_kind,
        "task_summary": prompt_summary, "model_requested": requested,
        "model_chosen": effective_tier, "override_reason": reason.split(" (", 1)[0],
        "matched_keyword": reason,
    })

    output: dict = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "allow",
            "permissionDecisionReason": f"routed → {effective_tier} ({reason})",
        }
    }
    # Best-effort tool_input override for newer Claude Code versions. VERIFIED
    # 2026-07-12: the current build IGNORES this field — real tiering requires an
    # explicit `model:` param on the dispatch. Kept for forward-compatibility.
    # Never emit an override for an allowed fable run (it would contradict the
    # honored explicit param, and is ignored anyway).
    if not allowed_fable and normalise_tier(requested) != chosen_tier:
        output["modifyToolInput"] = {"model": chosen_tier}
    print(json.dumps(output))
    return 0


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
    if not isinstance(hook_input, dict):
        log_debug("hook_input not an object; no-op")
        return 0

    try:
        return _run(hook_input, dry_run)
    except Exception as e:
        # C1 fail-closed backstop: a crash must never silently ALLOW an
        # unauthorized metered-fable dispatch. On any error, if this is
        # positively an unauthorized metered-fable Agent dispatch → DENY; else
        # fall through to allow (don't block normal work on a router bug).
        log_debug(f"router crashed in _run: {e}")
        try:
            if not dry_run and raw_fable_unauthorized(hook_input):
                banner("DENIED (fail-closed): router error on an unauthorized metered-fable dispatch.")
                print(json.dumps(deny_output("could not be verified due to a router error")))
        except Exception as e2:
            log_debug(f"fail-closed backstop also failed: {e2}")
        return 0


if __name__ == "__main__":
    sys.exit(main())
