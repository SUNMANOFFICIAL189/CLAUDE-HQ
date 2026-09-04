#!/usr/bin/env python3
"""HQ Hermes pilot -- T8c-B aux-pins resolution-level proof (derived surfaces).

proof-check-s3-2026-09-04.md HIGH-2 (T8b fix): T8's "0 agent.auxiliary_client
lines in the post-pin errors.log window" proved nothing -- the window held 0
lines of ANY kind, meaning no auxiliary call was ever attempted (Lesson 34: a
check that cannot fail reproduced inside the very check written to enforce
it). T8b's fix checked the CONFIG-RESOLUTION layer directly instead, but only
for a hardcoded list of 10 surface names.

proof-check-s3-rerun-2026-09-04.md NEW HIGH: that hardcoded list covered 10
of the 18 real `DEFAULT_CONFIG["auxiliary"]` sub-dicts with a "provider" key
(it also still named the two retired ones, web_extract/session_search, which
no longer resolve through this path at all) -- so 8 live surfaces
(goal_judge, kanban_decomposer, mcp, memory_query_rewrite, moa_aggregator,
moa_reference, profile_describer, review, skills_hub, triage_specifier minus
whichever were already covered) were never checked and could silently drift
to provider "auto" without this script ever noticing.

Fix (T8c-B): derive the surface list at RUNTIME from
`hermes_cli.config_defaults.DEFAULT_CONFIG["auxiliary"]` -- every key whose
value is a dict with a "provider" key -- instead of a hand-maintained list.
An upstream addition or removal of an auxiliary surface changes what this
script checks on the next run, automatically, with no edit here.

For each derived surface this calls the exact symbol
`agent/auxiliary_client.py::_call_llm_impl` calls at its top to decide which
provider/model an auxiliary call would actually use --

    resolved_provider, resolved_model, resolved_base_url, resolved_api_key,
    resolved_api_mode = _resolve_task_provider_model(task, provider, model,
                                                      base_url, api_key)

-- and asserts it resolves to provider == "custom" and model == the
configured model.default, with the loaded config's auxiliary.free_only also
True. A surface is also failed if it is missing from the RAW (un-merged)
config.yaml on disk -- `_resolve_task_provider_model` reads through
`load_config_readonly()`, which deep-merges the user's file over
DEFAULT_CONFIG (see `hermes_cli/config.py::_deep_merge` /
`_load_config_impl`), so a surface block deleted from the actual file is
invisible to a check that only looks at the merged view; comparing against
`read_raw_config_readonly()` (no merge -- `hermes_cli/config.py`) catches
that case by name instead of only ever reporting a provider mismatch.

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


def main() -> int:
    from agent.auxiliary_client import _resolve_task_provider_model
    from hermes_cli.config import load_config_readonly, read_raw_config_readonly
    from hermes_cli.config_defaults import DEFAULT_CONFIG

    aux_defaults = DEFAULT_CONFIG.get("auxiliary") or {}
    surfaces = sorted(
        key
        for key, value in aux_defaults.items()
        if isinstance(value, dict) and "provider" in value
    )
    if not surfaces:
        print(
            "aux-resolution-check: FAIL -- derived 0 surfaces from "
            "DEFAULT_CONFIG['auxiliary']; something upstream changed shape",
            file=sys.stderr,
        )
        return 1

    config = load_config_readonly()
    raw_config = read_raw_config_readonly()
    expected_model = (config.get("model") or {}).get("default")
    free_only = (config.get("auxiliary") or {}).get("free_only")
    raw_auxiliary = (raw_config.get("auxiliary") or {}) if isinstance(raw_config, dict) else {}

    if free_only is not True:
        print(
            f"aux-resolution-check: FAIL -- auxiliary.free_only is {free_only!r}, expected True",
            file=sys.stderr,
        )
        return 1

    failures = []
    for surface in surfaces:
        raw_surface_cfg = raw_auxiliary.get(surface) if isinstance(raw_auxiliary, dict) else None
        if not isinstance(raw_surface_cfg, dict) or "provider" not in raw_surface_cfg:
            print(
                f"FAIL {surface}: missing from the loaded config "
                f"(no auxiliary.{surface}.provider in the raw config.yaml)"
            )
            failures.append(surface)
            continue

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
        f"aux-resolution-check: PASS -- all {len(surfaces)} surfaces (derived from "
        f"DEFAULT_CONFIG['auxiliary']) resolve to provider='custom' "
        f"model={expected_model!r}, auxiliary.free_only=True"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
