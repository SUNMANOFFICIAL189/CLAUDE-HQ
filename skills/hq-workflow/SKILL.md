---
name: hq-workflow
description: >
  MANDATORY pre-flight before ANY Claude dynamic-workflow (the native `Workflow` tool)
  launch inside Claude HQ. Estimates token cost a-priori, applies the GREEN/AMBER/RED
  approval gate, and emits a script that bakes in the hard guardrails: concurrency cap,
  no unbounded loops, K=3 circuit breaker, mandatory adversarial-verify, and model
  tiering. Logs REAL token burn after the run. Invoke for every complex-project workflow.
  Built 2026-06-05 after a burn test proved budget.spent() undercounts true cost ~11x
  and the doctrine had no concurrency/quota guardrails (project_repo_eval_ruflo.md,
  project_dynamic_workflows_burn_test.md).
---

# HQ Workflow — Pre-Flight Gate & Guardrails

Native Claude dynamic workflows fan out tens–hundreds of subagents in one session. They
are powerful (parallel + adversarial verification = high calibre) and **expensive** — the
blog warns "substantially more tokens," and our own burn test confirmed it. This skill is
the cage. It is the in-session equivalent of `ctdd-precheck`: the discipline is external
to the Commander's judgment because relying on the Commander to "remember the cost" is
exactly how the 2026-04-28 quota window got blown.

## Why this exists (the two findings that built it)

1. **`budget.spent()` lies by ~11×.** Burn test: it reported 37k output tokens; the real
   total (input + output) was **409,174** for 6 agents — ~68k/agent. **~91% of burn is
   INPUT (context-loading), not output.** Never use `budget.spent()` as the cost guard.
2. **Cost is governed by per-agent context size × agent count.** The dominant lever is how
   much each subagent reads, NOT cleverness. Lean briefs ≈ 15–20k/agent; heavy ≈ 68k.

## When to invoke

**INVOKE BEFORE every `Workflow` tool call.** No exceptions for "small" ones — "small"
is how the window gets blown by a loop that wasn't supposed to run away.

**Do NOT use a workflow at all (use a normal Agent or inline work) when:**
- The task is linear / single-threaded (no real fan-out benefit)
- < 3 independent subtasks
- A single targeted Agent call would do it

---

## STEP 1 — Pre-flight estimate (procedural — you run this)

```
planned_agents     = (count every agent() call across all phases, incl. verifiers)
per_agent_estimate = 40_000           # conservative default (between 20k lean & 68k heavy)
                                      # use 18_000 only if briefs are verified-lean
                                      # use 68_000 if agents read large files/codebase
est_tokens         = planned_agents × per_agent_estimate
```

Write `planned_agents`, `per_agent_estimate`, and `est_tokens` into the mission board
Cost Ledger BEFORE launching.

## STEP 2 — Traffic-light gate (procedural — the real hard stop is the human)

| Band | Trigger | Behaviour |
|---|---|---|
| 🟢 **GREEN** | ≤ 8 agents **AND** est ≤ 300k tokens | Commander may launch within an already-approved mission |
| 🟡 **AMBER** | 9–20 agents **OR** est 300k–1M | Requires an explicit approval line from the operator in the mission board before launch |
| 🔴 **RED** | > 20 agents **OR** est > 1M | Requires explicit "I accept a large quota draw" confirmation. **Hard ceiling: 40 agents / 2M est** — do not exceed without a written, specific justification the operator signs off |

Quota note: there is **no reliable programmatic read of the Max 5-hour window** (verified
2026-06-05). So for AMBER/RED, surface the estimate + recent burn and let the operator
decide while watching `/usage`. Do not pretend an automatic quota cutoff exists — see
MODEL_ROUTING.md §7.

## STEP 3 — Build the script from the template (template-baked — HARD)

Generate the workflow script from `template.js` in this skill directory. Every emitted
script MUST contain, non-negotiably:

1. **`const MAX_AGENTS = N`** constant at the top — a hard cap. No dynamic fan-out beyond it.
2. **No unbounded loops.** Any loop-until-dry carries a hard iteration cap AND a
   `budget`-based guard (`budget.total && budget.remaining() > X`). budget is fine for
   *relative* loop control even though its absolute number undercounts.
3. **Circuit breaker: max `K = 3` verify→fix cycles**, then HALT and return partial results
   with a "needs human" flag. Never loop a fix forever.
4. **Model tiering (cost):** grunt/read/find agents → `model: 'haiku'` or `'sonnet'`;
   synthesis + final verification → omit (inherit Opus) or `'opus'`. Opus only where
   calibre is decided.
5. **Mandatory adversarial-verify stage:** any workflow that emits a claim, finding, or
   code passes each item through a *separate* verifier agent (different agent; ideally a
   different lens). Burn test: this killed 25% of bad output. Optionally route the verifier
   to **Codex** (`/codex:rescue` at the Commander level, not inside the script) for
   cross-model verification — different model, different failure modes.
6. **`pipeline()` over `parallel()`** unless a true barrier is needed (avoids idle-agent waste).
7. **Persist each phase's verified output to disk** (mission board / a results file) so
   context survives across phases and across an interrupted run.

## STEP 4 — Post-run accounting (procedural — closes the 11× gap)

When the task-notification arrives, read the **`usage` block** (`subagent_tokens` =
the REAL total) — NOT `budget.spent()`. Log to the Cost Ledger:

```
| workflow:<name> | Token usage (REAL) | <subagent_tokens> tok / <agent_count> agents | Done | Auto |
```

Then **calibrate:** if `actual / planned_agents` ≫ `per_agent_estimate`, raise the
constant in STEP 1 for next time. The system learns its own cost.

---

## How this serves the three standing goals

- **Cost-effective:** pre-flight estimate + traffic-light gate + model tiering + lean
  briefs (3–5× cheaper) + Codex offload for token-heavy phases (separate billing pool →
  those tokens never touch the Max window).
- **No hallucination:** mandatory adversarial-verify baked into every script; optional
  cross-model verify via Codex.
- **No context loss:** orchestration layer (Commander) holds the thread; persist each
  phase to disk; sequence several small scoped workflows instead of one giant run; native
  journaling/resume picks up an interrupted run.

## Anti-patterns

- **Skipping the gate for a "quick" workflow** — the runaway loop is always in the one you
  didn't gate. Same failure-class as skipping `ctdd-precheck` for an "obvious" call.
- **Trusting `budget.spent()` as the cost number** — it undercounts ~11×. Real number is
  the task-notification `usage.subagent_tokens`.
- **One giant 100-agent run** — sequence small scoped runs; cheaper, safer, keeps the
  Commander in the loop holding context.
- **Forcing full context into every subagent** — that is the single most expensive mistake
  (91% of burn is input). Give each agent a tight brief + targeted reads.
- **Documented-but-dormant guardrails** — if a control can't actually fire, say so plainly
  (the §7 lesson). Do not manufacture false confidence.
