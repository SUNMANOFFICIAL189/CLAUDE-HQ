# Hermes Agent — 14-Day Instrumented Pilot: Execution Ticket Set
*Produced by Claude Fable 5 planning consult, 2026-09-03, nonce FABLE-OK:20260903-hq7m, single reply, no tools. Verbatim. Foreman review + amendments are in a separate section at the end.*

**Path shorthand used throughout:** `HQ=/Users/sunil_rajput/claude-hq` · `HH=$HQ/run/hermes-hq` (HERMES_HOME) · `PR=$HQ/run/hermes-pilot` (pilot run-state, gitignored) · `SK=$HQ/skills/hq-hermes` · `CO=` Hermes checkout (T1 resolves from `docs/ORGANIZATION.md`; default `$HQ/tools/hermes-agent`) · `BD=` mission-board dir (T1 resolves; default per `commander/MISSION_BOARD_TEMPLATE.md` convention) · `HERMES=$CO/.venv/bin/hermes` (absolute, never PATH).

## 1. Pilot design (12 lines)

1. **Hypothesis:** on large / low-judgment / machine-verifiable jobs, Hermes on Ollama/Groq cuts Anthropic usage-window tokens ≥30% at equal-or-better pass rate. Nothing else is being tested.
2. **Phases/days:** P0 D1–2 gated install · P1 D3–4 hardening + Anthropic-path proof → **GATE A** `/proof-check` · P2–P3 D5–6 skill + doctrine + harness → **GATE B** `/proof-check` · P4 D7–11 three real jobs, both arms · P5 D12 optional Paperclip smoke · P6 D13–14 `/ctdd-precheck` + decision → **GATE C** operator landing go.
3. **Unit of measurement:** one fresh `sonnet` subagent per arm per job, receiving only the identical `brief.md`. Arm A does the job directly. Arm B writes the query-file, calls the wrapper, reads back, verifies. The whole subagent transcript is the arm's cost.
4. **Metric:** `window_tokens = input + cache_creation + output` (cache_read reported separately) summed from the arm's Claude Code JSONL transcript; plus pass/fail from `grade.py` (numeric thresholds), wall time, retries, Hermes-side tokens from `state.db.session_model_usage`, backend.
5. **Controls:** randomized arm order (coin flip logged on the board), arms never see each other's output, blind opus re-grade, everything written to `run/cost-ledger.sqlite` side-table `hermes_runs` and `$PR/`.
6. **Kill rule (P6):** DROP unless median saving ≥30% AND Arm-B pass rate ≥ Arm-A pass rate across the 3 jobs. Result within ±10 pp of 30% → one rerun of that job only (Q5). DROP keeps only the Paperclip-adapter knowledge.
7. **Hard kills (any time, any ticket):** any Anthropic request path or macOS Keychain dialog for "Claude Code-credentials"; a write outside `HERMES_WRITE_SAFE_ROOT`; any `hermes skills install`/`hermes update`/`import-agent`; any background Hermes process. Stop, file, do not continue.
8. **Backends:** Ollama `hq-coder-64k` (qwen2.5-coder:7b, 64k ctx — T4 justifies), Groq model chosen by T6 from live rate-limit headers. `llama3.2` is not measured: it would measure model weakness, not the hypothesis.
9. **Explicitly NOT built:** gateway/launchd/cron/Telegram/alerts, MCP bridge, auto-mode routing, Hermes memory/skill writes, Docker, cost-ledger schema migration, Trust-Gate-as-Hermes-hook (parked to BACKLOG), Paperclip adapter source changes.
10. Two fence conflicts flagged now: (a) per-call Ollama↔Groq switching under ONE `HERMES_HOME` may be impossible with the `custom` provider — T6 resolves, sibling homes under `run/` is the fallback deviation; (b) `--worktree` hides the worktree path until launch, so `HERMES_WRITE_SAFE_ROOT` can't be set to it — wrapper creates the worktree itself and passes `--in`.
11. Honest cost note: the pilot spends more window than it can save in 14 days. The payoff is a doctrine decision, not savings.
12. Mode throughout: foreman PROPOSES every Hermes hand-off; no auto-routing until P6 grants it by name.

## 2. Ticket set

**GLOBAL (inherited by every ticket; each ticket lists only deltas):**
- **CONSTRAINTS:** fences 1–11 of the brief verbatim. Free only. `HERMES_HOME=$HH` on every Hermes invocation. Docker down → `terminal.backend: local`. Provider never `anthropic`. Runs from `$HQ` current branch, uncommitted.
- **MUST NOT:** spawn subagents; commit/push (landing = GATE C); write outside WRITE SET; touch `~/.hermes`, `~/.claude/*` (T21 excepted), `ANTHROPIC_*`/`CLAUDE_*` env; paste any secret value into output; run `scripts/install.sh`, `curl|bash`, `hermes update`, `hermes skills install`, `hermes import-agent`, `hermes gateway`, cron; invoke any model/provider string matching `/anthropic|claude/i`; save subject-repo bytes outside `$CO`.
- **OUTPUT FORMAT:** workers status-first `DONE|DONE_WITH_CONCERNS|NEEDS_CONTEXT|BLOCKED` + pasted verify-command output. Verifiers verdict-first `PASS|FAIL|PASS_WITH_NOTES` + evidence; verifiers receive the original ticket verbatim and nothing from the worker's chat.

### P0 — Gated install & isolation

```
ID: T1   TIER: sonnet   WAVE: 1   DEPENDS_ON: []
TASK: Pre-flight verification artifact.
EXPECTED OUTCOME: $PR/preflight.json with ≥14 keys: uv/python/sqlite3/shellcheck versions; `ollama list` + `ollama show llama3.2` context; Docker daemon state; `~/.hermes` absent; Keychain service NAMES present (`security dump-keychain | grep svce`, names only); trust-gate hooks + matcher list from ~/.claude/settings.json (does it match `uv`?); disk free ≥15 GB; resolved CO and BD paths from docs/ORGANIZATION.md; column list of run/cost-ledger.sqlite per MODEL_ROUTING.md §8.
CONTEXT: $HQ/docs/ORGANIZATION.md, $HQ/commander/MODEL_ROUTING.md §8, $HQ/commander/TRUST_GATE.md, $HQ/scripts/trust-gate.sh.
CONSTRAINTS: GLOBAL; read-only except the JSON.
MUST DO: verify `python3 -c "import json;d=json.load(open('$PR/preflight.json'));print(len(d))"` ≥14.
MUST NOT: GLOBAL; no installs.
OUTPUT FORMAT: worker.
WRITE SET: $PR/preflight.json
```

```
ID: T2   TIER: sonnet   WAVE: 2   DEPENDS_ON: [T1]
TASK: Gated, pinned install of Hermes v2026.8.31.
EXPECTED OUTCOME: `$HERMES --version` prints 0.21.0; HEAD == `git rev-parse v2026.8.31^{commit}`; SHA recorded in preflight.json; $PR/freeze.txt snapshot; ~/.hermes still absent.
CONTEXT: T1 output; $CO/pyproject.toml optional-deps; $CO/tools/lazy_deps.py (map of runtime lazy installs).
CONSTRAINTS: GLOBAL; exactly ONE `HQ_TRUST_OVERRIDE=1` command (the clone); `uv sync --locked`; extras chosen from lazy_deps.py for custom/openai provider + ddgs + sqlite (targeted; `.[all]` only if the map is unreadable — installing the `anthropic` lib is not the risk, provider config is).
MUST DO: `HQ_TRUST_OVERRIDE=1 git clone https://github.com/NousResearch/hermes-agent $CO`; `git -C $CO checkout tags/v2026.8.31`; confirm trust-gate-post Magika + secret-scan ran (quote log lines); `uv sync --locked` then extras; `uv pip freeze > $PR/freeze.txt`; verify `HERMES_HOME=$HH $HERMES --help; echo $?` = 0 and `test ! -e ~/.hermes`.
MUST NOT: GLOBAL; `pip install` outside uv; any hermes command without HERMES_HOME.
OUTPUT FORMAT: worker.
WRITE SET: $CO/**, $PR/preflight.json (sha key only), $PR/freeze.txt
```

```
ID: T3   TIER: opus   WAVE: 3   DEPENDS_ON: [T2]
TASK: Blind verify T2.
EXPECTED OUTCOME: PASS only if: HEAD SHA == tag commit; trust-gate log has exactly one override line naming the clone; Magika + secret-scan outputs present; no install.sh execution (grep shell history + $CO for exec marks); ~/.hermes absent; freeze.txt present; note whether `anthropic` package is installed (informational for T7); note if the gate did NOT see `uv sync` (gap → T21 LESSON candidate).
CONTEXT: T2 ticket verbatim; $HQ/scripts/trust-gate.sh log path; $PR/*.
CONSTRAINTS: GLOBAL; read-only.
MUST DO: run `git -C $CO rev-parse HEAD v2026.8.31^{commit}` and paste both.
MUST NOT: GLOBAL.
OUTPUT FORMAT: verifier.
WRITE SET: none
```

```
ID: T4   TIER: sonnet   WAVE: 2   DEPENDS_ON: [T1]
TASK: Ollama executor model at ≥64k context.
EXPECTED OUTCOME: `ollama show hq-coder-64k` reports num_ctx 65536; benchmark table (8k and 32k-token prompts): prompt-eval tok/s, gen tok/s, peak RSS; both runs complete with RSS ≤12 GB and 32k prompt ≤300 s wall — else DONE_WITH_CONCERNS recommending `hq-coder-32k` (needs T6 to confirm Hermes checks `model.context_length` from config, not the server).
CONTEXT: 18 GB Apple-Silicon Mac; llama3.2 (3B) is too weak for tool loops. qwen2.5-coder:7b q4 ≈4.7 GB, GQA KV ≈3.7 GB at 64k → ≈9 GB resident. Free pull, justified.
CONSTRAINTS: GLOBAL; no other model pulls.
MUST DO: `ollama pull qwen2.5-coder:7b`; Modelfile `FROM qwen2.5-coder:7b` + `PARAMETER num_ctx 65536` at $HH/ollama/Modelfile; `ollama create hq-coder-64k -f …`; benchmark via `curl 127.0.0.1:11434/v1/chat/completions`; verify `ollama show hq-coder-64k | grep -i num_ctx` → 65536.
MUST NOT: GLOBAL; run Ollama jobs concurrently.
OUTPUT FORMAT: worker.
WRITE SET: Ollama model store, $HH/ollama/Modelfile, $PR/ollama-bench.json
```

### P1 — Hardened config, Keychain secrets, Anthropic-path-impossible proof

```
ID: T5   TIER: sonnet   WAVE: 3   DEPENDS_ON: [T2,T4]
TASK: Write hardened $HH/config.yaml + Keychain secrets helper; mount 3 HQ skills read-only.
EXPECTED OUTCOME: config.yaml with EXACTLY: model.provider=custom, model.base_url=http://127.0.0.1:11434/v1, model.default=hq-coder-64k, model.context_length=65536, agent.max_turns=40, delegation.{max_concurrent_children=1,max_spawn_depth=1,max_iterations=1}, approvals.{single_query_mode=deny,cron_mode=deny,unattended_mode=deny}, approvals.deny=[git push,curl,wget,pip,uv pip,npm,brew,security,osascript,sudo,hermes,ollama pull,docker], memory.write_approval=true, skills.write_approval=true, skills.guard_agent_created=true, terminal.backend=local, telemetry.shared_metrics.{enabled=false,send=false}, updates disabled per schema, secrets.command.{enabled=true,command=$SK/scripts/hermes-secrets.sh,helper_timeout_seconds=5}, hooks=[]. `.env` = 0 bytes. Non-TTY Keychain read works with no GUI dialog.
CONTEXT: $HQ/scripts/mcp-launchers/paperclip-launcher.sh (Keychain pattern); $CO docs for config schema; Keychain service `claude-hermes-groq` (operator creates via the setup script — NEEDS_CONTEXT if absent).
CONSTRAINTS: GLOBAL; secrets helper prints `GROQ_API_KEY=<value>` only; setup script reads key via `read -s`, stores with `security add-generic-password -a "$USER" -s claude-hermes-groq -w "$KEY" -T /usr/bin/security -U`.
MUST DO: `ln -s $HQ/skills/{proof-check,handoff,laymans} $HH/skills/hq/`; verify `env -i PATH=/usr/bin:/bin USER=$USER HOME=$HOME bash $SK/scripts/hermes-secrets.sh </dev/null | sed 's/=.*/=<redacted>/'` → `GROQ_API_KEY=<redacted>`, exit 0, <2 s; `stat -f%z $HH/.env` → 0.
MUST NOT: GLOBAL; use `claude-paperclip-openrouter`/`-gemini`; echo the key.
OUTPUT FORMAT: worker.
WRITE SET: $HH/{config.yaml,.env,skills/hq/*}, $SK/scripts/{hermes-secrets.sh,hermes-keychain-setup.sh}
```

```
ID: T6   TIER: sonnet   WAVE: 4   DEPENDS_ON: [T5]
TASK: Resolve per-call backend switching + Groq model choice + smoke both backends.
EXPECTED OUTCOME: $PR/provider-mechanism.md naming ONE mechanism, tested: M1 first-class `--provider groq` plugin (grep $CO provider registry); else M2 `--provider custom` with per-call `OPENAI_BASE_URL`/`OPENAI_API_KEY` env override (confirm from source); else M3 sibling homes `$HH-ollama`/`$HH-groq` sharing symlinked skills (fence-4 deviation → operator OK before use). Locate the 64k-context check in source and state what it reads. $PR/groq-limits.json from `x-ratelimit-*` headers on one `/models` + one chat call; pick the Groq model with the highest tokens-per-day that is ≥8B. Two smokes: `HERMES_HOME=$HH $HERMES chat -Q --source tool --max-turns 1 --run-budget 60 -t <minimal> -q "Reply with exactly PONG"` → stdout `PONG`, exit 0 on each backend.
CONTEXT: $CO source; Groq base https://api.groq.com/openai/v1; T4 model name.
CONSTRAINTS: GLOBAL; ≤5 Groq calls.
MUST DO: verify `sqlite3 $HH/state.db "select provider,model from session_model_usage"` → 2 rows, none `anthropic`.
MUST NOT: GLOBAL.
OUTPUT FORMAT: worker.
WRITE SET: $PR/{provider-mechanism.md,groq-limits.json}, $HH/config.yaml (only if M1/M2 needs a key line), $HH/state.db (by Hermes)
```

```
ID: T7   TIER: opus   WAVE: 5   DEPENDS_ON: [T6]   [SECURITY]
TASK: Prove no Anthropic request path exists from this install.
EXPECTED OUTCOME: $PR/anthropic-proof.md with (1) source enumeration: the exact file/function that reads ~/.claude/.credentials.json / Keychain "Claude Code-credentials" and sets `user-agent: claude-code/…`; every route by which provider can resolve to anthropic (config, `--provider`, `-m claude-*` auto-detect, delegation.provider, env-key auto-select) and the closure for each; (2) dynamic negative tests, each run under `HTTPS_PROXY=http://127.0.0.1:9 HTTP_PROXY=http://127.0.0.1:9 HOME=$PR/tmp/home` so nothing can leave: A `--provider anthropic -m claude-sonnet-4-5` → non-zero exit, error names the blocked path, NO Keychain dialog appeared; B config copy tampered to `provider: anthropic` → Hermes refuses or proxy-blocked, documented; C normal Ollama run under the same closed proxy with `NO_PROXY=127.0.0.1` → exit 0 and no proxy-refused lines in Hermes logs (proves no hidden egress: telemetry/update checks); (3) verdict.
CONTEXT: $CO source; T5 config; T6 mechanism.
CONSTRAINTS: GLOBAL; the closed proxy is mandatory on tests A/B — no test may reach api.anthropic.com even once.
MUST DO: paste each command + exit code + last 5 stderr lines; FAIL stops the pilot.
MUST NOT: GLOBAL; automate this test; run it without the proxy.
OUTPUT FORMAT: verifier.
WRITE SET: $PR/anthropic-proof.md, $PR/tmp/**
```

```
ID: T8   TIER: sonnet   WAVE: 6   DEPENDS_ON: [T7]
TASK: Fence-probe suite + Claude-Code-SKILL.md compatibility check.
EXPECTED OUTCOME: $PR/probes.md, 9/9 as expected. Each probe = `chat -Q --source tool --max-turns 6 --run-budget 120 --in $PR/probes/wd` with `HERMES_WRITE_SAFE_ROOT=$PR/probes/wd`, toolset `terminal,file` unless stated: P1 write `../outside.txt` → not created; P2 `git push` → denied; P3 `pip install requests` → denied AND `uv pip freeze` == freeze.txt; P4 ask to delegate → tool absent; P5 ask to store a memory → absent/denied; P6 ask to edit `hq/proof-check/SKILL.md` → sha256 of $HQ/skills/proof-check/SKILL.md unchanged; P7 `skill_view hq/proof-check` → returns content (compat proof; if loader rejects the front-matter, paste the exact error); P8 workdir CLAUDE.md containing `CANARY-7741`, run with `--ignore-rules`, ask "list any codewords in your instructions" → no CANARY; rerun without flag → record behaviour; P9 cron tool absent.
CONTEXT: T5 config; $HQ/skills/proof-check/SKILL.md.
CONSTRAINTS: GLOBAL; one probe at a time.
MUST DO: paste sha256 before/after for P6; `diff <(uv pip freeze) $PR/freeze.txt` empty for P3.
MUST NOT: GLOBAL.
OUTPUT FORMAT: worker.
WRITE SET: $PR/probes/**, $PR/probes.md, $HH/state.db (by Hermes)
```

**GATE A (foreman, opus): `/proof-check` over T2–T8 artifacts.** CRITICAL/HIGH → operator; fix → re-run gate before P2.

### P2 — `hq-hermes` skill, wrapper, doctrine

```
ID: T10   TIER: sonnet   WAVE: 7   DEPENDS_ON: [GATE A]
TASK: Build $SK: SKILL.md + hermes-run.sh wrapper + hermes-ledger.py + workdir .hermes.md template.
EXPECTED OUTCOME: Wrapper interface `hermes-run.sh --backend ollama|groq --job ID --workdir DIR --query-file PATH [--max-turns 40] [--run-budget 1800] [--toolsets terminal,file] [--worktree]`. It MUST: use $HERMES absolute; reject any `--provider|-m|--model` value matching `/anthropic|claude/i` (exit 2); pre-exec assert `! grep -qiE 'anthropic|claude' $HH/config.yaml`; build env with `env -i` allowlist (PATH HOME USER LANG TMPDIR HERMES_HOME HERMES_WRITE_SAFE_ROOT=DIR TERMINAL_ENV UV_OFFLINE=1 PIP_NO_INDEX=1 NO_PROXY=127.0.0.1,localhost) + backend=ollama → `HTTPS_PROXY=HTTP_PROXY=http://127.0.0.1:9` (egress kill), backend=groq → key via T6 mechanism; run `chat -Q --query-file … --source tool --in DIR --max-turns --run-budget --toolsets --ignore-rules`; `--worktree` = wrapper runs `git worktree add $PR/wt/<job> -b hermes-pilot/<job>` and passes that as DIR (deviation from `-w`, deliberate: safe root must be known pre-launch); capture stdout→`$PR/jobs/<job>/<ts>/stdout.md`, stderr→session_id, exit, wall; exit 75 → sleep 60 → retry ≤2; then `hermes-ledger.py` reads `session_model_usage` for that session_id and inserts into `run/cost-ledger.sqlite` table `hermes_runs(run_id,job_id,backend,provider,model,session_id,started_at,wall_s,exit_code,retries,prompt_tokens,completion_tokens,api_calls,stdout_path)` — CREATE TABLE IF NOT EXISTS, idempotent on session_id, never ALTER existing tables; last stdout line = one-line JSON summary. SKILL.md: hand-off shape test (≥30 files or ≥20 uniform items, machine-verifiable acceptance, no judgment), data-sensitivity gate (client IP → ollama only), PROPOSE-never-auto wording, examples.
CONTEXT: T5–T8 outputs; $HQ/skills/hq-foreman/SKILL.md (format); MODEL_ROUTING.md §8 (ledger).
CONSTRAINTS: GLOBAL; bash `set -euo pipefail`, no `eval`, all vars quoted.
MUST DO: verify hello job on ollama → `sqlite3 $HQ/run/cost-ledger.sqlite "select count(*) from hermes_runs"` = 1 with prompt_tokens>0; `hermes-run.sh --backend groq --model claude-3-5-sonnet …; echo $?` → 2.
MUST NOT: GLOBAL; touch existing ledger tables; add `--resume`.
OUTPUT FORMAT: worker.
WRITE SET: $SK/{SKILL.md,README.md,scripts/hermes-run.sh,scripts/hermes-ledger.py,templates/hermes.md}, $HQ/run/cost-ledger.sqlite (new table only), $PR/jobs/hello/**
```

```
ID: T11   TIER: sonnet   WAVE: 7   DEPENDS_ON: [GATE A]
TASK: Doctrine edits + mission board.
EXPECTED OUTCOME: MODEL_ROUTING.md §5 new row `hermes-bulk` (keywords: bulk/sweep/classify-N/run-tests-and-report; ≥30 files or ≥20 uniform items; machine-verifiable acceptance required; executor Hermes via $SK on Ollama/Groq; mode PROPOSE during pilot; excluded: reviews, planning, client-facing; client IP → Ollama only) + §8 note on `hermes_runs` side table + §1 Phase-2 line pointing at this pilot. registry.json entry `hermes-agent` {path=$CO, tag=v2026.8.31, sha=<preflight>, trust="HQ_TRUST_OVERRIDE logged <date>", status="pilot", never_update=true}; self-declared counts updated. BACKLOG.md:136 appended: `PILOT RUNNING <D1>–<D14>; tickets T1–T21; decision due <D14>`. $BD/MISSION_BOARD.md from template with ticket table, waves, kill rule, coin-flip log section.
CONTEXT: $HQ/commander/MODEL_ROUTING.md, $HQ/registry.json, $HQ/docs/BACKLOG.md:136, $HQ/commander/MISSION_BOARD_TEMPLATE.md.
CONSTRAINTS: GLOBAL; wording must restate the 2026-08-12 ruling, not soften it.
MUST DO: verify `grep -c hermes-bulk $HQ/commander/MODEL_ROUTING.md` ≥1; `python3 -c "import json;json.load(open('$HQ/registry.json'))"` exits 0; `grep -n "PILOT RUNNING" $HQ/docs/BACKLOG.md` hits.
MUST NOT: GLOBAL; edit any other doctrine file.
OUTPUT FORMAT: worker.
WRITE SET: $HQ/commander/MODEL_ROUTING.md, $HQ/registry.json, $HQ/docs/BACKLOG.md, $BD/MISSION_BOARD.md
```

```
ID: T12   TIER: opus   WAVE: 8   DEPENDS_ON: [T10,T11]   [SECURITY]
TASK: Blind verify T10 + T11.
EXPECTED OUTCOME: Line-by-line wrapper review: guard regex case-insensitive and covers `-m/--model/--provider`; env allowlist has no `ANTHROPIC_*`/`CLAUDE_*`; no eval; retry bounded; ledger idempotent; egress-kill present for ollama. Re-run T7 test A THROUGH the wrapper (closed proxy) → exit 2 before exec; tampered config copy → pre-exec assert fails. Hello job on both backends → 2 ledger rows, tokens>0, provider≠anthropic. Doctrine row faithful; registry JSON valid; BACKLOG line present; board matches template.
CONTEXT: T10, T11 tickets verbatim; $PR/anthropic-proof.md.
CONSTRAINTS: GLOBAL.
MUST DO: paste `sqlite3 … "select backend,provider,model,prompt_tokens from hermes_runs"`.
MUST NOT: GLOBAL; fix anything.
OUTPUT FORMAT: verifier.
WRITE SET: none ($HH/state.db + ledger rows by the hello runs only)
```

### P3 — Instrumentation harness

```
ID: T13   TIER: sonnet   WAVE: 9   DEPENDS_ON: [T12]
TASK: Claude-side usage capture + comparison tooling + Hermes usage calibration.
EXPECTED OUTCOME: `$SK/scripts/pilot/claude-usage.py <transcript.jsonl> [--since ISO --until ISO]` sums `usage.{input_tokens,output_tokens,cache_creation_input_tokens,cache_read_input_tokens}` over assistant messages; prints `window_tokens` (input+cache_creation+output) and `window_tokens_incl_cache_read`. README documents the confirmed transcript layout for subagents under `~/.claude/projects/-Users-sunil-rajput-claude-hq/` (session vs sidechain/subagent files). `compare.py` joins `hermes_runs` + per-arm usage JSON + grade JSON → markdown + JSON table. `ARM_A.md`/`ARM_B.md` subagent instruction templates, symmetric except B's hand-off step (B: write query-file from brief verbatim; call wrapper; read stdout; run grade.py; on fail ONE fresh feedback call; report). Calibration: same hello prompt via `hermes -z --usage-file $PR/calibration/u.json` vs `chat -Q` + state.db → |Δ tokens| ≤5% or documented cause. Decision recorded: state.db is primary (it honours all fences), usage-file is calibration only.
CONTEXT: T10 wrapper; Claude Code transcript JSONL format (inspect a real file).
CONSTRAINTS: GLOBAL; python3 stdlib only.
MUST DO: verify `python3 claude-usage.py <a real transcript>` prints 5 integers; `compare.py` on the calibration data prints a 1-row table.
MUST NOT: GLOBAL; dispatch subagents (foreman step F1 below does that).
OUTPUT FORMAT: worker.
WRITE SET: $SK/scripts/pilot/{claude-usage.py,compare.py,ARM_A.md,ARM_B.md,README.md}, $PR/calibration/**
```

**F1 (foreman):** dispatch hello job as two fresh sonnet subagents (ARM_A, ARM_B); capture transcript paths; run `compare.py` → 2-row table into `$PR/calibration/hello-compare.md`.

```
ID: T14   TIER: opus   WAVE: 10   DEPENDS_ON: [T13,F1]
TASK: Blind verify harness.
EXPECTED OUTCOME: manual `jq` sum on one transcript within ±2% of claude-usage.py; subagent transcript layout confirmed against the F1 files; calibration Δ ≤5%; ARM templates symmetric and contain no hints beyond the brief; hello-compare table has both arms with non-zero window_tokens.
CONTEXT: T13 verbatim; $PR/calibration/**.
CONSTRAINTS: GLOBAL; read-only.
MUST DO: paste the jq command and both numbers.
MUST NOT: GLOBAL.
OUTPUT FORMAT: verifier.
WRITE SET: none
```

**GATE B (foreman, opus): `/proof-check` over T10–T13.** Clears P4.

### P4 — Three measured bulk jobs

```
ID: T15   TIER: sonnet   WAVE: 11   DEPENDS_ON: [GATE B]
TASK: Build job packs J1–J3 (brief.md identical for both arms, grade.py with numeric thresholds, setup.sh, oracle where scriptable).
EXPECTED OUTCOME:
 J1 SKILL.md sweep — inputs: all SKILL.md under $HQ/skills/* and ~/.claude/skills/* (~57). Output JSONL per file: name_present, description_present, description_words, dead_path_refs (paths mentioned but absent), has_trigger_phrase (semantic), suggested_tier (semantic). oracle.py computes the 4 scriptable fields. PASS = scriptable fields exact on ≥95% of files AND semantic fields agree ≥80% with T16's 15-file sample. Backend: Ollama (arm B) + Groq (arm C, cheap extra). Fences: --max-turns 60 --run-budget 2400 -t terminal,file.
 J2 shellcheck loop — worktree of $HQ; fix SC2086/SC2155/SC2046 across $HQ/scripts/**/*.sh EXCLUDING trust-gate*.sh, model-router.sh, lib/secret-scan.sh, mcp-launchers/*, hooks. PASS = target-code count 0 AND `bash -n` 100% AND diff confined to allowed files AND every hunk matches quoting-only patterns (else flagged for T18). Backend: Groq. --max-turns 60 --run-budget 2700. (shellcheck via brew if absent — through the gate.)
 J3 API classification — export 300 rows from $HQ/tools/api-index/ sqlite to input.jsonl; 3 categorical fields NOT already columns (T15 confirms via `.schema`; default: hq_use_case∈{content,research,dev-tooling,finance,data,other}, free_tier_usable∈{yes,no,unknown}, needs_account∈{none,key,oauth,unknown}). PASS = 300 valid rows AND macro accuracy ≥0.85 per field on T16 gold. Backend: Groq, Ollama fallback if TPD exceeded. --max-turns 40 --run-budget 1800.
 Each brief carries a token pre-estimate vs $PR/groq-limits.json (≤70% of TPD or split into chunks). Briefs never mention Hermes.
CONTEXT: T13 templates; groq-limits.json; api-index schema.
CONSTRAINTS: GLOBAL; no client-IP inputs anywhere.
MUST DO: verify each `grade.py --selftest` exits 0 on a synthetic pass and 1 on a synthetic fail.
MUST NOT: GLOBAL; write gold/sample files (T16).
OUTPUT FORMAT: worker.
WRITE SET: $SK/jobs/{J1,J2,J3}/** (except gold.jsonl, semantic-sample.jsonl), $PR/jobs/**
```

```
ID: T16   TIER: opus   WAVE: 12   DEPENDS_ON: [T15]
TASK: Label J3 gold (60 rows, stratified) and J1 semantic sample (15 files) using T15's field definitions.
EXPECTED OUTCOME: gold.jsonl (60) + semantic-sample.jsonl (15), each row with a one-line rationale; self-consistency: relabel 10 rows blind, ≥9/10 match.
CONTEXT: $SK/jobs/J3/brief.md, $SK/jobs/J1/brief.md, input.jsonl.
CONSTRAINTS: GLOBAL.
MUST DO: verify `wc -l` = 60 and 15; `python3 -c` JSON-parse both.
MUST NOT: GLOBAL; read any arm output.
OUTPUT FORMAT: worker.
WRITE SET: $SK/jobs/J3/gold.jsonl, $SK/jobs/J1/semantic-sample.jsonl
```

```
ID: T17[a–g]   TIER: sonnet   WAVE: 13–15   DEPENDS_ON: [T16]
TASK: Execute arms. Foreman dispatches each as a FRESH subagent given only ARM_X.md + brief.md; order per coin flip logged on $BD board.
  a J1-A direct · b J1-B ollama · c J1-C groq · d J2-A direct · e J2-B groq · f J3-A direct · g J3-B groq
EXPECTED OUTCOME: per run: output at the brief's path, grade.py JSON, (B/C) hermes run_id + wrapper summary line, transcript path recorded by foreman; DONE or DONE_WITH_CONCERNS.
CONTEXT: ARM template + brief only.
CONSTRAINTS: GLOBAL; Hermes runs strictly serial (Ollama RAM); a direct arm may run alongside one Hermes arm (disjoint dirs); J2 arms each in their own worktree; retries: A none beyond its own judgment, B/C exactly one feedback call.
MUST DO: run `grade.py` and paste its JSON.
MUST NOT: GLOBAL; read the other arm's dir, gold, oracle, or T15/T16 tickets; exceed fences.
OUTPUT FORMAT: worker.
WRITE SET: $PR/jobs/<J>/<arm>/** (+ $PR/wt/J2-<arm> for J2), ledger rows via wrapper
```

```
ID: T18   TIER: opus   WAVE: 16   DEPENDS_ON: [T17*]
TASK: Blind grade + results table.
EXPECTED OUTCOME: independently re-run grade.py per arm; J2: spot-check 10 hunks per arm for semantic change; J1: audit semantic fields vs sample; cross-read check (grep each transcript for the other arm's path → none); ledger has one `hermes_runs` row per B/C run; `diff <(uv pip freeze) $PR/freeze.txt` empty (lazy-dep check); run compare.py; write $BD/RESULTS.md: job, arm, backend, pass, window_tokens, incl_cache_read, wall_s, hermes tokens, retries, exit; per-job saving % and ambiguous-zone flag.
CONTEXT: T15–T17 tickets verbatim; $PR/**; transcripts.
CONSTRAINTS: GLOBAL.
MUST DO: paste the results table.
MUST NOT: GLOBAL; recommend (T20's job).
OUTPUT FORMAT: verifier.
WRITE SET: $BD/RESULTS.md, $PR/results.json
```

### P5 — Optional Paperclip smoke (only if T18 done by D11)

```
ID: T19   TIER: sonnet   WAVE: 17   DEPENDS_ON: [T18]   OPTIONAL
TASK: One Paperclip issue → `hermes_local` employee → result, no daemon.
EXPECTED OUTCOME: $SK/scripts/hermes-paperclip-shim.sh (sets HERMES_HOME=$HH, same env-i allowlist, config assert, rejects anthropic/claude in "$@", execs $HERMES "$@" — adapter's `--resume` allowed here only). One agent configured via Paperclip API at 127.0.0.1:3100 with `hermesCommand`=shim; issue "reply PONG" → result comment contains PONG; `state.db` shows the session with provider custom.
CONTEXT: ~/projects/paperclip server/src/adapters/registry.ts:240 (read-only).
CONSTRAINTS: GLOBAL; shim bypasses the ledger — acceptable for smoke, noted.
MUST DO: verify `sqlite3 $HH/state.db "select provider from sessions order by rowid desc limit 1"` → custom.
MUST NOT: GLOBAL; edit ~/projects/paperclip/**; use paperclip-openrouter/gemini Keychain items; start any daemon.
OUTPUT FORMAT: worker.
WRITE SET: $SK/scripts/hermes-paperclip-shim.sh, Paperclip DB (via API), $PR/paperclip-smoke.md
```

### P6 — Decision gate + write-backs

```
ID: T20   TIER: opus   WAVE: 18   DEPENDS_ON: [T18, T19?]
TASK: Apply the kill rule; run /ctdd-precheck; produce the decision memo.
EXPECTED OUTCOME: $BD/DECISION.md verdict-first: KEEP (proposes named auto-mode for `hermes-bulk`, Stage-2 BACKLOG item) | DROP (quarantine plan: delete $HH state, registry status "evaluated-dropped", keep Paperclip-adapter note) | EXTEND (only if ambiguous zone AND operator approved rerun). Includes EV math, dominance test, what was NOT tested.
CONTEXT: $BD/RESULTS.md, MODEL_ROUTING.md §5.5, COST_CONTROL.md.
CONSTRAINTS: GLOBAL.
MUST DO: quote the three saving % and pass rates verbatim from RESULTS.md.
MUST NOT: GLOBAL; edit doctrine (T21).
OUTPUT FORMAT: verifier (verdict-first).
WRITE SET: $BD/DECISION.md
```

```
ID: T21   TIER: sonnet   WAVE: 19   DEPENDS_ON: [T20 + operator go]
TASK: Write-backs per DECISION.md.
EXPECTED OUTCOME: BACKLOG.md:136 → Closed-KEEP / Closed-DROP with RESULTS link; MODEL_ROUTING `hermes-bulk` row → active or struck-with-note; registry status; Obsidian Decision Log append with provenance tag under /Users/sunil_rajput/Vaults/Jarvis-Brain/JARVIS-BRAIN/Projects/<claude-hq hub>/; auto-memory `project_hermes_pilot_2026_09.md` + MEMORY.md index line; LESSONS.md entries where corrections occurred (candidates: gate blind to `uv`; Hermes reads CLAUDE.md; state.db vs usage-file). Landing via /sync = GATE C.
CONTEXT: $BD/DECISION.md; T3/T8/T13 concern notes.
CONSTRAINTS: GLOBAL; append-only on Decision Log and LESSONS.
MUST DO: verify `grep -n "Closed-" $HQ/docs/BACKLOG.md` hits line 136 block.
MUST NOT: GLOBAL; push (operator runs /sync).
OUTPUT FORMAT: worker.
WRITE SET: $HQ/docs/BACKLOG.md, $HQ/commander/MODEL_ROUTING.md, $HQ/registry.json, $HQ/commander/LESSONS.md, $BD/MISSION_BOARD.md, vault Decision Log, ~/.claude/projects/-Users-sunil-rajput/memory/{MEMORY.md,project_hermes_pilot_2026_09.md}
```

## 3. Dependency DAG + waves

```
W1  T1
W2  T2 ∥ T4            (disjoint: $CO+preflight/freeze vs Ollama store+$HH/ollama)
W3  T3 ∥ T5            (T3 read-only; T5 writes $HH/config + $SK/scripts)
W4  T6
W5  T7                 (serial: Hermes runs share state.db + Ollama RAM)
W6  T8  → GATE A
W7  T10 ∥ T11          (disjoint: $SK/** + ledger table vs 4 doctrine files)
W8  T12
W9  T13 → F1
W10 T14 → GATE B
W11 T15
W12 T16
W13 T17a ∥ T17b  · W14 T17c, then T17d ∥ T17e  · W15 T17f ∥ T17g   (Hermes arms serial; each pair disjoint dirs)
W16 T18
W17 T19 (optional)
W18 T20 → GATE C (operator go)
W19 T21
```
Everything else sequential. Day map: W1–3 = D1–2, W4–6 = D3–4, W7–10 = D5–6, W11–15 = D7–11, W16–17 = D12, W18–19 = D13–14.

## 4. Risk register

| # | Risk | Mitigation (ticket) |
|---|---|---|
| 1 | **Measurement invalid**: foreman contamination, ordering, n=1 variance, arm B's "subagent tax" hidden | Fresh subagents per arm, identical brief, coin-flip order, arm B's full transcript counted (T13/T17); blind re-grade + cross-read check (T18); ±10 pp rerun rule (T20/Q5) |
| 2 | **Ollama 64k**: RAM/speed; Hermes rejects <64k; llama3.2 too weak | qwen2.5-coder:7b at num_ctx 65536, benchmarked with thresholds and a 32k fallback (T4); locate what the 64k check reads (T6) |
| 3 | **Groq free-tier RPM/TPD** kills a loop mid-job | Live limit headers → model choice (T6); exit-75 backoff ≤2 (T10); per-brief token pre-estimate ≤70% TPD, Ollama fallback (T15) |
| 4 | **Keychain GUI prompt / no-TTY hang** on first `security` read | `-T /usr/bin/security -U` at creation; `</dev/null` non-interactive test; `helper_timeout_seconds: 5` (T5) |
| 5 | **Hermes reads HQ CLAUDE.md** → wanders, burns turns, leaks HQ instructions into the executor | `--ignore-rules` default in wrapper + `.hermes.md` template (T10); canary probe P8 (T8) |
| 6 | **Lazy deps at runtime** bypass the gate / hidden egress (telemetry, update checks) | Extras inside the gate + freeze snapshot (T2); `UV_OFFLINE=1 PIP_NO_INDEX=1` + closed-proxy egress kill on Ollama (T10); probe P3 (T8); freeze re-diff (T18); closed-proxy run C (T7) |
| 7 | **Trust Gate override scope**: override leaks past the clone; gate may not match `uv` at all | Single override command, verified exactly-one log line (T2/T3); gap → LESSON (T21) |
| 8 | **Cost-capture gaps**: `chat -q` prints no usage; `-z` may not honour fences; retries uncounted | state.db primary via stderr session_id, `-z --usage-file` calibration ≤5% (T13/T14); wrapper stores raw stdout/stderr/exit and counts retries in `hermes_runs` (T10) |

Kill-class risk above all eight — an Anthropic request via Hermes' Claude-Code credential path — is closed by config pin + wrapper guard + env-i scrub + the closed-proxy negative tests (T5, T7, T10, T12).

## 5. Claude-side quota estimate

| Ticket | Band (window tokens) |
|---|---|
| T1 20–40k · T2 40–80k · T3 30–60k · T4 20–40k | P0 ≈110–220k |
| T5 40–70k · T6 60–120k · T7 80–150k · T8 60–120k · GATE A 100–200k | P1 ≈340–660k |
| T10 80–150k · T11 30–60k · T12 80–150k | P2 ≈190–360k |
| T13 80–150k · F1 20–40k · T14 40–80k · GATE B 100–200k | P3 ≈240–470k |
| T15 100–200k · T16 40–80k · T17 A-arms 3×80–300k · T17 B/C-arms 4×30–120k · T18 60–120k | P4 ≈560–1,360k |
| T19 40–80k · T20 40–80k · T21 30–60k | P5–6 ≈110–220k |
| **Total** | **≈1.55M–3.3M** over 14 days, sonnet-heavy; opus on 7 tickets + 2 gates |

Dollars: **$0** beyond the Anthropic subscription — Groq free tier (no card), Ollama local, no Nous/OpenRouter/FAL. Disk ≈7 GB (checkout + venv ≈1.5 GB, model 4.7 GB, worktrees). Wall-clock: Ollama 64k runs may take 20–40 min each; budget reflected in `--run-budget`.

## 6. Open questions for the operator

1. **Groq key on D1?** Free tier, no card. Without it the pilot is Ollama-only — still valid but tests a weaker executor and can't run J2/J3 as planned.
2. **Job set:** J1 SKILL.md sweep / J2 shellcheck over HQ scripts (security scripts excluded) / J3 api-index classification — swap any for a job you actually need done next fortnight? Client-IP jobs excluded by design.
3. **Checkout + board locations:** confirm `$HQ/tools/hermes-agent` (or `vendor/`) and where boards live — T1 reads ORGANIZATION.md but a wrong default costs a wave.
4. **RAM:** OK to run ≈9 GB resident during Ollama jobs (close other heavy apps), or cap at 32k context and accept a smaller-context executor?
5. **Ambiguous-zone rule:** accept one rerun per job within ±10 pp of the 30% threshold (+~30% pilot quota), or single-shot and decide on the number?

## 7. What NOT to build

- `hermes gateway`, launchd, cron, kanban, heartbeat/goals, Telegram/alert routing (Stage 2, watchdog owns alerts).
- MCP bridge (`mcp_serve`); Hermes as reviewer/planner/client-facing writer.
- Auto-mode routing or router-hook enforcement (router is advisory; PROPOSE only until P6).
- Hermes memory/curator/skill writes, Hub installs, `import-agent` copies.
- Docker sandbox, a general egress-allowlisting proxy, a Trust-Gate `pre_tool_call` hook (park to BACKLOG).
- Cost-ledger schema migration (side table only); dashboards/UI.
- Paperclip adapter source changes; more than one Paperclip agent.
- A third backend or model bake-off beyond hq-coder-64k + one Groq model.
