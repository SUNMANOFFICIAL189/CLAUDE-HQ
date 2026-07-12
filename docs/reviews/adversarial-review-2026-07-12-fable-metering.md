# Adversarial Review — Fable metering transition build (2026-07-12)

Independence achieved: fresh-agent ×2 on **Opus 4.8 via explicit `model:"opus"` params** (builder session = Fable 5, so reviewer ≠ builder model). Cross-vendor (Codex): unavailable — API key 401, BACKLOG 2026-06-14.
Archetype(s): **security gate / money-path guard** (router deny gate) + orchestration doctrine (hq-foreman) + observability script.
Blast radius reviewed: model-router.py + model-router.sh wrapper, settings.json hook wiring, MODEL_ROUTING.md, COMMANDER.md, hq-foreman SKILL.md, hq-workflow SKILL.md (interaction), route-{table,preview,fable}.md, fable-spend.sh, session-start.sh, feedback_phase_gate_dual_review_fable.md memory.
All findings reproduced/verified by the lenses (crafted-JSON runs against scratch HQ_ROOT; file:line reads). No invented issues; false positives dropped.

## RE-REVIEW RESULT (2026-07-12, fresh Opus lens) + FIX STATUS
**Re-review verdict: all 5 fixes HOLD; no active CRITICAL/HIGH; adjacent routing unregressed.** 12 H1 evasions denied, H3 reuse denied, C1 crash-inputs (dict/list model, forced `_run` crash via dict cwd) fail closed to DENY, denied rows keep `model_chosen='opus'`. One NEW MEDIUM (latent) found + FIXED same session: an authorized Fable dispatch under `HQ_MODEL_OVERRIDE=opus/sonnet/haiku` would run Fable (explicit param honored) but skip nonce-consume + log 'opus' + hide from fable-spend. Fixed by keying the metered banner / nonce-consume / ledger `model_chosen` on the ALLOWED-fable REQUEST (`effective_tier`), not decide()'s `chosen_tier`. Re-verified: override+authorized-fable → runs+logs fable + consumes nonce; override+reuse → denied; override+no-sentinel → denied; non-fable + override unaffected. Residual LOWs (nonce-store TOCTOU race, C1 backstop checks sentinel-presence-not-reuse, store-read-error fails-open for the reuse sub-check only) are documented defense-in-depth, none model-controllable → filed to BACKLOG, accepted. **Gate: CLEAR.**

## FIX STATUS (applied 2026-07-12, same session; re-review CLEAN)
- 🔴 C1 → FIXED: main() wraps _run() in try/except; inputs coerced to str (errs toward blocking); residual-crash backstop denies a positively-unauthorized metered-fable dispatch. Verified: dict/list model + list prompt now DENY (were allow-on-crash).
- 🟠 H1 → FIXED: sentinel is now regex `FABLE-OK:<nonce>` (≥4 alnum), not bare substring. Verified: quoted doctrine + `FABLE-OK:<nonce>` template no longer authorize; real nonce does.
- 🟠 H2 → FIXED: route-table.md now says DENIES + notes modifyToolInput is ignored.
- 🟠 H3 → FIXED (code + doctrine): single-use nonce store (`run/.fable-nonces`); reuse DENIED. hq-foreman states one-yes=one-nonce=one-dispatch + planning-consult vs review-lens as separate consents.
- 🟠 H4 → FIXED (doctrine): hq-workflow STEP 3 + hq-foreman rail 2 forbid `model:fable` on workflow `agent()` calls; MODEL_ROUTING §5.5 documents the boundary.
- 🟡 M1 → FIXED: real-deny stderr banner now says "DENIED". 🟡 M3 → FIXED: fable-spend.sh uses `datetime(ts)`. Remaining M2/M4/M5 + LOWs stay in BACKLOG (2026-07-12 item).

---

## 🔴 CRITICAL
- **C1 — Deny gate fails OPEN on any unhandled exception.** `model-router.py` guards only stdin-read + `json.loads`; everything after (decide(), deny computation, deny print) is unguarded, and `sys.exit(main())` lets exceptions exit 1 with no JSON → per hook semantics the dispatch PROCEEDS → an unauthorized fable dispatch RUNS and bills. Reproduced with 5 schema-violating inputs (non-string `model`/`prompt`, `tool_input` as string): e.g. `{"model":{"id":"claude-fable-5"}}` → AttributeError → exit 1 → allow. Deny helpers themselves throw on non-strings (`fable_authorized`, `tier_for_model((requested or "").strip())`). Likelihood caveat: needs a schema-violating dispatch (harness may pre-validate) — but a money gate must not depend on an upstream validator it doesn't own. **Fix:** wrap main() body in try/except; on exception affecting an Agent dispatch, fail CLOSED for the fable question (compute a defensive deny from str-coerced raw input FIRST, before decide()); coerce `str()` on model/prompt at entry.

## 🟠 HIGH
- **H1 — Sentinel defeated by quotation.** `fable_authorized()` is substring-anywhere; the literal `FABLE-OK` now lives in MODEL_ROUTING.md, hq-foreman, route-table.md, MEMORY.md, fable-spend.sh output — any fable-stamped dispatch whose prompt quotes doctrine self-authorizes (reproduced). **Fix:** structured sentinel — token must appear on its own line as `FABLE-OK <nonce>` (Commander mints per approval), matched by regex, not substring.
- **H2 — route-table.md:27 teaches the opposite of the code.** Says the router "caps the dispatch to Opus"; code DENIES (and cannot cap — modifyToolInput ignored). Actively re-teaches the disproven mental model. **Fix:** one-line correction to "DENIES".
- **H3 — Consent-scope ambiguity (the real leak path).** hq-foreman "at most ONE per task" vs standing-order "consent-gated per dispatch": one operator yes could be read to cover both the planning consult AND a later review lens. Nothing says FABLE-OK is single-use. **Fix:** hq-foreman wording — one yes = exactly one dispatch; planning consult and review lenses are separate consents; cross-link the standing order.
- **H4 — Workflow-tool hole.** Native `Workflow` agent() spawns don't match the `"Agent"` hook matcher (router hard-guards `tool_name != "Agent"`), so a workflow script with `model:'fable'` bills UNGATED; hq-workflow SKILL.md never mentions Fable/metering. **Fix:** add "never model:fable in workflow agents — the deny gate does not cover them" to hq-workflow STEP 3 + hq-foreman hard rail 2.

## 🟡 MEDIUM (filed to BACKLOG)
- M1 — Real-deny stderr banner says "Routed → opus (fable-capped…)", never "DENIED" (only dry-run prints DENIED). Loud-block clause partial.
- M2 — Protected-universe gaps to document as accepted-uncovered + rail: session model via `ANTHROPIC_MODEL` env / `--model` CLI / project settings (session-start warn only greps ~/.claude/settings.json); inheritance blind spot (no-model dispatch from a future Fable session is invisible to the gate — sole defense is the Opus pin); MCP/Bash-spawned sessions.
- M3 — fable-spend.sh day-boundary over-count: string compare of ISO-with-T vs `datetime('now')` space form. Fix `WHERE datetime(ts) >= …` (verified correct).
- M4 — MODEL_ROUTING.md header/§1/§3/§4 still promise "automatic enforcement"; §4 "explicit fable preserved" stale (now needs sentinel). Add header honesty line + §4 amendment.
- M5 — Consent is intent-signal, not verified consent (LLM can write the token) — by design; state plainly in §5.5 + add drift visibility note (route-fable DENIED/ALLOWED counts are the audit).

## 🟢 LOW (filed to BACKLOG)
- L1 — fable-spend.sh: estimate can understate multi-fold on big briefs; noisy sqlite errors on empty/table-less ledger.
- L2 — `gpt-fable`-style non-Anthropic names: banner says passthrough yet deny fires (over-block, fails safe; no such model today).
- L3 — COMMANDER.md points at COST_CONTROL.md as routing SSOT (it redirects); stale `opusplan` tip; quick-reference lacks metering note.
- L4 — model-router.sh:6 comment "never blocks" now false (deny carve-out).
- L5 — hq-foreman retry table "top tier" ambiguous (could be read as Fable); add "Opus is the execution ceiling".
- L6 — hq-foreman/route-table reference space-form `/route table`, `/route preview`; actual commands are hyphenated.
- L7 — route-fable.md allowed-tools hardcodes absolute path (brittle vs tilde form); siblings carry none.
- L8 — hq-foreman: one line on when to use its own verifier vs /proof-check.

## ✅ What's solid (verified)
- Fable string-shape coverage complete: fable/FABLE/Fable-5/claude-fable-5/[1m]/dated/whitespace/prefixed all denied; case-sensitive sentinel rejects `fable-ok`.
- No env route-around: deny keyed on raw request in main(); OVERRIDE/FLOOR=fable still rejected; HQ_ROUTER_OFF bypass works exactly as documented.
- Correct modern deny contract (permissionDecision:"deny", exit 0); ledger row (`fable-denied`) written before print, exception-guarded.
- Authorized path works; metered-cost banner prints; 12-case dry-run + 7-case live sandbox batteries pass.
- hq-foreman's "Hard context" section is the cleanest statement of enforcement reality in the doc set; wires to existing gates instead of duplicating; consent-on-no path well-specified (First Law).
- fable-spend.sh queries match the router's ledger writes exactly; DENIED count is a genuine drift signal; honest estimate labeling.
- session-start.sh warning is exception-safe, fires correctly on a fable settings model.
- Consistent with COST_CONTROL.md Tier 4 (any expenditure needs approval).

## Contract coverage — security gate (money-path)
- [ ] (1) Fail closed on error — **FAIL → C1** (open until fixed)
- [x] (2) Detection set == enforcement set — PASS (over-inclusive; L2) — 7 shapes verified; no env route-around
- [ ] (3) Full protected universe — **PARTIAL → H4 + M2** (Workflow spawns; session-model env/CLI; inheritance)
- [ ] (4) Block signal loud — **PARTIAL → M1** (ledger yes; stderr misleading)
- [ ] (5) Bypass resistance / consent — **FAIL → H1 + H3** (quotation collision; consent-scope ambiguity); M5 inherent-limit stated

## Loose ends / not interrogated
- Whether the harness pre-validates Agent tool_input schema before hooks fire (would reduce C1 likelihood; cannot be read from disk).
- Whether Workflow-internal agent() calls emit ANY PreToolUse event (H4 residual unknown; treated as uncovered).
- Real Fable billing terms on this account post-cutoff (docs verified; account page not checked from here).

Coverage + limits: full read of changed files + hook wiring + interacting skills; live crafted-JSON reproduction for every code finding; intra-vendor independence only (Opus lenses, Codex down). Residual risk = the three loose ends above.

— Lenses: 2× fresh Opus agents (adversarial code lens; doctrine/consistency lens). Builder: Fable 5 session. Date: 2026-07-12.
