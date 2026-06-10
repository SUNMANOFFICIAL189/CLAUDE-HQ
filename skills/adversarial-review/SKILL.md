---
name: adversarial-review
description: >-
  On-demand adversarial "proof-it" review for ANY project. Runs a skeptical, severity-ranked
  review of the current code/architecture that tries to BREAK what was built — composing
  independent reviewers (cross-vendor Codex when available + a fresh skeptical Claude agent +
  optional specialised reviewers), verifying every finding before reporting it (no false alarms),
  and returning CRITICAL/HIGH/MEDIUM/LOW findings with file:line, concrete risk, and a suggested
  fix — plus an honest "what's solid" pass. Now WIDE-SCOPE: a Phase-0 blast-radius + artifact-archetype
  contract check + a completeness critic so it interrogates the whole picture, not just the narrow
  brief (defeats the "narrow brief → loose ends untied" failure). Read/diagnose only; never auto-applies.
  Trigger phrases: "run the adversarial review", "proof this", "double-check the code", "pressure-test
  before we ship", "/adversarial-review". Reach for it at pre-merge / pre-deploy gates and after any
  substantial build phase.
---

# Adversarial Review — HQ proof-it pass (project-agnostic)

A reusable, trustworthy second pass that asks "what did we get wrong, and where will a bug creep in
later?" — for any project, in any language. It is an ORCHESTRATOR: it composes the review tools HQ
already has into one disciplined, CTDD-governed pass. It does not reinvent review.

**Why the wide pass exists (2026-06-10 lesson):** a review only finds what its BRIEF points at. A narrow
brief ("is the timeout fix safe?") yields a narrow review and leaves loose ends untied — and "17/17 tests
passed" was let stand in for a review entirely, so a new secret-scrubber shipped with fail-open holes.
Phase 0 (below) forces a zoom-OUT before the zoom-IN, and the mandatory-trigger rule stops the skill from
being skipped. See [[feedback_adversarial_review_scope_and_tests]].

## When to use
- Before merging a feature branch to main, before any deploy, or after finishing a build phase.
- When the operator says "proof it / double-check / pressure-test / run the adversarial review".
- After a large refactor or a change to a data layer, auth, payments, or anything touching PII.

## When the WIDE pass is MANDATORY (do not substitute tests/confidence for it)
Run the full Phase-0 wide pass (blast-radius + archetype contract) — not just a narrow check — and run it
the MOMENT the code is written, BEFORE calling it "solid" / "tests pass" / proposing merge, whenever the
change is **security-critical**: secret-handling, auth, a gate/guard/validator, a money-path, a data
migration/state-mutator, or anything that decides "allow vs block" or mutates persistent/PII data.
**Tests-pass ≠ reviewed** — happy-path tests miss fail-open behaviour and contract-completeness.

## When NOT to use
- Trivial one-line edits (use `/code-review` or just eyeball).
- As an auto-fixer — this NEVER edits code. It reports; fixing is a separate, approved step (Lesson 17).

## Hard rules (CTDD)
1. **Read/diagnose only.** Propose fixes; never apply them.
2. **Verify every finding before reporting it.** Each finding must cite `file:line` and the concrete
   failure path. If you cannot reproduce/justify it, DROP it. No crying wolf (false positives destroy trust).
3. **Don't invent issues.** If something is solid, say so. A short honest report beats a padded one.
4. **State the independence level achieved.** Cross-vendor (Codex) is the gold standard; fresh-Claude-agent
   is intra-vendor. Always tell the operator which was actually used — never imply cross-vendor if Codex didn't run.
5. **Deep / multi-agent mode is COST-GATED** — route it through the `hq-workflow` skill (GREEN/AMBER/RED) before any fan-out.
6. **Default posture = FAIL CLOSED.** When you cannot PROVE a gate/guard/mutator clause holds, report it
   as an open risk — never assume it's fine because the happy path works.

## Inputs / scope
- Default scope = uncommitted changes + commits ahead of the base branch (usually `main`).
  Detect: `git -C <repo> status --short` and `git -C <repo> log --oneline <base>..HEAD`.
- Overrides: `--path <dir/file>`, `--range <gitref..gitref>`, `--since <commit>`, `--all` (whole module).
- Detect stack/language from the changed files (extensions, manifests) to pick specialised lenses.
- Be token-efficient: read the changed files + their immediate dependencies, not the whole repo.

## Depth modes
- **standard (default):** Phase 0 (lightweight) + cross-vendor lens (if Codex healthy) + fresh skeptical Claude agent + finding-verification + completeness critic. Cheap, fast.
- **deep:** standard + full Phase-0 blast-radius (code-review-graph) + specialised reviewers (security / language) and/or a multi-agent fan-out. **MUST** run via `hq-workflow` (cost estimate + approval gate). **Auto-selected** for the mandatory-trigger categories above.

## Procedure

### 0. Widen the scope BEFORE you narrow it  ← defeats "narrow brief → loose ends"
Two moves, BOTH before the focused lenses. Do not skip for security-critical changes.

**(a) Blast-radius map.** Review what the artifact actually TOUCHES, not just the file in the brief.
Use **code-review-graph FIRST** (per `claude-hq/CLAUDE.md`): `get_impact_radius`, `get_affected_flows`,
`query_graph` (callers / dependents / tests_for). If the target isn't graph-indexed (standalone script,
config, hook), map it by hand: who invokes it, what it writes, what consumes its output, what downstream
gate/push/deploy depends on its result. **Expand the review set to that radius.**

**(b) Archetype + full contract.** Classify WHAT KIND of thing this is, then write its COMPLETE contract
and turn every clause into a checklist item — review against the *whole contract*, not just the brief's
question. **This is the step that unties loose ends.** Use the seed library; if nothing fits, derive the
contract from first principles AND append the new archetype to the library (it grows like LESSONS.md).

#### Archetype contract library (seed — extend on use)
| Archetype | Is it? | Mandatory contract clauses — check EVERY one, cite proof or list as open risk |
|---|---|---|
| **Security gate / guard** | decides allow-vs-block (scrubbers, validators, auth checks, Trust Gate, push/deploy gates) | (1) **FAIL CLOSED** on ANY error / exception / timeout / crash / partial run — never default to "allow"; (2) **detection set == enforcement set** — every pattern/rule it can *clean/handle* it must also *block on* (no gap between "what I detect" and "what I stop"); (3) **covers the FULL protected universe** — every file type / row / path that downstream actually ships or trusts, not a convenient subset; (4) the block signal is reliably **emitted AND loud** (not a silent log line); (5) runs at a point where it **can't be bypassed/skipped**, and its caller honours its verdict (exit code / sentinel). |
| **State mutator / migration** | changes persistent state (DB writes, file rewrites, watermarks, caches) | (1) progress/watermark advances **only after the write commits** (never over uncommitted/rolled-back work); (2) partial failure → safe, **re-runnable** state (idempotent); (3) **atomic** writes (temp+rename, not truncate-in-place); (4) **concurrency-safe** vs other writers (locks/timeouts); (5) failures **surface**, not silently swallowed-then-"clean". |
| **Auth / secret handler** | touches credentials / PII | (1) secrets never logged/persisted in plaintext; (2) least privilege; (3) fail closed; (4) revocation/rotation path exists; (5) detection complete across ALL key shapes it claims to cover. |
| **Parser / external-input** | consumes untrusted/external data | (1) malformed/empty/oversized/adversarial input can't crash or be mis-trusted; (2) no injection/eval of input; (3) bounded resource use; (4) sanitised before any downstream use. |

### 1. Scope + context
Resolve the scope (above) AS WIDENED BY PHASE 0. List the files in scope (brief + blast radius) and the
stack. Read them + immediate deps. State the artifact's archetype(s) and its contract checklist.

### 2. Run the independent lenses (use those available; record which ran)

**Lens A — Cross-vendor (Codex).** Best independence (a different model that didn't write the code).
- Check health first: `codex login status` and
  `node "$HOME/.claude/plugins/cache/openai-codex/codex/<ver>/scripts/codex-companion.mjs" setup --json`.
- NOTE: the codex *plugin/companion* runs in ChatGPT-account "app-server" mode and is limited to that
  account's model tier (it has failed with "gpt-5.4 not supported when using Codex with a ChatGPT account").
  The reliable path is the **Codex CLI directly** on API-key auth:
  `codex exec -s read-only -C <repo> "<review brief>"` (read-only sandbox, non-interactive).
  Requires a VALID OpenAI API key with API billing enabled (ChatGPT Plus ≠ API access).
- If Codex errors (auth/billing/model), **SKIP this lens** and record "cross-vendor: unavailable (<reason>)".
  Never block the review on Codex.

**Lens B — Fresh skeptical Claude agent (always run).**
- Spawn a subagent (Agent tool, `subagent_type: "general-purpose"` or `Explore` for read-only) with this mandate:
  "You did NOT write this code. Your job is to BREAK it. Find real bugs, security holes, silent
  failure modes, and architectural weaknesses in <scope>. **This artifact is a <archetype>; check it
  against EVERY clause of its contract: <paste the Phase-0 contract checklist>. For each clause you cannot
  PROVE holds, report it (default fail-closed).** For each finding, give file:line, the concrete failure
  path, severity, and a fix. Verify each finding is real before listing it. Also list what is genuinely
  solid. Do not invent issues."
- This gives fresh-context independence even when Codex is down.

**Lens C — Specialised depth (deep mode only).**
- If the change touches input handling / auth / PII / secrets → invoke the ECC `security-reviewer`.
- For the stack, invoke the matching ECC reviewer (`python-reviewer`, `go-reviewer`, `rust-reviewer`,
  `java-reviewer`, `kotlin-reviewer`, `cpp-reviewer`) and/or `/code-review` for correctness-bug coverage.
- Fan-out across lenses/files → wrap in `hq-workflow` (cost gate).

### 3. Adversarially verify findings
For each candidate finding from any lens: confirm it against the actual code (open the file:line, trace
the path). Classify: REAL / FALSE-POSITIVE / NEEDS-INVESTIGATION. Drop false positives. Keep only what
you can defend with an artifact. This step is what makes the report trustworthy.

### 3.5 Completeness critic (the loose-ends backstop — always run)
Before writing the report, answer explicitly:
- **Which archetype-contract clauses are still UNVERIFIED?** List each as an open risk (fail-closed default).
- **What's in the blast radius that wasn't reviewed?**
- **What did the narrow brief EXCLUDE that actually matters?**
- **Tests vs review:** if the artifact was "validated by tests," do the tests exercise the fail/error paths
  and the full contract — or only the happy path? Name the gap.

### 4. Synthesise
Dedup + merge across lenses into ONE ranked report. Map each finding to a severity and (where relevant)
to a project phase / follow-up.

### 5. Output (this exact shape)

```
# Adversarial Review — <scope> (<date>)
Independence achieved: <cross-vendor (Codex) + fresh-agent | fresh-agent only (Codex unavailable: <why>)>
Archetype(s): <e.g. security-gate + state-mutator>   Blast radius reviewed: <files/flows beyond the brief>

## 🔴 CRITICAL
- <finding> — `file:line` — <concrete risk / failure path> — Fix: <suggested fix>
## 🟠 HIGH
## 🟡 MEDIUM
## 🟢 LOW
## ✅ What's solid (verified, not invented)
- <thing done well>

## Contract coverage — <archetype>
- [x] clause verified holds (proof)   [ ] clause OPEN/unverified → risk
## Loose ends / not interrogated: <what a deeper or wider pass would still add>

Coverage + limits: <what was/wasn't reviewed; residual risk>
```

- Also offer to write the report to `<project>/docs/reviews/adversarial-review-<YYYY-MM-DD>.md` for the record.
- End by offering next steps: (a) fix the CRITICAL/HIGH now (separate approved step), (b) fold into the plan, (c) re-run after fixes.

## Guardrails recap
- Never edits code. Never auto-fixes. Cross-vendor is best-effort + honestly labelled. Deep mode is hq-workflow-gated. Every finding is verified. Solid things are credited. No invented issues. **Wide pass + fail-closed default on security-critical changes; tests-pass is never a substitute for the review.**

## Pairs with
- `ctdd-precheck` (verify-before-claim discipline), `hq-workflow` (cost gate for deep fan-out),
  `code-review-graph` (blast-radius mapping in Phase 0), `/code-review` + ECC reviewers + `codex:rescue`
  (the lenses this composes), `save`/`sync` (persist the report).
