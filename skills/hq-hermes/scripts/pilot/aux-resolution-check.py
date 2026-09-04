#!/usr/bin/env python3
"""HQ Hermes pilot -- T8b H2 aux-pins resolution-level proof.

proof-check-s3-2026-09-04.md HIGH-2: T8's "0 agent.auxiliary_client lines in
the post-pin errors.log window" proved nothing -- the window held 0 lines of
ANY kind, meaning no auxiliary call was ever attempted (Lesson 34: a check
that cannot fail reproduced inside the very check written to enforce it).

This checks the CONFIG-RESOLUTION layer directly instead of inferring from
an absence of log lines: for each of the 10 auxiliary surfaces named in
mechanisms.md (i) (vision, web_extract, tts_audio_tags, title_generation,
session_search, compression, background_review, curator, approval, monitor)
it calls the exact symbol `agent/auxiliary_client.py::_call_llm_impl` calls
at its top to decide which provider/model an auxiliary call would actually
use --

    resolved_provider, resolved_model, resolved_base_url, resolved_api_key,
    resolved_api_mode = _resolve_task_provider_model(task, provider, model,
                                                      base_url, api_key)

-- and asserts it resolves to provider == "custom" and model == the
configured model.default, with the loaded config's auxiliary.free_only also
True.

`_resolve_task_provider_model()` only reads config, via its own
`_get_auxiliary_task_config(task)` helper -> `hermes_cli.config
.load_config_readonly()`; it never builds a provider client or touches the
network. The client-construction call sites for a real auxiliary call
(`resolve_vision_provider_client` / `_get_cached_client`) live one level up,
inside `_call_llm_impl` itself, and are deliberately NOT called here --
per the ticket, this script stops at the config-resolution layer.

Run with HERMES_HOME=<home> <python> aux-resolution-check.py -- no network,
no hermes command, no model call. Exits 0 with one PASS line per surface, or
1 on the first mismatch (naming every offending surface).
"""
import sys

SURFACES = [
    "vision",
    "web_extract",
    "tts_audio_tags",
    "title_generation",
    "session_search",
    "compression",
    "background_review",
    "curator",
    "approval",
    "monitor",
]


def main() -> int:
    from agent.auxiliary_client import _resolve_task_provider_model
    from hermes_cli.config import load_config_readonly

    config = load_config_readonly()
    expected_model = (config.get("model") or {}).get("default")
    free_only = (config.get("auxiliary") or {}).get("free_only")

    if free_only is not True:
        print(
            f"aux-resolution-check: FAIL -- auxiliary.free_only is {free_only!r}, expected True",
            file=sys.stderr,
        )
        return 1

    failures = []
    for surface in SURFACES:
        provider, model, base_url, api_key, api_mode = _resolve_task_provider_model(surface)
        ok = provider == "custom" and model == expected_model
        status = "PASS" if ok else "FAIL"
        print(
            f"{status} {surface}: provider={provider!r} model={model!r} "
            f"(expected provider='custom' model={expected_model!r})"
        )
        if not ok:
            failures.append(surface)

    if failures:
        print(
            f"aux-resolution-check: FAIL -- mismatch on: {', '.join(failures)}",
            file=sys.stderr,
        )
        return 1

    print(
        f"aux-resolution-check: PASS -- all {len(SURFACES)} surfaces resolve to "
        f"provider='custom' model={expected_model!r}, auxiliary.free_only=True"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
