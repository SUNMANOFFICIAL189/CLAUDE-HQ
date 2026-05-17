#!/usr/bin/env python3
"""
Codex rate-limit catcher — PostToolUse hook.

Watches Bash tool output for Codex rate-limit errors. When a hit is detected,
fires ONE plain-English Telegram alert via the HQ Watchdog PlainAlert path
and suppresses further alerts for 5 hours (the Codex rolling window).

Exit 0 always — this is observational, never blocks the tool call.

Trigger conditions (any one):
  - Bash command contains "codex" (catches /codex:* slash commands which
    Claude Code translates into Bash spawns of codex-companion.mjs, plus
    direct codex CLI invocations)
  - Tool output contains a known rate-limit error fingerprint

Fingerprints (case-insensitive substring match):
  - "rate limit"           — the OpenAI / Codex CLI standard phrasing
  - "429"                  — HTTP status code in error responses
  - "too many requests"    — HTTP 429 reason phrase
  - "usage limit"          — Codex-specific phrasing
  - "quota exceeded"       — generic
  - "rate_limit_exceeded"  — OpenAI API error code

Throttle: 5 hours (matches Codex rolling window). State persisted at
~/claude-hq/run/codex-rate-limit-last-alert.txt as an ISO timestamp.

Reference: feedback_codex_delegation_doctrine.md, watchdog/telegram.py
Lesson 16 (plain-English alerts), Lesson 17 (propose-don't-auto-invoke
doesn't apply here — this is an information-only alert, not an action).
"""

from __future__ import annotations

import json
import os
import re
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

HQ_ROOT = Path(os.environ.get("HQ_ROOT", "/Users/sunil_rajput/claude-hq"))
THROTTLE_FILE = HQ_ROOT / "run" / "codex-rate-limit-last-alert.txt"
THROTTLE_HOURS = 5

# Trigger fingerprints — case-insensitive substring match against tool output
FINGERPRINTS = (
    "rate limit",
    "rate_limit",
    "429",
    "too many requests",
    "usage limit",
    "quota exceeded",
    "rate_limit_exceeded",
)


def _read_hook_input() -> dict:
    """Claude Code PostToolUse passes JSON on stdin."""
    raw = sys.stdin.read().strip()
    if not raw:
        return {}
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return {}


def _is_codex_invocation(tool_input: dict) -> bool:
    """Check if this Bash call was a Codex invocation."""
    cmd = str(tool_input.get("command", ""))
    return "codex" in cmd.lower()


def _output_text(payload: dict) -> str:
    """Extract the tool output text (stdout + stderr) from the hook payload."""
    parts = []
    response = payload.get("tool_response") or {}
    for key in ("stdout", "stderr", "output", "error"):
        v = response.get(key)
        if isinstance(v, str):
            parts.append(v)
    return "\n".join(parts)


def _matches_fingerprint(text: str) -> bool:
    """Case-insensitive substring match against any known rate-limit fingerprint.

    For '429' we require the standalone token to avoid matching unrelated digits
    (e.g. file paths, byte counts, port numbers like 4290).
    """
    if not text:
        return False
    lowered = text.lower()
    for fp in FINGERPRINTS:
        if fp == "429":
            # Require word-boundary on both sides to avoid false positives
            if re.search(r"\b429\b", lowered):
                # And require a co-occurring context word so we don't fire on
                # arbitrary numerics. The presence of any of these alongside
                # 429 is strong signal of a rate-limit response.
                if any(w in lowered for w in ("rate", "limit", "too many", "throttl", "quota")):
                    return True
            continue
        if fp in lowered:
            return True
    return False


def _within_throttle_window() -> bool:
    """Return True if we alerted within the last THROTTLE_HOURS."""
    if not THROTTLE_FILE.is_file():
        return False
    try:
        last = datetime.fromisoformat(THROTTLE_FILE.read_text().strip())
    except ValueError:
        return False
    return (datetime.now(timezone.utc) - last) < timedelta(hours=THROTTLE_HOURS)


def _record_alert_sent() -> None:
    THROTTLE_FILE.parent.mkdir(parents=True, exist_ok=True)
    THROTTLE_FILE.write_text(datetime.now(timezone.utc).isoformat())


def _fire_alert() -> None:
    """Build and send a PlainAlert via the watchdog telegram pipe."""
    # Import here so we don't pay the cost on every non-Codex Bash call
    sys.path.insert(0, str(HQ_ROOT / "watchdog"))
    try:
        from telegram import PlainAlert, send  # type: ignore[import-not-found]
    except ImportError:
        return  # telegram pipe missing — silently skip (this is best-effort)

    alert = PlainAlert(
        what_happened=(
            "Codex just hit its usage cap. Any further /codex:rescue or "
            "/codex:review commands will fail until the window resets — "
            "this usually takes a few hours, depending on when usage started."
        ),
        what_to_do=(
            "Switch back to Claude for coding work for now. Check the Codex "
            "usage dashboard or run /status inside a Codex CLI session to see "
            "when the cap clears."
        ),
        severity="warn",
        headline_emoji="⏳",
    )
    send(alert)  # fire-and-forget; errors are returned not raised


def main() -> int:
    payload = _read_hook_input()
    tool_name = payload.get("tool_name", "")
    if tool_name != "Bash":
        return 0

    tool_input = payload.get("tool_input") or {}
    if not _is_codex_invocation(tool_input):
        return 0

    output = _output_text(payload)
    if not _matches_fingerprint(output):
        return 0

    if _within_throttle_window():
        return 0

    _fire_alert()
    _record_alert_sent()
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception:  # noqa: BLE001 — never let a hook fail the tool call
        sys.exit(0)
