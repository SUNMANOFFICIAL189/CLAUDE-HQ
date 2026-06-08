---
name: adversarial-review
description: >-
  On-demand adversarial "proof-it" review for ANY project. Runs a skeptical, severity-ranked
  review of the current code/architecture that tries to BREAK what was built — composing
  independent reviewers (cross-vendor Codex when available + a fresh skeptical Claude agent +
  optional specialised reviewers), verifying every finding before reporting it (no false alarms),
  and returning CRITICAL/HIGH/MEDIUM/LOW findings with file:line, concrete risk, and a suggested
  fix — plus an honest "what's solid" pass. Read/diagnose only; proposes fixes, never auto-applies.
  Trigger phrases: "run the adversarial review", "proof this", "double-check the code", "pressure-test
  before we ship", "/adversarial-review". Reach for it at pre-merge / pre-deploy gates and after any
  substantial build phase.
---

# Adversarial Review — HQ proof-it pass (project-agnostic)

A reusable, trustworthy second pass that asks "what did we get wrong, and where will a bug creep in
later?" — for any project, in any language. It is an ORCHESTRATOR: it composes the review tools HQ
already has into one disciplined, CTDD-governed pass. It does not reinvent review.

## When to use
- Before merging a feature branch to main, before any deploy, or after finishing a build phase.
- When the operator says "proof it / double-check / pressure-test / run the adversarial review".
- After a large refactor or a change to a data layer, auth, payments, or anything touching PII.

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

## Inputs / scope
- Default scope = uncommitted changes + commits ahead of the base branch (usually `main`).
  Detect: `git -C <repo> status --short` and `git -C <repo> log --oneline <base>..HEAD`.
- Overrides: `--path <dir/file>`, `--range <gitref..gitref>`, `--since <commit>`, `--all` (whole module).
- Detect stack/language from the changed files (extensions, manifests) to pick specialised lenses.
- Be token-efficient: read the changed files + their immediate dependencies, not the whole repo.

## Depth modes
- **standard (default):** Cross-vendor lens (if Codex healthy) + fresh skeptical Claude agent + finding-verification. Cheap, fast.
- **deep:** standard + specialised reviewers (security / language) and/or a multi-agent fan-out. **MUST** run via `hq-workflow` (cost estimate + approval gate). Use for pre-deploy gates on high-stakes code (auth, payments, PII, money-moving, safety-critical).

## Procedure

### 1. Scope + context
Resolve the scope (above). List the files in scope and the stack. Read them + immediate deps.

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
  failure modes, and architectural weaknesses in <scope>. For each, give file:line, the concrete
  failure path, severity, and a fix. Verify each finding is real before listing it. Also list what is
  genuinely solid. Do not invent issues."
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

### 4. Synthesise
Dedup + merge across lenses into ONE ranked report. Map each finding to a severity and (where relevant)
to a project phase / follow-up.

### 5. Output (this exact shape)

```
# Adversarial Review — <scope> (<date>)
Independence achieved: <cross-vendor (Codex) + fresh-agent | fresh-agent only (Codex unavailable: <why>)>

## 🔴 CRITICAL
- <finding> — `file:line` — <concrete risk / failure path> — Fix: <suggested fix>
## 🟠 HIGH
## 🟡 MEDIUM
## 🟢 LOW
## ✅ What's solid (verified, not invented)
- <thing done well>

Coverage + limits: <what was/wasn't reviewed; residual risk; what a deeper pass would add>
```

- Also offer to write the report to `<project>/docs/reviews/adversarial-review-<YYYY-MM-DD>.md` for the record.
- End by offering next steps: (a) fix the CRITICAL/HIGH now (separate approved step), (b) fold into the plan, (c) re-run after fixes.

## Guardrails recap
- Never edits code. Never auto-fixes. Cross-vendor is best-effort + honestly labelled. Deep mode is hq-workflow-gated. Every finding is verified. Solid things are credited. No invented issues.

## Pairs with
- `ctdd-precheck` (verify-before-claim discipline), `hq-workflow` (cost gate for deep fan-out),
  `/code-review` + ECC reviewers + `codex:rescue` (the lenses this composes), `save`/`sync` (persist the report).
