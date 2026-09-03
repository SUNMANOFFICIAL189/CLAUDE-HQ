# /proof-check RE-RUN — Hermes pilot P0 fence after T3e (2026-09-03, ~18:05 +08)

**Independence:** fresh Opus reviewer, read-only, one `hermes doctor` run + the fence unit tests (Codex unavailable). 147k tokens, 32 reads.
**Verdict: NOT CLEAN — 1 HIGH (NEW-1) / 4 MEDIUM / LOWs. 7 of 8 prior findings CLOSED; H4 PARTIAL.** Gate stays closed pending T3f + re-run #3.

## Closure table (prior findings)
| Finding | Verdict | Proof |
|---|---|---|
| H1 OAuth guard on last branch | CLOSED | `agent/anthropic_adapter.py:692 build_anthropic_client` raise = statement #1 before `_get_anthropic_sdk()`/endpoint branching; `create_anthropic_message:1208` unconditional first statement; `agent/auxiliary_client.py:4125 _try_anthropic` raises before the adapter import; test-proven |
| H2 `inherit_credentials=True` bypass | CLOSED | `tools/environments/local.py:850-852 _ALWAYS_STRIP_KEYS` has all three; `hermes_subprocess_env:891` pops Tier 1 unconditionally 17 lines before the `if not inherit_credentials` block (:908); docker.py / env_passthrough do not re-add |
| H3 fallbacks fail open | CLOSED | four sites default True + loud line (`local.py:439-443`, `auth.py:648-651`, `web_server.py:10926-10929`, `:11002-11005`); no fifth; six bare importers = crash = fail closed |
| H4 Codex/Copilot cosmetic | **PARTIAL** | registry pop live (`auth.py:616-623`, after every population path); login funcs + `CodexAppServerClient.__init__:82` + `CopilotACPClient._run_prompt:400` raise first-statement; doctor row gone — **but three hard subscripts remain → NEW-1** |
| H5 probe-2 positive control | CLOSED | `hermes-engine.sh:240 positive_control_probe` requires LEAK on both URLs, gated on `check_ollama_reachable_from_host:219` |
| H6 signal traps | CLOSED | `:386, :444` `trap … EXIT INT TERM HUP`; all four disarms match; no wall-down path exits without the trap |
| M7 three guard copies | CLOSED | exactly one definition (`anthropic_credentials.py:44`); adapter :91 and pool :25 import + re-export |
| M8 by-tag pull | CLOSED (with NEW-3/NEW-4 defects) | `select_probe_image:171` inspects IMG then the Dockerfile-parsed digest; returns 1, never pulls |

## New findings (T3e regressions / adjacent)
### 🟠 HIGH
**NEW-1 — registry pop left three hard subscripts → KeyError (fail-closed crash, not leak).** `hermes_cli/runtime_provider.py:559` (`elif provider == "copilot"` → `PROVIDER_REGISTRY["copilot"].inference_base_url`; :533 uses `.get()`, :559 does not); `hermes_cli/model_setup_flows.py:1821` (`"copilot"`) and `:2020` (`"copilot-acp"`) — second statement of the setup flow, outside any try; reachable because `hermes_cli/models.py:1315/1323/1324` still advertise "ChatGPT or Codex Subscription", "GitHub Copilot", "GitHub Copilot ACP" in the picker. **Fix (T3f):** `.get()` + explicit "disabled during the HQ pilot" refusal at the three sites; prune the three `ProviderEntry` rows in `models.py` as `doctor.py:1937` was.
### 🟡 MEDIUM
**NEW-2** — `hermes_cli/doctor.py:2817 _probe_anthropic` (registered unconditionally :3104) takes `get_anthropic_key()` and, if `_is_oauth_token(key)`, sends `Authorization: Bearer` + `_COMMON_BETAS + _OAUTH_ONLY_BETAS` to `api.anthropic.com/v1/models` via raw httpx — an OAuth-shaped value in `ANTHROPIC_API_KEY`/.env rides through (the H1 channel on a route H1 doesn't cover). Pre-existing. **Fix (T3f):** guard `_probe_anthropic` first-statement (`models.py:4729`, `account_usage.py:762` are safe — they use `resolve_anthropic_token()` → None).
**NEW-3** — bootstrap deadlock: on a clean machine `ensure`/`build-image` both hard-exit at `select_probe_image` and the hint says "run build-image first". **Fix (T3f):** drop the self-referential hint; `build-image` may pull the pinned digest itself while the wall is down under the positive control.
**NEW-4** — the M8 fail-closed message (`hermes-engine.sh:67-70`) is dead code: under `set -euo pipefail` a no-match `grep` kills the script at :62-65 with exit 1 and zero output — and the parse runs at top level, so a changed `FROM` format breaks `status`/`stop` too. **Fix (T3f):** `|| true` on the pipeline so the explicit check runs; parse the LAST `FROM`.
**NEW-5** — the three Tier-1 names (`local.py:850-852`) are hardcoded, not gated on the flag; flipping `HQ_PILOT_ANTHROPIC_DISABLED = False` (the documented single restore switch) leaves child spawns permanently without Anthropic credentials. **Fix (T3f):** add them conditionally on the flag.
### 🟢 LOW (→ BACKLOG)
`model_setup_flows.py:650/670` degrade to "Login failed: 'openai-codex'" (confusing, not a crash) · `trap_reapply_kill:160` swallows a failed re-apply with `|| true` (pre-existing) · bash defers INT/TERM traps until the foreground `docker build` returns · `CURL_BIN` silent exit if curl absent · `build_azure_foundry_anthropic_client:651` / `build_anthropic_bedrock_client:858` unguarded but authenticate with Entra/AWS (no subscription credential).

## Doctor + tests
`hermes doctor` closed-proxy: exit 0, no traceback, no Codex row; stderr = the two expected `get_anthropic_key skip …` lines. `tests.hq_pilot.test_fence`: 9/9 OK — real clauses, not tautologies. Coverage gaps: `test_exactly_one_guard_definition` scans only `agent/`; H3 fallbacks have no test (`# pragma: no cover`). Known casualty confirmed by reading: `tests/tools/test_hermes_subprocess_env.py:213-227` now contradicts H2 by design (pytest absent).

## Solid
Single-source guard; every fallback fails closed; H1 relocation structural; Tier-1 ordering proven by execution; registry pop after every population path; positive control falsifiable on both URLs; traps cover every wall-down window; comments cite the finding they close.

## Disposition
**T3f** (sonnet, small): NEW-1 (.get + refusal ×3, prune 3 picker rows), NEW-2 (guard `_probe_anthropic`), NEW-3 (hint), NEW-4 (`|| true`, last FROM), NEW-5 (flag-gated Tier-1), widen `test_exactly_one_guard_definition` to the whole tree + add an H3 test; commit both branches; doctor + tests + selftest. Then proof-check **re-run #3** (scoped to T3f's diff + the closure table). LOWs → BACKLOG residuals item.
