---
name: proof-check
description: >-
  The standing "don't move on with loose ends" gate. Triggered by /proof-check, or run it
  automatically after any SUBSTANTIAL or SECURITY-CRITICAL task before calling it done / moving to
  the next task / proposing a merge or deploy. Runs ONE wide /adversarial-review on the just-completed
  work, then: CRITICAL/HIGH findings STOP you and surface to the operator ("fix these, then re-run
  /proof-check"); LOW/MEDIUM are filed to BACKLOG; a clean pass clears you to proceed. It NEVER
  auto-fixes and NEVER loops — one review, human decides. Built 2026-06-10 after a secret-scrubber
  shipped with fail-open holes because the review was SKIPPED (tests were used as a stand-in). The
  heavier "auto-loop until clean" version was reviewed and rejected (doctrine-illegal cost, nested
  agent fan-out, unsupervised-fix risk) — see project_proof_loop_design_2026_06_10.
---

# /proof-check — one inspection, never skipped, human decides

A thin, cheap, fail-safe gate. It exists to fix ONE failure: a review getting *skipped* (confidence or
green tests standing in for it), letting loose ends ship. It is NOT a loop and NOT an auto-fixer — those
were deliberately rejected (`project_proof_loop_design_2026_06_10`): the value is in *running the
inspection*, not in automating the fix-recheck cycle.

## When it is MANDATORY (the standing rule)
Before you call a task done, move to the next task, or propose a merge/deploy — run this whenever the
work is **substantial or security-critical**. Use the SAME mandatory-category list as
`/adversarial-review`: secret-handling, auth, a gate/guard/validator, a money-path, a data
migration/state-mutator, anything deciding "allow vs block" or mutating persistent/PII data, OR any
multi-file / non-trivial build. **Tests passing is NOT a substitute** (that was the 2026-06-10 failure).

## When to SKIP it
Trivial one-liners, doc/typo edits, pure-information answers. The inspection is Opus-floored
(`MODEL_ROUTING.md` hard floor — adversarial work doesn't run cheap), so don't spend it on trivia.

## Procedure
1. **Scope the target** — the work just completed (the diff / new files / the artifact). State it.
2. **Run ONE `/adversarial-review`** on it (the wide skill: Phase-0 blast-radius + archetype contract +
   completeness critic). This is the single inspection. Do not loop it.
3. **Triage by severity:**
   - **🔴 CRITICAL / 🟠 HIGH → STOP.** Surface to the operator: "N critical/high to resolve before you
     move on — [list with file:line + fix]. Fix them, then re-run `/proof-check`." Do **NOT** auto-fix.
     Do **NOT** proceed, merge, or deploy. The gate is closed.
   - **🟡 MEDIUM / 🟢 LOW → file to BACKLOG** (via the `/capture` → BACKLOG path) and report the count.
     These do not block proceeding.
   - **Clean (no CRITICAL/HIGH) → report "proof-check passed — clear to proceed"** AND clear the
     proof-gate flag so a proof-checked merge/push isn't blocked: `rm -f ~/.claude/.proof-needed`.
4. **Re-running is operator-triggered.** After the operator fixes the CRITICAL/HIGH, they re-run
   `/proof-check`; the re-run (which is what catches any fix-introduced regression — exactly how MED-3
   was caught on 2026-06-10) confirms clean. No automatic re-loop.

## Hard rules (CTDD)
- **Never auto-fix.** Fixing is a separate, operator-approved step (Lesson 17; same rule the
  underlying `/adversarial-review` enforces). Unsupervised fixes introduce new fail-opens.
- **Never loop automatically.** One review per invocation. Convergence is the operator re-running.
- **Fail-safe gate:** if CRITICAL/HIGH are present (or the review couldn't complete), the answer is
  "do NOT proceed" — never "probably fine."
- **One Opus review per run** — scope to substantial/security work; the heavy auto-loop is shelved.

## Relationship to the rest of HQ
- Wraps `/adversarial-review` (the inspection) — uses its wide archetype-contract pass.
- The Commander activation protocol references this as the proof gate before delivery.
- The deferred next step is the **Layer-3 watchdog hook** — a harness hook that mechanically blocks
  "done/merge" if no proof-check ran. Until that exists, this gate is doctrine-enforced (relies on the
  Commander honoring it), NOT hard-enforced. See `project_proof_loop_design_2026_06_10` Phase 3.

## Pairs with
`adversarial-review` (the inspection it runs), `ctdd-precheck` (verify-before-claim), `hq-workflow`
(cost cage if a review ever fans out), `/capture` (files LOW/MED to BACKLOG), `save`/`sync`.
