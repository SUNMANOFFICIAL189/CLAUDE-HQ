# CLAUDE HQ — Improvements Backlog

**Purpose:** Deferred improvements to Claude HQ. Items here are not scheduled — they are captured so we don't forget them when we next sit down to improve the system. Revisit during any HQ tune-up session or when a listed item becomes blocking.

**Convention:**
- Add new items at the bottom with `## [Open] — YYYY-MM-DD — <title>`
- When an item is picked up, change `[Open]` → `[In progress]` and add owner
- When done, change to `[Done] — YYYY-MM-DD` and leave the entry in place (do not delete; it's our audit trail)

---

## [Open] — 2026-04-22 — Audit TECCP once, fold rules into AGENTS.md

**What:** Read through `~/claude-hq/tools/token-efficiency/.source` target repo (`https://github.com/SUNMANOFFICIAL189/token-efficiency-context-continuity`). Extract the rules that actually reduce waste (token discipline, context buffer monitoring, anti-hallucination patterns, GitHub-backed task tracking). Fold them into `~/claude-hq/AGENTS.md` as first-class HQ directives.

**Why:** TECCP's real value is its rules, not a plugin wrapper. Hoisting rules into AGENTS.md gives them to every session without a separate install, startup cost, or maintenance drift against an upstream. After the hoist, the standalone repo can be retired as a reference.

**Estimate:** 1–2 hours. Mostly reading + distilling, one-pass edit to AGENTS.md, commit.

**How to start:**
1. `git clone` the repo via Trust Gate (owner is self, allowlisted).
2. Read README + any `rules.md` / `principles.md` / skill files.
3. Draft a TECCP section for AGENTS.md with the rules that pass the "would this change Claude's behaviour on a real task?" test. Drop the rest.
4. Commit: `feat(agents): fold TECCP rules into HQ directives`.
5. Delete `tools/token-efficiency/.source` stub (or leave a note pointing to where the rules landed).

**Acceptance:** AGENTS.md has a TECCP rules section. A new session shows the rules applied. Stub removed or annotated.

---

## [Open] — 2026-04-22 — Lift 3–4 best templates from seed into ~/claude-hq/templates/

**What:** Walk the already-cloned `~/claude-hq/repos/seed/` for its best templates (micro-task decomposition prompts, error-handling patterns, any scaffolding that maps to how we actually work). Copy the keepers into `~/claude-hq/templates/` with a short `README.md` describing when to use each.

**Why:** seed is a methodology, not a daemon — installing it as a framework is overkill. But the 3–4 best templates are genuinely reusable. Having them as HQ-native files means the Commander can cite them directly in plans without loading seed's whole world.

**Estimate:** ~30 minutes once we're in the repo.

**How to start:**
1. `ls ~/claude-hq/repos/seed/templates ~/claude-hq/repos/seed/examples` (or equivalent — explore structure first).
2. Read candidates, pick the 3–4 that actually match how we decompose work.
3. Copy into `~/claude-hq/templates/seed-<name>.md` with a one-line header noting origin and licence.
4. Add a short `~/claude-hq/templates/README.md` indexing them.
5. Commit: `feat(templates): lift seed micro-task + error-handling templates`.

**Acceptance:** `templates/` has 3–4 new files plus an index. Commander's planning step can reference them by path.

---

## [Open] — 2026-04-22 — Write Commander-specific slash commands for our recurring patterns

**What:** Identify the 3–5 patterns we actually repeat across projects (e.g., PATS-Copy scraper cycle, PRD → build bootstrap, end-of-session sync, wallet/signal investigation loop, dashboard regression pass). Encode each as a slash command in `~/claude-hq/commands/` (or project-scoped `.claude/commands/` where it's project-specific).

**Why:** Custom slash commands for *our* patterns are higher ROI than installing someone else's generic framework. They capture institutional knowledge, reduce per-session prompt overhead, and make the Commander's "Step 2 classify" faster because the triggers are explicit.

**Estimate:** 1–3 hours total, depending on how many commands. Each command is small.

**How to start:**
1. Review the last 5 sessions' summaries (claude-mem search) and list prompts/flows that repeated verbatim or near-verbatim.
2. For each repeat: define the trigger phrase, the steps, the expected output, what gets committed, and knowledge-layer updates.
3. Draft as markdown files in `~/claude-hq/commands/<name>.md` with frontmatter (`name`, `description`, `category`).
4. Register in `registry.json` so Commander picks them up on activation.
5. Commit: `feat(commands): add <n> recurring-pattern slash commands`.

**Candidate commands (from memory — refine when picking this up):**
- `/pats-cycle` — wallet scan → signal eval → copy decision → mission-board update
- `/prd-bootstrap` — Step 0 bootstrap flow in one command
- `/session-sync` — checkpoint: git commit + mempalace mine + graphify update + vault push
- `/investigate` — wallet/flaw investigation with agent orchestration

**Acceptance:** `commands/` has the new files, registry.json lists them, one real task has been run through a new command end-to-end to validate.

---

## [Open] — 2026-04-22 — Measure before adding: baseline HQ's current token spend per task

**What:** Before installing anything else (ruflo, paul, etc.) establish a baseline of what each task class actually costs in tokens today. Break it down: how much goes to file reads vs. agent coordination vs. hook output vs. actual reasoning.

**Why:** Adding tools without measurement is guessing. Today we have no idea which part of HQ is token-heavy — is it skills loading at session start? Redundant Grep/Read before code-review-graph does its job? Hook output noise? Until we can answer that, any "let's install X to save tokens" decision is faith-based.

**Estimate:** Unclear — could be 2 hours (eyeball transcripts) or a day (build a proper measurement harness). Start with eyeball.

**How to start:**
1. Pick 3 representative past sessions of different sizes (short/medium/long).
2. For each, estimate or count: session-start hook/skill load tokens, tool-call tokens, reasoning tokens, final output tokens.
3. Identify the top 3 token sinks.
4. Draft a cheap fix for each sink (e.g., "trim session-start hooks output," "prefer code-review-graph over Grep in AGENTS.md," "compact tool results in claude-mem").
5. If there's value in repeatability: add a `scripts/measure-session.sh` that parses session JSON and reports token breakdown.
6. Record findings in `docs/TOKEN_AUDIT_<date>.md`.

**Acceptance:** A token-spend baseline doc exists for at least 3 session classes. Top 3 sinks are named with proposed fixes. A rule goes into LESSONS.md: "don't install a new tool for token efficiency without citing baseline data."

---

## [Open] — 2026-05-06 — Wire weekly Telegram routing digest

**What:** Implement the weekly digest spec in `commander/MODEL_ROUTING.md` §8. Every Sunday 09:00 local: query `run/cost-ledger.sqlite` for last-7-days routing decisions, aggregate per project/tier/agent kind, format as a Lesson-16-compliant PlainAlert, send via existing `watchdog/telegram.py`.

**Why:** Phase 1 of the multi-model build shipped doctrine + routing hook + cost ledger, but the user-facing weekly visibility loop is not wired. Without it we have data but no proactive surfacing — defeats the "spot regressions early" intent that drove Q5.

**Estimate:** ~3–4 hours. Generator script, launchd plist, dry-run mode, jargon-linter validation.

**How to start:**
1. Wait until ~Sunday May 12 — by then we'll have ~7 days of real ledger rows to test against (today's data is mostly synthetic from the Phase 1 verification).
2. Read `watchdog/telegram.py` for the `PlainAlert` send pattern + jargon-linter behaviour.
3. Author `~/claude-hq/scripts/routing-digest.py`: queries ledger, aggregates, builds PlainAlert per the §8 template.
4. Add `~/Library/LaunchAgents/com.claude-hq.routing-digest.plist` for Sunday 09:00 trigger.
5. Run dry-run mode against current ledger, confirm output passes the linter.
6. Install launchd, verify on the next Sunday firing.

**Depends on:** ideally Watchdog Telegram listener fix (next item) so the digest's "reply 'details'" loop actually works. Without the listener, the digest still goes out — user just can't reply via Telegram. Acceptable degraded mode.

**Acceptance:** First Sunday digest lands in Telegram with no jargon-linter errors. Reading it tells the user something useful about the prior week's routing.

---

## [Open] — 2026-05-06 — Fix Watchdog Telegram listener (launchd path mismatch)

**What:** `com.claude-hq.watchdog.listener` plist references `listener.py` but launchd can't find it ("[Errno 2] No such file or directory" repeated in `listener.err.log`). The file exists; suspect a working-directory mismatch in the plist.

**Why:** Watchdog can still alert via email (verified — sent 2 reminder emails 2026-05-05). But the conversational layer — replying "show" or "why" or "details" to alerts in Telegram — is broken. Less urgent than the memory issue we already fixed today, but it's a real degradation. Affects future routing digest's reply flow.

**Estimate:** 30–45 min — diagnose + restart service.

**How to start:**
1. Read `watchdog/com.claude-hq.watchdog.listener.plist` — check `WorkingDirectory`, `ProgramArguments` paths, `EnvironmentVariables`.
2. Compare to where `listener.py` actually lives.
3. Either correct the plist path OR set `WorkingDirectory` to the watchdog dir.
4. `launchctl unload + load` to restart.
5. Verify by checking `listener.err.log` — errors should stop, listener should start polling Telegram.

**Acceptance:** No more "can't open file" errors in `listener.err.log`. Sending a Telegram message to the bot gets a routed response.

---

## [Open] — 2026-05-06 — Phase 2: cross-provider routing gateway

**What:** Decide between LiteLLM (BerriAI) and claude-code-router (musistudio) as the localhost proxy that lets the routing hook fall back to non-Anthropic providers (Gemini, Groq, Cerebras). Run as Docker container on `127.0.0.1:<port>`. Wire into the routing decision algorithm so when a tier is chosen, the actual call lands on the cheapest viable provider.

**Why:** Phase 1 captures within-Anthropic routing (Opus / Sonnet / Haiku). The full ~70–85% cost reduction comes from cross-provider — Gemini Flash for bulk summarisation is ~200× cheaper than Opus. Doctrine §13 already specifies the Trust Gate intersection; just need to pick the proxy.

**Estimate:** 1–2 days. Trust Gate Tier C evaluation of whichever proxy we pick, Docker pinning, key migration to Keychain (Lessons 14-15), routing hook integration.

**How to start:**
1. After ~30 days of cost-ledger data (~early June): query ledger to see the actual spend pattern. If Anthropic-only spend is low, this becomes lower priority. If high, high priority.
2. Re-evaluate LiteLLM vs claude-code-router: by then, claude-code-router's CVE-2025-57755 status, BerriAI's Trust Gate posture, and any new contenders in the space.
3. Run Trust Gate Tier C on the chosen proxy (Magika + secret-scan + Socket + reputation).
4. Pin Docker image SHA. Document in `commander/INCIDENT_LEDGER.md` if any vendor enters cooling-off during the eval.
5. Update `model-router.py` to consult provider chain after tier choice.
6. Update `MODEL_ROUTING.md` §13 with the chosen provider chain.

**Depends on:** ~30 days of Phase 1 cost-ledger data. Doctrine is already written.

**Acceptance:** A Haiku-class task routed by the hook actually lands on Gemini Flash via the gateway, observable in ledger. Cross-provider fallback works on 429.

**Update 2026-08-12 (research done, approach CORRECTED — see `project_pomelli_omniroute_eval_2026_08_11.md` + claude-hq Decision Log 2026-08-11/12):** The 2026-05-06 "pick a LiteLLM/claude-code-router proxy" framing is SUPERSEDED. A 5-pass adversarial exploration rejected the proxy approach — a global `ANTHROPIC_BASE_URL` reroute hijacks the whole session, and OmniRoute (the tool the operator surfaced) ships ToS-evasion machinery that risks the Anthropic account. Corrected direction: a thin **Bash-delegation subagent** → an OpenAI-compatible endpoint (the Codex-precedent pattern), never touching the session's base URL. Executor field canvassed: **Groq** = the only genuinely-free + no-train + sustainable backend (rate-limited ~30 RPM / ~1000 RPD on its best coder; open models are Haiku-ish, below Sonnet); Gemini-free and NVIDIA-NIM both TRAIN on submitted data (client-IP disqualified); GLM-5.2 has no free tier ($18/mo Z.ai Coding Plan cheapest). Premise also corrected: the resource saved is the usage-WINDOW (Fable burns it fast), not marginal dollars. **Next step is a small INSTRUMENTED PILOT (Groq + local Ollama, token-logged, hard data-sensitivity gate) that MEASURES the window saving before any full build** — offload only nets a saving on large/low-judgment/machine-verifiable bulk jobs (subagent-tax logic). GLM-5.2 $18/mo = paid upgrade tripwire. Pilot is operator-pending; alternative = hold the ~$4.50/30d status quo. Still gated on the same "~30 days of cost data / measured pain" trigger.

---

## [Open] — 2026-05-06 — Phase 3: quality gate sample-and-grade

**What:** Implement the sampling spec in `MODEL_ROUTING.md` §9. 10% of cheap-tier outputs (Haiku, Gemini Flash post-Phase-2) get spot-graded by next tier up. Disagreement → escalate the whole batch + log `quality_escalated`. Persistent disagreement → surface as doctrine-revision suggestion in weekly digest.

**Why:** Without quality gate, silent regression risk: Gemini Flash returns garbage, Sonnet synthesis silently consumes garbage, output looks plausible. Catching this early via sampling is much cheaper than catching it after a delivered report turns out to be wrong.

**Estimate:** 2–3 days. Sampling logic in routing hook, grader prompt design, ledger schema extension, weekly-digest aggregation hook.

**How to start:**
1. After Phase 2 ships + ~30 days of mixed-tier ledger data.
2. Add `quality_grade` + `grader_model` columns to ledger (migration).
3. In routing hook: 10% sampling on Haiku/Flash dispatches; on completion, async-fire a grader call from the next tier up.
4. Define disagreement threshold (e.g., grader judges output as "would not approve in a code review" → escalate).
5. Extend weekly digest to surface "doctrine row X had >30% disagreement over 50 samples — consider re-mapping."

**Depends on:** Phase 2 shipped (so we have cross-provider data, not just Anthropic-only).

**Acceptance:** Ledger has `quality_grade` populated on ~10% of cheap-tier rows. Synthetic test where deliberately-wrong cheap output is escalated.

---

## [Open] — 2026-05-06 — Phase 4: quota-aware degradation

**What:** Implement the spec in `MODEL_ROUTING.md` §7. Monitor Anthropic Max 5-hour rolling window; when >80% consumed, degrade Sonnet→Haiku and Opus→Sonnet (skipping hard-floor agents). Send PlainAlert via Telegram. User reply "keep big" sets `HQ_QUOTA_AWARENESS=off` for the session.

**Why:** The 2026-04-28 quota incident (Paperclip Fleet on subscription mode + claude-mem CLI mining blew Max 5h window) is exactly what this prevents. We have the doctrine; we don't have the enforcement. Until we do, the next sustained-heavy session is a re-incident risk.

**Estimate:** 1 day. The monitoring source of truth is the unsolved part — see "How to start."

**How to start:**
1. Trigger: either after the next quota incident OR proactively before sustained heavy usage.
2. Identify monitoring source. Candidates: (a) `claude usage` CLI subcommand if exposed, (b) Claude Code's local usage telemetry files, (c) periodic Anthropic API ping with token-counting endpoint. Pick the one that's cheapest + most accurate.
3. Add a polling loop (cron / launchd / inline in routing hook) that updates `run/quota-state.json`.
4. Routing hook reads `quota-state.json`; if `>80% used`, applies degradation per §7.
5. Add PlainAlert template (already drafted in §7) — verify it passes the watchdog jargon linter.
6. Test: simulate >80% state, dispatch a Sonnet task, confirm it runs as Haiku.

**Acceptance:** A simulated >80%-consumed state causes the routing hook to degrade tiers, alert plain English, and respect "keep big" override.

---

## [Open] — 2026-05-06 — Move trust-gate test cases from /tmp into the repo

**What:** Today's session added test cases to `/tmp/test-trust-gate.sh` and `/tmp/test-trust-gate-post.sh` while fixing the eval bug (commits `7e45c3b`, `c6006ab`). Move them into `~/claude-hq/scripts/tests/` as committed regression tests.

**Why:** The /tmp files are ephemeral — next system reboot erases them. The trust-gate scripts are security-critical; we want regression tests that run on every change to those files. Both fixes today were caught by these tests; codifying them prevents the next regression.

**Estimate:** ~30 min — copy, parameterise paths, add a runner.

**How to start:**
1. `mkdir ~/claude-hq/scripts/tests/`
2. Move `test-trust-gate.sh` and `test-trust-gate-post.sh` from `/tmp/` to `scripts/tests/`.
3. Update HQ_ROOT references to use `${HQ_ROOT:-$HOME/claude-hq}`.
4. Add `scripts/tests/run-all.sh` that invokes both.
5. Optional: add a pre-commit hook that runs the tests if either trust-gate script changed.
6. Commit: `test(trust-gate): codify regression tests from 2026-05-06 fix`.

**Acceptance:** `scripts/tests/run-all.sh` exits 0 with all tests passing. Tests are checked into git.

---

## [Open] — 2026-05-06 — HQ root cleanup: orphan .rtf files + DB backup

**What:** Clean up four pre-existing untracked items in `~/claude-hq/` root that surfaced during today's `git status` review:
- `watchdog_commands.rtf`
- `watchdog_reminders.rtf`
- `watchdog_reminders_2.rtf`
- `watchdog/history.db.pre-migration-backup`

**Why:** The .rtf files look like personal scratch notes accidentally saved into the repo root. The `pre-migration-backup` is a stale DB dump from a past Watchdog migration. Neither should be tracked or even visible in git status. Clutter accumulates → real changes get lost in noise → eventually someone commits something they shouldn't.

**Estimate:** 5–10 min — triage decision per file.

**How to start:**
1. Open each .rtf — decide: (a) move to `~/Desktop/` if personal notes, (b) move into a proper docs file if useful, (c) delete if obsolete.
2. For `history.db.pre-migration-backup`: check `git log -p -- watchdog/history.db.pre-migration-backup` (it shouldn't appear; if it does, remove from history). Delete the file or move to `~/.archive/` if you want to keep the snapshot.
3. Add patterns to `.gitignore` if any class of file should never be tracked at root.
4. `git status` should be clean of these four after the pass.

**Acceptance:** `cd ~/claude-hq && git status` shows none of these four files.

---

## [Open] — 2026-05-06 — claude-mem upstream quirk: ChromaSync uses add not update

**What:** When claude-mem worker restarts after a crash and re-processes observations that were partially synced before the crash, the ChromaSync layer fails with "IDs already exist in collection" because it calls `chroma_add_documents` instead of `chroma_update_documents`. Observed during the 2026-05-06 paid-tier flip restart — obs IDs 653, 654, etc. tripped this on retry.

**Why:** Not blocking — SQLite primary store is fine, the worker continues with remaining batches. But the ChromaDB vector index ends up with stale-or-duplicate entries for any observations that span a restart. Affects semantic-search recall quality slightly. Will accumulate noise over time as claude-mem restarts happen.

**Estimate:** ~1 hour upstream. Either patch claude-mem locally or PR upstream.

**How to start:**
1. Locate the ChromaSync code in `~/.claude/plugins/cache/thedotmack/claude-mem/<version>/scripts/` — likely `worker-service.cjs` or a Chroma-specific module.
2. Find the `chroma_add_documents` call that produces this error.
3. Wrap with try-existing-then-update, or use `chroma_upsert_documents` if available.
4. Test by deliberately mid-flight crashing the worker on an observation, then restarting.

**Acceptance:** No "IDs already exist" errors after a restart with mid-flight observations. ChromaDB query returns clean unique vectors.

---

## [Open] — 2026-05-06 — claude-mem upstream quirk: parser cleans observation type from concepts array

**What:** Gemini occasionally includes an observation-type label (e.g. `discovery`) inside the structured `concepts` array of a generated observation. The parser logs `[PARSER] Removed observation type from concepts array` and silently strips it. Cosmetic but suggests prompt conditioning could be tightened upstream.

**Why:** Soft data-quality issue — concepts list is meant to be domain concepts, not observation-type metadata. Stripping is correct, but the log noise + the underlying prompt drift is worth a fix.

**Estimate:** ~30 min — review the prompt template that conditions Gemini, add a stronger negative example.

**How to start:**
1. Find the prompt template in claude-mem's plugin cache that conditions the Gemini observation-extraction call.
2. Add a negative example showing what NOT to put in the concepts array (specifically: "don't include observation type labels like discovery, decision, etc.").
3. Test with a session that previously triggered the warning.

**Acceptance:** No `Removed observation type from concepts array` warnings in claude-mem logs over 1 week of normal usage.

---

## [Open] — 2026-05-06 — Apify-equivalent capability for locked-down platform scraping

**What:** Today's Layer 0 stack (Crawl4AI + Jina + Exa + Puppeteer + Reddit MCP) handles public web pages well but cannot scrape **locked-down social platforms** — Twitter/X, Instagram, Facebook, LinkedIn, TikTok. These sites combine login walls, anti-bot challenges (Cloudflare, Arkose Labs, custom JS challenges), and IP/behaviour fingerprinting that defeats any local-Playwright-plus-LLM-extraction architecture. The gap is "Apify-class capability" — site-specific maintained scrapers running through rotating residential/datacenter/mobile proxies. ScrapeGraphAI was evaluated 2026-05-06 and ruled out (same fetch-and-parse architecture as Crawl4AI, hits the same walls).

**Why:** The gap is real but currently latent — Corporate Brains Phase 1 doesn't need locked-down social data (public sources cover competitor research). For any future project requiring Twitter sentiment, Instagram brand monitoring, LinkedIn employee/funding signals, Facebook page scraping, or TikTok content harvesting, we'd hit the wall. Documenting the three concrete paths now means future-Sunil doesn't redo the eval — just picks the right path for the use case.

**Estimate:** Open-ended — depends entirely on which path. Cheapest to costliest:
- **Pay Apify Actor per-platform** ($30–50/mo): trivial, no engineering work, cancel after use
- **Wire official APIs** (Twitter Basic $100/mo, YouTube free, Reddit free, LinkedIn very expensive): 1–2 hours per platform, sustainable but limited scope
- **Crawlee + self-hosted proxies** (Apify's own open-source actor framework, MIT): 1–2 weeks to set up + ongoing $5–15/GB residential proxy costs

**How to start (when triggered):**
1. **Trigger condition:** a real use case demands locked-down social-platform data that public sources cannot supply. Until then, do NOT pre-build per Lesson 20 — instrument the need first, build second.
2. When triggered: identify the specific platform(s) and the data volume (one-off vs. ongoing recurring).
3. Pick the path:
   - One-off / low volume / single platform → Apify Actor for that platform ($30–50/mo, cancel after)
   - Recurring need on Twitter / YouTube / Reddit only → official APIs (sustainable, ToS-clean)
   - Multi-platform recurring at scale → evaluate Crawlee + proxy infrastructure vs. ongoing Apify subscription
4. **Trust Gate considerations at adoption time:**
   - Apify (the company) — not currently allowlisted; review their security posture, postmortems, and Trust Gate Tier C
   - Crawlee — published by Apify under MIT; run through Tier C
   - `snscrape` / `Instaloader` / `facebook-scraper` — MIT, but fragile (break when platforms update); ToS-grey for some
5. Update `~/claude-hq/registry.json` with the chosen tool(s) at the appropriate Layer.

**Why ScrapeGraphAI was ruled out (so we don't re-evaluate it):** It fetches with local Playwright + extracts with an LLM. That's mechanically identical to Crawl4AI which we already have. Both hit the same walls on Twitter/Instagram/Facebook/LinkedIn — the bottleneck is *getting through the door* (proxies + site-specific Actors), not LLM extraction. Adding it would duplicate Crawl4AI under a different brand without bridging the gap.

**Acceptance:** When the trigger fires, the implementer picks a path from this entry without redoing the evaluation. The chosen path delivers the specific platform data needed for the specific use case, with an entry in registry.json, Trust Gate clearance, and (if recurring spend) a cost-ledger note.

---

## [Open] — 2026-05-06 — Gamma `slug_contains` returns garbage; lifecycle Strategy 3 unreliable

**What:** During PATS-Copy session-start health check on 2026-05-06, queried Gamma API with `slug_contains=hormuz` and got 20 unrelated markets back (Rihanna album, GTA-VI release, Stanley Cup, Harvey Weinstein sentencing — none containing "hormuz" in slug). Either the parameter is silently ignored or it's been deprecated. `position-lifecycle.ts:267` uses this exact parameter as Strategy 3 (broad text search fallback), then takes `markets[0]` as the result — meaning if Strategies 1 and 2 fail, lifecycle silently grabs an arbitrary market and checks ITS resolution status against our position. Currently low-impact because (a) most positions resolve via Strategy 1 (exact slug), and (b) the wrong market is usually `closed=false` so it's a no-op skip; but if the wrong market ever returns `closed=true`, lifecycle would close OUR position at THAT market's settlement price.

**Why:** Silent correctness bug. Mostly inert today, but a one-bad-luck-market away from a wrong-settlement close. Worth fixing or removing the fallback entirely.

**Estimate:** 30 min. Either drop Strategy 3 (preferred — Strategy 1+2 cover the real cases), or replace `slug_contains` with `?q=` if Gamma supports a real text-search parameter.

**How to start:**
1. Probe Gamma's documented parameters — `?q=`, `?slug_starts_with=`, `?text_search=` — to find one that actually filters.
2. If none works, delete Strategy 3 entirely from `position-lifecycle.ts:266-271`. The warn log "Could not find market" will fire instead, which is the correct behaviour.
3. Add a unit test that confirms `_gammaLookup('slug=non-existent')` returns null.

**Acceptance:** Either a working text-search parameter is wired in, or Strategy 3 is removed and Strategy 1/2 become the only paths. No silent wrong-market matches possible.

---

## [Open] — 2026-05-06 — MemPalace `mine` blocked from Claude Code subprocess

**What:** Running `mempalace mine .` from within a Claude Code session against `~/Desktop/POLYMARKET_TRADING_3.0` produces inconsistent failures: first attempt segfaults (exit 139), subsequent attempts return exit 0 silently with no `polymarket_trading_3.0` wing created in the palace. `mempalace status` works fine. `mempalace mine --dry-run` produces correct output. This blocked the same step in the previous session (2026-05-05) too — at that time attributed to TCC (macOS Transparency, Consent, Control) permission issues with the Terminal hosting Claude Code not having Full Disk Access.

**Why:** Memory-layer sync drift. Each blocked session means Phase 3.5 trade observations don't make it into the cross-session palace, weakening the next session's recall.

**Estimate:** 1–2 hours. Mostly diagnostic.

**How to start:**
1. Compare TCC permissions on the Terminal app vs. iTerm vs. Warp — whichever one is hosting Claude Code needs Full Disk Access to `~/.mempalace/palace/`.
2. Reproduce by running `mempalace mine ~/Desktop/POLYMARKET_TRADING_3.0` from a fresh native Terminal window outside Claude Code. If that works, confirms the harness is the issue.
3. Either grant Claude Code's host Terminal Full Disk Access, OR add a session-end hook that runs the mine via a launchd helper outside the harness.
4. Verify by checking `mempalace status` afterward shows the wing populated.

**Acceptance:** `mempalace status` shows a `polymarket_trading_3.0` wing with non-zero drawer counts after a session.

---

## [Open] — 2026-05-07 — PATS-Copy: proportional sizing for copy-trader

**What:** Currently the copy-executor opens every copied position at a flat $20–$100 regardless of how much the leader put on. Leaders make money via asymmetric sizing — small probes ($50) when uncertain, big conviction bets ($5k–$20k) when sure. Their winning trades are large; their losing trades are small. Net positive. Flat-sized copying produces the leader's hit rate without the asymmetric upside, leading to net losses even on profitable leaders.

**Why:** Empirically demonstrated on 2026-05-07. Wallet `0x2005d16a...` has +$151k lifetime realized PnL on Polymarket. We copied 92 of their trades at flat sizing → our PnL on that subset: −$811 with 17.4% WR. Mean entry slippage was 0.32% (negligible). Stop-loss flushed only 4/92 trades. The remaining 88 closed naturally — same direction, similar entry, similar exit, but we lost $888. Conclusion: their edge is asymmetric sizing; flat sizing destroys it.

**Estimate:** 3–5 days. Real engineering work — touches risk-manager, copy-executor sizing logic, capital concentration safeguards.

**How to start (after convergence-copy is validated and shipped):**
1. Pull leader's recent bet-size distribution via `data-api.polymarket.com/positions?user=X` → for each position, `totalBought` / leader's portfolio value gives bet-as-fraction-of-portfolio
2. Add `our_size_factor` to copy-executor: `our_position = our_portfolio × leader_position_pct × scaling_factor`
3. Cap at risk-manager limits — never let any single copy exceed `MAX_POSITION_PCT` of our portfolio (e.g., 20%)
4. Backtest combined with convergence-copy filter: do convergence-confirmed + proportional-sized copies turn the strategy net-positive?
5. If validated, ship behind a feature flag (`PROPORTIONAL_SIZING=true`) so it's reversible

**Acceptance:** Backtest shows PnL improvement vs flat-sizing baseline of at least +$0.50/trade on the same 714 historical trades, with no single position exceeding `MAX_POSITION_PCT` of capital.

**Connection to other items:** Should ship AFTER convergence-copy (item below) is validated, because convergence-copy filters to higher-conviction trades and proportional sizing amplifies the captured edge. Together they're the two halves of "capture leader edge."

---

## [Open] — 2026-05-07 — PATS-Copy: convergence-copy filter (validate via backtest first)

**What:** Currently copy-executor copies any tracked leader's move when filters pass. Proposed: only copy when 2+ tracked leader wallets independently trade the same market in the same direction within a 30-min window — i.e., consensus among smart-money traders, not single-wallet noise.

**Why:** Wisdom-of-crowds principle — N independent skilled traders converging on a position is statistically a stronger signal than any single trader acting alone. Used in equity markets (13F filings consensus), crypto whale tracking. Should filter copy trades to high-conviction moments and avoid "probe" trades.

**Estimate:** Validation backtest 1 day; if validated, build 1–2 days. If not validated, abandon (Lesson 20).

**How to start:**
1. **Validation phase (1 day)** — replay our 714 historical copy_trades. For each, check if 2+ DIFFERENT leader wallets traded the same market within 30 min before our entry. Tag as "convergence-confirmed" vs "single-wallet". Compare PnL distributions.
2. Pre-committed test parameters (anti-overfit): 30-min window, 2+ distinct wallets, exact market match, same side direction.
3. **Independence check** — also measure time gaps between first-mover and second-mover. If consistently <60s → wallets are correlated (1 alpha + copytraders), not independent. Convergence isn't real signal in that case.
4. **If validated** — build convergence detector module that maintains rolling 30-min window of leader trades, fires "convergence" event when 2+ wallets align, copy-executor only acts on convergence events (not single-wallet events).
5. **If not validated** — drop the idea. Combine with proportional sizing as Phase 5 enhancement instead.

**Acceptance:** Convergence-confirmed copies show PnL > 0 across the historical sample, AND meaningfully better PnL/trade than single-wallet copies, AND wallets pass independence check (median gap > 5 min between first and second mover).

---

## [Open] — 2026-05-07 — Re-evaluate `uzucky/watchdog-ai` if it matures

**What:** [uzucky/watchdog-ai](https://github.com/uzucky/watchdog-ai) is a Python runtime verification framework with 6 check types (process, freshness, log_scan, assertion, http, script) that map closely to what we need for the architectural watchdog. Discovered during 2026-05-07 PATS-Copy session research. Not adopted because of Trust Gate concerns: 0 stars, 1 contributor, 1-month-old (created March 2026). Per Lessons 1-2, unproven solo-dev tools are high-risk for production trading bot monitoring.

**Why:** If the project gains traction (≥50 stars, ≥5 contributors, ≥6 months operating cleanly), it becomes a genuine candidate. Its 6 check types are well-designed for AI-built systems and could replace much of our custom rule-runner work. Saves us long-term maintenance if we adopt a maintained upstream rather than rolling our own.

**Estimate:** 1-2 hours re-evaluation when triggered. Trust Gate Tier C if adopted (Magika scan, secret scan, Socket dependency check, reputation review).

**How to start (when triggered):**
1. Re-check stars/contributors/release cadence at https://github.com/uzucky/watchdog-ai
2. If Trust Gate passes, prototype against 1-2 of our existing PATS-Copy watchdog rules — does it catch the same issues our custom rules do?
3. If it works, evaluate migrating from custom Python checks → watchdog-ai checks
4. Decision: keep custom (safer), migrate (less maintenance), or hybrid

**Trigger conditions to re-evaluate** (any one):
- watchdog-ai gains 50+ stars
- watchdog-ai has stable commit cadence > 6 months
- We're maintaining 10+ custom runtime rules and need a framework
- We're spawning 2+ project-native watchdogs and need shared tooling

**Acceptance:** Either we adopt watchdog-ai (replacing our custom Python scripts) and back-port any specific rules upstream, OR we document why it doesn't fit and stop revisiting.

---

## [Done] — 2026-05-08 — PATS-Copy: SELL-aware position sizing (max-loss cap, not just dollar cap)

**Resolved:** Two-part rule shipped at PATS-Copy commit `935d44f` (branch `fix/sell-aware-sizing` merged to `strategy/buy-optimization`):

1. **SELL entry-price floor at $0.05** (`MIN_SELL_ENTRY_PRICE`) — added to `signal-executor.ts` after the existing `MIN_SIGNAL_ENTRY_PRICE` check. Calibrated against 116 historical signal-bot SELLs: the ≤$0.05 bucket accumulated −$840 (driven by a single −$943 event) while $0.05–$0.10 bucket was +$104 with no large losses. Floor removes the catastrophic class while preserving the profitable mid-cheap one.

2. **5% max-loss-per-trade cap** (`MAX_LOSS_PCT_PER_TRADE`) — new `RiskManager.capByMaxLoss()` helper. Computes `max_loss_per_share = (1 − entry)` for SELL, `entry` for BUY. Reduces size if the would-be max-loss exceeds 5% of current balance; rejects entirely if reduction drops below $5 economic floor. Wired into both `signal-executor.ts` and `copy-executor.ts` as the final size step before execute.

**Backtest** against 156 historical signal-bot trades at $5,289 balance:
- Floor-rejected: 32 (avoid −$840 of historical losses)
- Cap-rejected: 0 (floor catches all catastrophic-class first)
- Size-reduced: 25 (small drag: +$16 → −$31 after scaling)
- Untouched: 99 (+$371 unchanged)
- Counterfactual outcome: −$452 → +$340 = **+$792 improvement**
- The 2026-05-07 −$943 BTC trade: FLOOR-REJECTED ✓

**Originally proposed cap was 1.5%; recalibrated to 5% during analysis.** User pushed back on the 1.5% cap as drastic for what looked like a "blue moon" event; the data showed that while catastrophic events ARE rare (1 in 50 cheap SELLs, ~2%), the strategy is still net-negative because each rare event wipes ~50 small wins. The right line was at the entry-price bucket, not at a portfolio-percentage. 5% serves as a backstop for outsized exposures in $0.05–$0.10 range without rejecting the profitable bucket entirely.

**Connection to other 2026-05-08 work:** Together with Phase C Signal v2 (BUY drop + SELL <24h cap) and the pnl-write reliability fix (commit 58d8257), the structural conditions that produced the −$943 event no longer exist in any layer — accounting accurate, sizing capped, position lifetime bounded. Phase G live-trading no longer blocked by this class of risk.

**Original entry (kept for audit trail):**

## [Open — historical] — 2026-05-07 — PATS-Copy: SELL-aware position sizing (max-loss cap, not just dollar cap)

**What:** Position sizer currently treats every trade as if max-loss = dollar amount committed. That is true for BUY (size = max-loss) but false for SELL (max-loss = (1 − entry_price) × shares = much larger when entry is low). On 2026-05-07 a $75 SELL at entry 0.041 carried up to $1,754 max-loss exposure and stopped out at −$943 in a single event — 12.5× the position dollar amount. Add a SELL-aware sizing rule that caps max-loss as a fraction of portfolio (e.g., MAX_LOSS_PCT_PER_TRADE = 1.5% of equity) and reduces size when entry price is low.

**Why:** Surfaced 2026-05-07 Phase A balance investigation. The −$943 single-trade loss accounts for ~97% of the −$976 PnL swing in 11h. Side-aware stop-loss fix (`ef206c1`) is correct but only kicks in at 30% adverse — by then a low-entry SELL has already lost multiples of its size. Pre-fix, this risk was hidden because stop-loss never fired on losing SELLs at all. Sizing-aware-of-side is the structural answer; tuning stop-loss thresholds alone can't fix asymmetric SELL risk.

**Estimate:** 2-3 days. Touches `risk-manager.ts` sizing logic + new MAX_LOSS_PCT config + tests + verification of sizing on actual signal-bot historical sample.

**How to start:**
1. Compute `max_loss_per_share = (1 − entry_price)` for SELL, `entry_price` for BUY.
2. Compute `max_position_loss = max_loss_per_share × shares`.
3. Add config `MAX_LOSS_PCT_PER_TRADE` (start 1.5%, tunable).
4. In sizing path: cap `our_size` so `max_position_loss ≤ MAX_LOSS_PCT_PER_TRADE × current_balance`.
5. Backtest against last 14 days of signal-bot SELL trades — does the cap reject the catastrophic sizes while letting normal trades through?
6. Watchdog Tier 1 rule (Phase B): static check for any code path that opens positions without computing max-loss.

**Acceptance:** No SELL position can be opened where `(1 − entry_price) × shares > 1.5% × balance`. Catastrophic loss class (>5% balance hit per single trade) becomes structurally impossible.

**Connection:** Independent of Signal v2 (Phase C) and proportional-sizing (item above) but should ship before either if sizing math is being touched anyway.

---

## [Done] — 2026-05-08 — PATS-Copy: Supabase pnl-write reliability (audit-trail gap)

**Resolved:** Code fix at PATS-Copy commit `58d8257` (branch `fix/pnl-write-reliability` merged to `strategy/buy-optimization`). Two compound bugs:
- `copy-executor.ts:548` — closePosition called paperEngine.closeTradeByMarketId regardless of whether the marketId was tracked in this.openCopyTrades. For signal-bot trades (owned by signalExecutor per c0e44b9), the trade closed in paperEngine but the function returned null. Added an early-return guard.
- `runner.ts:168` — lifecycle closePosition closure wasn't async-aware. `if (copy)` checked the Promise (always truthy), so signalExecutor branch was dead code. Added async + await.

**Backfill:** `~/claude-hq/watchdogs/pats/scripts/backfill_pnl_writes.py` ran on 2026-05-08. 46 suspect rows total; 2 recoverable from PM2 logs (BTC-80k −$943.04, US-Iran-war −$0.18), applied. 44 unrecoverable (pre-2026-05-06 logs rotated, or reconciliation-only closures with no log line). Per user 2026-05-08 decision: leave the 44 at pnl=0; code fix prevents new occurrences.

**Audit gap closed:** db sum(pnl) was +$158.14, after backfill: −$785.08. Bot's pre-restart in-memory pnl was −$767.15 → residual gap ~$18 (acceptable, attributable to the 44 unrecoverable rows).

**2026-05-08 update — Layer 3 follow-up shipped:** Fixed the secondary pnl=0 source at PATS-Copy commit `6ef3553` (branch `fix/reconciliation-pnl-truthful`). The 15-minute reconciliation routine was overwriting orphan rows with `pnl=0` when its market-cache lookup missed (cache misses happen for resolved markets, slug/condition_id mismatches, or fresh fetches). New three-layer fallback: (1) read pnl from `paperEngine.getClosedTrades()` first — handles the common case where bot hasn't restarted between close and reconciliation, (2) MarketCache lookup as before, (3) leave `pnl` as null (skip the column update entirely) and Telegram-alert the user to investigate. The historical 44 unrecoverable rows are unaffected; this prevents new ones from being created. After this fix, every pnl=0 row in the audit log is intentional history, not future drift.

**Original entry (kept for audit trail):**

**What:** Stop-loss closures sometimes don't write `pnl` back to Supabase — the row stays at `pnl=0` while the bot's in-memory state has the real loss. Sample of 30 low-priced SELL stops in last 7 days: 11 (37%) have `pnl=0` in db. Includes the 2026-05-07 −$943 BTC-80k trade. Bot's in-memory accounting is the truth (balance + .bot-status.json reflect real losses), but the audit trail in `copy_trades` is incomplete. All-time `sum(pnl)` from db = +$158 vs bot reports −$767 → $925 audit gap.

**Why:** Surfaced during 2026-05-07 Phase A. Three downstream effects: (1) reconstruction queries (e.g., this Phase A investigation) undercount losses and create false-positive "regression" signals; (2) dashboard PnL is wrong because it reads db; (3) any future hydration-from-Supabase will mis-restore balance after restart — the bot only computes correct balance now because it had the right state in-memory. A fresh restart-from-cold could reload at the wrong balance.

**Estimate:** 1-2 days. Investigate which close path skips the pnl write (likely reconciliation orphan-close vs primary-path closure), add pnl to those writes, backfill the existing 11 known-bad rows.

**How to start:**
1. Diff the three close paths: `closeTrade` (paper-trading.ts:145), `closeTradeByMarketId` (paper-trading.ts:176), reconciliation orphan-close (somewhere in runner.ts or a reconciler).
2. Find which path doesn't call `updateCopyTrade({pnl})` or where the pnl arg is missing.
3. Fix the missing write.
4. Backfill: write a one-shot script that pulls in-memory closedTrades from a recent bot status snapshot (or recomputes from entry/exit price + size) and updates the 11 rows with correct pnl.
5. Watchdog Tier 1 rule (Phase B): runtime check that flags any `copy_trades.status='stopped'` row with `pnl=0` and `our_size > 0` (impossible state — a stop-loss closure should always have a non-zero pnl).

**Acceptance:** No new `status=stopped` rows with `pnl=0` after fix deploys. Existing 11 rows backfilled. Bot's in-memory PnL matches `sum(pnl)` from db within $5 tolerance.

**Connection:** Pairs naturally with the sizing item above — together they're "make the SELL accounting trustworthy." Watchdog runtime rule from this item directly supports Phase B step 3.

---

## [Open] — 2026-05-08 — Memory probe adoption metric in HQ Watchdog

**What:** Wire two new metrics into `~/claude-hq/watchdog/metrics.yaml`:
1. `memory_probe_invocations_per_session` — count of times `memory-probe.sh` is run per session.
2. `tasks_starting_without_probe` — sessions where I started non-trivial work without first running the probe (heuristic: substantial code/file edits in the first N tool calls without a preceding probe).

**Why:** Lesson 21 (added 2026-05-08) tells me to probe memory before non-trivial work. Without a measurement layer per Lesson 20, this becomes another un-instrumented behavioural rule that can silently drift to "memory of behaviour" rather than actual behaviour. The watchdog is the natural home for adoption signals.

**Estimate:** 1-2 hours. Most of the work is the heuristic for "task started without probe" — needs a sliding window over the session's first 5-10 tool calls and a check for memory-probe.sh invocation.

**How to start:**
1. Add the two metric definitions to `metrics.yaml` with `plain_language` blocks per Lesson 16.
2. Implement the detection in `watchdog/listener.py` or a metric-specific module.
3. Calibrate thresholds after 7 days of data — what's a "normal" probe rate?
4. After 14 days: if the probe rate is too low, surface as a Telegram nudge ("you've started 5 non-trivial tasks today without probing memory — check Lesson 21").

**Acceptance:** Two metrics in `metrics.yaml` with plain-language blocks. Watchdog logs invocations. After 14 days of soak: a baseline number we can use to flag drift.

**Connection:** Lesson 21 is the doctrine; this is the measurement. Without this, the lesson is half a system per Lesson 20.

---

## [Done] — 2026-05-08 (resolved 2026-06-25) — graphify clean regen with `repos/` excluded

**What:** The vault's `Projects/claude-hq/Graph/` was last regenerated 2026-04-21. As of today, `graphify --update` detects 2,158 changed files — but **2,079 of those are inside `~/claude-hq/repos/`** (cloned reference repos that have accumulated since April, not our source). A naive full re-extraction would burn ~60 subagents and 30+ minutes processing material that isn't ours and shouldn't be in our knowledge graph.

**Why:** The graphify skill doesn't natively respect `.gitignore`, even though `repos/` is gitignored. So re-extraction picks up the cloned trees alongside our actual source. We need either (a) a graphify config that excludes `repos/` or (b) a temporary mv-out / mv-back wrapper.

**Estimate:** 1-2 hours. Most of the work is finding / writing the exclude mechanism and validating the resulting graph still has good cross-area connections (commander ↔ watchdog ↔ scripts ↔ patches).

**How to start:**
1. Check graphify's actual file-walk code to see if `--exclude` or `.graphifyignore` exists; if not, propose upstream patch.
2. Alternative: write a wrapper script `~/claude-hq/scripts/graphify-update.sh` that temporarily renames `repos/` → `repos-snapshot/`, runs `/graphify --update --obsidian --obsidian-dir <vault path>`, renames back.
3. Run a clean regen producing `Projects/claude-hq/Graph/` in vault.
4. Commit vault + push.

**Acceptance:** A `graphify --update` invocation that produces a fresh graph covering only HQ source (commander, watchdogs, scripts, patches, docs, agents, tools) without re-extracting `repos/`. Total file count after exclude should be <120, not 2,158.

**Connection:** Hub.md and Decision Log narrative already cover the 2026-05-08 work for human readers — graphify is a nice-to-have visualisation, not blocking. Scheduled regen rather than session-end snapshot per Lesson 20 (don't ship un-instrumented work).

**Resolution (2026-06-25):** Done via the NATIVE `.graphifyignore` (the wrapper plan in "How to start" #2 was obsolete — graphify gained `.graphifyignore` support, verified in `detect.py:256-378`). Created `~/claude-hq/.graphifyignore` excluding `repos/ tools/ graphify-out/ run/` + noise. Adversarial review caught two faults in the original plan before running: (a) `repos/` alone was insufficient — `tools/` (vendored collections, 2,040 files) also polluted; (b) an incremental `--update` would NOT purge existing junk nodes, so a FULL rebuild was required (old `graphify-out` moved to `graphify-out.pre-clean-2026-06-25`). Result: **621 nodes / 26 communities** (was 6,521 nodes, ~78% cloned code); vault `Graph/` **649 files** (was 7,099); 0 `repos//tools/` source-file nodes. Cost: ~342k tokens / 3 semantic worker agents (AMBER, operator-approved; estimate had been GREEN ≤120k — per-agent cost for HQ markdown is ~115k, not the 40k default — calibration logged). Detect classified the real corpus at 74 source files (acceptance "<120" met). FOLLOW-UPS (both shipped 2026-06-25): (1) session-end hook Layer 6 now logs failures to `graphify-out/graphify-export-errors.log` (was a silent `except: pass`); (2) weekly drift-nudge — launchd `com.claude-hq.graphify-weekly` (Sun 09:00) runs `scripts/graphify-freshness-check.sh`, which detects doc drift via `detect_incremental` and nudges (macOS notification + `run/graphify-freshness.log`) to run `/graphify --update` in-session. Deliberately NO auto-LLM (semantic refresh needs a session; weekly auto-burn = the 2026-04-28 quota pattern). ~$0/run.

---

## [Open] — 2026-05-08 — Paperclip watchdog: deferred runtime rules (Phase 2)

**What:** Three rules deferred from the Tier 1 Paperclip watchdog build because they need API surface verification + soak data for calibration:
1. `stale_heartbeat.py` — agent that should have woken in last X minutes hasn't.
2. `failed_run_rate.py` — high failure percentage across runs in a window (warn at >20%, critical at >50%).
3. `stuck_queued_runs.py` — runs queued but not executing for >30 minutes.

**Why:** Tier 1 shipped 4 rules calibrated against the 2026-04-28 quota incident (server health, HC.io relay, token burn rate, agent quota threshold). The 3 above need: (a) Paperclip's `/agents/:id/runtime-state` and `/issues/:id/runs` response shapes mapped end-to-end, (b) a soak window of real Paperclip activity to know what "normal" looks like for stale-thresholds and failure-rate baselines. Shipping uncalibrated would mean alert noise on day one.

**Estimate:** 1 day. Most of the work is calibration during the 14-day soak (2026-05-08 → 2026-05-22), then writing the rules in the same shape as the existing four.

**How to start:**
1. After 2026-05-22 soak end: review `~/claude-hq/watchdogs/paperclip/audit.log` for what real Paperclip activity looks like.
2. For stale_heartbeat: pick a stale-window threshold (likely 2× the agent's configured heartbeat interval).
3. For failed_run_rate: confirm the failure-rate baseline from soak data, set warn at 2× normal, critical at 4×.
4. For stuck_queued_runs: confirm Paperclip's existing stale-run cancellation timeout in `heartbeat.ts`, set the watchdog threshold below it so we alert *before* Paperclip auto-cancels.
5. Write each rule following the pattern in `~/claude-hq/watchdogs/paperclip/rules/runtime/server_health.py`.

**Acceptance:** Three new rules in `rules/runtime/`, each tested with `--once-stdout`, plain-English findings, audit-log entries. Soak window for the new rules: 7 days each (shorter than initial soak because the orchestrator pattern is already proven).

---

## [Done] — 2026-05-08 — Paperclip dedicated watchdog (Tier 1)

**What:** Built `~/claude-hq/watchdogs/paperclip/` as the second tenant of the watchdogs framework (PATS was first). Four runtime rules: server_health, healthchecks_io_relay, token_burn_rate, agent_quota_threshold. Soak mode default for 14 days (ends 2026-05-22). launchd plist included but NOT auto-loaded — operator installs manually.

**Why:** The 2026-04-28 quota incident proved Paperclip needs per-project monitoring beyond its built-in `/health` and stale-run cleanup. Mirrors the dedicated PATS watchdog pattern. Replaces the manual `~/claude-hq/scripts/paperclip-burn-tracker.py` script (which stays as a one-off CLI tool but isn't on a timer).

**Resolution:** Files: `orchestrator.py`, 4 runtime rule scripts, `lib/{finding,alerts,paperclip_api}.py`, `com.claude-hq.paperclip-watchdog.plist`, README. Reminder set in `watchdog/reminders.json` for 2026-05-22 soak end. Telegram alerts prefixed `[Paperclip]` to distinguish from PATS.

**Healthchecks.io setup:** ✅ Done 2026-05-08. Two checks created in user's existing HC.io account: `paperclip-server` and `paperclip-watchdog`. URLs in `~/claude-hq/watchdog/healthchecks-urls.env`. Initial ping confirmed (HTTP 200 from both endpoints). Note: `_ping()` now uses certifi's CA bundle because macOS system Python doesn't link the SSL bundle by default — fix applied in `rules/runtime/healthchecks_io_relay.py`.

**Connection:** Tier 1 only — detect + alert, no auto-fix. Tier 2-4 deferred per the existing project-watchdog framework.

---

## [Open] — 2026-05-08 — Trust Gate: npm-registry-aware author resolution for bare packages

**What:** When a `npm install <pkg>` command is run with a bare package name (e.g. `npm install ethers@^6`, no `@scope/`), the Trust Gate's `extract_owner()` returns empty because there's no slash. The package always falls into UNKNOWN AUTHOR, even for trusted maintainers (e.g. ethers maintained by `ricmoo` / `ethers-io` org). This forces `HQ_TRUST_OVERRIDE=1` for legitimate installs every time.

**Why:** The npm registry `/{pkg}` endpoint returns repository URL + maintainer list as authoritative metadata. We can resolve `ethers@^6` → `github.com/ethers-io/ethers.js` → owner `ethers-io` and check that against the existing allowlist. Same flow as the GitHub URL parse, just one HTTP indirection.

**How:**
1. In `scripts/lib/advisory-check.sh`, add `resolve_npm_owner()`: cheap `curl https://registry.npmjs.org/{pkg}` (with timeout), parse `repository.url` field, run through existing `extract_owner` regex to pull github org.
2. Cache results to `/tmp/trust-gate-npm-cache.json` keyed by pkg name (TTL 24h) so we don't hit npm registry on every install.
3. If the registry resolution fails (network, 404, malformed), fall through to current UNKNOWN behavior — no regression.
4. Update `commander/TRUST_GATE.md` Layer 0.5 docs.

**Acceptance:** `npm install ethers@^6` auto-passes via the existing `ethers-io` allowlist entry (added 2026-05-08 for PATS Branch 2). `npm install some-typosquat` still falls into UNKNOWN as today. Cache invalidates correctly when a package's repository URL changes.

**Estimate:** 1–2 hours. Mostly bash + curl + jq.

**Source:** 2026-05-08 PATS-Copy Branch 2 build — needed `ethers@^6` for Polygon WS monitor, hit UNKNOWN AUTHOR despite ethers being one of the most-installed Ethereum libraries. Added `ethers-io` and `Polymarket` to the allowlist for git-clone path coverage but the npm-bare-package flow still requires registry-lookup to benefit.

---

## [Open] — 2026-05-09 — PATS-Copy: Branch 3 — geopolitics pipeline on Option D (replaces obsolete env-flag variant)

**What:** Implement Branch 3 (geopolitics copy revival) as a third pipeline on the post-Option-D architecture. Same wallet list (12 geopolitics leaders from convergence backtest), same edge thesis (+$168.79/trade per multi-category backtest), but as a first-class pipeline with its own `RiskManager`, capital pool, position cap, and risk gates — NOT as an env-flag-on-shared-bot retrofit.

**Why:** The original master-handoff Branch 3 design (`COPY_GEOPOLITICS_ENABLED=true`, `COPY_GEOPOLITICS_WALLETS=...`, ~30 min of work) is obsolete after the 2026-05-09 Option D architecture decision. Landing it on the shared-state design would re-create the cross-pipeline contagion problem Option D was designed to solve. The geopolitics edge (+$168.79/trade) is real and worth pursuing, but only on the better foundation. See Decision Log entry "Architecture decision: Option D" (2026-05-09).

**How:**
1. Pre-req: Option D refactor complete (BACKLOG entry above).
2. Add `geopolitics` as a pipeline ID in the post-Option-D `Map<PipelineId, RiskManager>`.
3. Capital allocation env var: `GEOPOLITICS_CAPITAL=<N>` (sum of all pipeline capitals ≤ `TOTAL_CAPITAL_USDC`).
4. Build `GeopoliticsPipeline` (or extend `CopyExecutor` with a pipeline-aware filter):
   - Watch the 12 wallets from the convergence backtest (list in master handoff)
   - Filter to geopolitics-category markets only (use existing `market-categoriser.ts` `categoriseMarket()` function)
   - Trade only when both wallet AND category match
5. Watchdog: add `geopolitics-cumulative-pnl` rule (the 5th rule from the master handoff Phase 5 list, deferred to here).
6. Paper-mode validation soak: ≥30 days with the pipeline running on paper, hitting the live-readiness combined bar (WR ≥55%, no single-day drawdown >10%, cumulative P&L positive).

**Acceptance:**
- Pipeline trades only when (wallet ∈ 12 geopolitics leaders) AND (market category == 'geopolitics')
- Per-pipeline P&L queryable via Supabase `pipeline='geopolitics'` filter
- Geopolitics pipeline's loss does NOT reduce signal-bot's drawdown headroom (Option D guarantee)
- Watchdog `geopolitics-cumulative-pnl` rule emits findings if rolling-7d P&L drops below a configured floor

**Estimate:** 1-2 days dev + 30 days paper soak (in parallel with Phase 4b Polymarket live ramp on signal-bot).

**Sequencing:** AFTER Option D refactor. BEFORE Phase 4b live trading goes wide (geopolitics paper soak runs concurrently with signal-bot's live test on Polymarket — they're independent gates).

**Source:** 2026-05-09 conversation — user asked to confirm Branch 3 status. Original env-flag plan superseded by Option D. Reframed plan documented and confirmed.

**Empirical priority anchor (added 2026-05-10):** Forensic on the March→April WR collapse + 30-day P&L data shows the bot's profitable era (March 2026: +$1,008 across 215 trades, 44.2% WR) was 100% from copy pipeline. Signal-bot solo is structurally break-even. Branch 3 is therefore the highest-priority profit lever — the structural path back to March-level monthly profits, not a side-experiment.

**Mandatory feature (NOT optional):** Branch 3 must mirror leaders' position size *relative to their typical* (their conviction signal), not absolute. Flat-copying is what destroyed April 2026 — leader `0x2005d16a` (lifetime +$151k PnL on Polymarket, asymmetric-edge sizing) ramped to 42 trades on 2026-04-07 and our flat-size copy lost −$470 on that wallet alone. Without proportional sizing, Branch 3 will reproduce April's loss pattern even with the F-series fixes in place.

**Full empirical justification:** Vault Decision Log entry "2026-05-10 — Forensic: March → April WR collapse + the case for restoring copy pipeline".

---

## [Open] — 2026-05-09 — PATS-Copy: Phase 4b — Polymarket live trading (signal-bot first)

**What:** Enable real-money execution on Polymarket CLOB for the signal-bot pipeline (most-validated pipeline). Add a Polymarket execution path alongside the always-running PaperEngine. Other pipelines (copy-bot, geopolitics) stay paper-only initially. Per-pipeline opt-in via `<pipeline>_LIVE_TRADING=true` env vars.

**Why:** Signal-bot has the most production track record (live since 2026-04-28, profitable +$287 across 55 trades pre-Phase-C, currently in Phase C with BUY disabled and SELL <24h-cap). The next step toward real revenue is moving signal-bot from paper to live with a small bankroll. Keep paper engine running as the always-on baseline for slippage/fee measurement (per Mission Board's dual-mode-parallel-execution architecture).

**How:**
1. Pre-req: Option D refactor complete + Branch 3 implemented (so per-pipeline live flags actually work).
2. Build Polymarket live-execution path:
   - CLOB order placement via `py-clob-client` or equivalent TS client
   - Authentication / API key / proxy wallet setup
   - Order types: limit orders only (no market orders for safety)
   - Fill tracking and reconciliation against Polymarket API
3. Per-pipeline opt-in env vars: `SIGNAL_LIVE_TRADING=true`, `COPY_LIVE_TRADING=false`, `GEOPOLITICS_LIVE_TRADING=false`.
4. Bankroll: $500 to start (Mission Board recommendation), separate Polymarket account from paper-tracked balance.
5. Paper engine continues running for ALL pipelines as baseline / control group — every live trade has a paper twin for slippage/fee measurement.
6. Watchdog rules: add `live-vs-paper-divergence` (alert if live fill price differs from paper expected fill by >X%), `live-execution-failure` (alert if live order placement fails), `polymarket-api-health` (alert on persistent CLOB API errors).
7. Daily reconciliation: live position book vs paper position book vs Supabase. Find drift early.

**Acceptance:**
- Signal-bot trades placed on real Polymarket against the $500 bankroll
- Paper engine continues to run with the same signals for direct slippage/fee comparison
- For ≥30 days: WR stays ≥55%, no single-day drawdown >10%, cumulative live P&L positive
- Daily reconciliation passes (live ↔ paper ↔ Supabase all match within $5 drift)
- After 30 days clean, this pipeline is eligible for the dYdX gate (Phase 4c)

**Estimate:** 3-5 days dev (CLOB execution path is non-trivial), then 30+ days observation.

**Sequencing:** AFTER Branch 3 (so all three pipelines exist on Option D). BEFORE Phase 4c (dYdX). Other pipelines (copy, geopolitics) stay paper-only during this phase — they go through their own Phase 4b later, on their own timeline, after they pass the live-readiness combined bar in paper.

**Risks to flag during implementation:**
- Polymarket CLOB has thin liquidity on long-tail markets — slippage on paper vs live can be material. Worth running a 1-week pre-flight where signals fire but DON'T execute live, just log "would have placed order at $X, current bid/ask is $Y/$Z" to estimate slippage.
- Real-money orders need explicit kill switches — add a `LIVE_TRADING_KILL_SWITCH` env that, when set, immediately cancels open orders and stops new placements. Wire to a manual command + watchdog auto-trigger.

**Source:** 2026-05-09 conversation — confirmed sequencing with Sunil. Combined-bar live gate + per-pipeline opt-in.

---

## [Open] — 2026-05-09 — PATS-Copy: Phase 4c-d — dYdX directional-mirror integration (post-Polymarket-live)

**What:** Add dYdX as a third execution venue (alongside paper + Polymarket live), per-pipeline opt-in. Use dYdX perpetual contracts to **mirror Polymarket trade direction with leverage** on the subset of Polymarket markets that have a dYdX analog. Phase 4c is the foundation (build path, validate at 2x leverage, minimum positions). Phase 4d is scale-up (increase position sizes and leverage once verified).

**Why:** dYdX perpetual contracts can amplify returns on directionally-correlated trades (e.g., Polymarket "Bitcoin above $78k by EOD" maps to dYdX BTC-PERP LONG). 2-20x leverage on the same conviction signal compounds the strategy's edge. Mission Board has the original architecture sketch from 2026-04 era; this entry consolidates and extends it to fit Option D + post-Branch-3 reality.

**Confirmed direction (2026-05-09):**
- **Use case: directional mirror with leverage** (NOT hedging, NOT standalone strategy). Same direction as Polymarket trade, leveraged 2-5x at start, on dYdX perpetual when an analog market exists.
- **Live gate (per-pipeline combined bar):** WR ≥55% sustained 30 days AND no single-day drawdown >10% AND cumulative P&L positive AND ≥1 month after that pipeline went Phase-4b live on Polymarket.
- **Sequencing:** AFTER Phase 4b (signal-bot Polymarket live). Each pipeline graduates independently to dYdX once it passes the gate.

**Identified gaps the Mission Board doesn't address (must solve in Phase 4c):**

1. **Market-mapping layer.** Most Polymarket markets have NO dYdX analog. Need a deterministic mapper:
   - Input: Polymarket slug (e.g. `bitcoin-above-78k-on`)
   - Output: dYdX market id (e.g. `BTC-USD`) + directional translation (Polymarket "BUY YES" = dYdX "LONG") + size translation
   - For markets with no analog: skip dYdX, Polymarket-only execution
   - Maintain mapping config in `dydx-market-map.json` with manual curation (high-confidence mappings only)

2. **Position-sizing math.** Polymarket "$75 size at $0.92" is NOT directly equivalent to "$75 notional on dYdX at 2x leverage."
   - Polymarket position has finite floor (-$X if NO resolves)
   - dYdX position has continuous mark-to-market and liquidation risk
   - Need a sizing rule: "match expected dollar P/L on a 1% adverse move" or similar
   - Document the math, validate against historical data before going live

3. **Funding rate accounting.** dYdX charges/pays funding every 8 hours.
   - For multi-day Polymarket positions (e.g. monthly markets), funding can accumulate to material % of position
   - Decision: cap dYdX hold duration to ≤24h (only mirror short-duration Polymarket positions)? Or track funding as a separate cost component?
   - Recommend: cap hold duration to match Polymarket position's expected hold, with a hard 7-day max.

4. **Per-pipeline subaccount strategy.** dYdX V4 has subaccounts.
   - Recommend: per-pipeline subaccount on dYdX (signal-bot subaccount, copy-bot subaccount, geopolitics subaccount). Matches Option D's capital-pool isolation.
   - Each subaccount has its own margin pool, position limits, P&L tracking.
   - dYdX SDK supports multi-subaccount; cleaner accounting.

5. **Liquidation safety.** Even at 2x, dYdX positions can liquidate on sharp moves.
   - Add `MAX_LEVERAGE_PER_PIPELINE` config (start: 2x for all, raise to 5x after 30 days clean, never above 10x)
   - Add a `dydxMarginBuffer` rule in RiskManager — never deploy more than 80% of subaccount equity to position margin
   - Watchdog rule: alert if any subaccount equity drops below the maintenance margin floor

**How (Phase 4c — foundation, 5-7 days dev + 30 days paper soak):**
1. Build dYdX execution path: REST + WebSocket SDK (Python or TS — dYdX V4 has good support for both)
2. Per-pipeline subaccount creation + funding (dYdX testnet first, mainnet after dev complete)
3. Build market-mapping layer (`dydx-market-map.json`)
4. Build sizing-translation logic (Polymarket size → dYdX notional)
5. Build position-management module (open / close / monitor / forced-close on liquidation risk)
6. Wire ExecutionRouter: signal → paper (always) + Polymarket live (if pipeline LIVE flag) + dYdX (if pipeline DYDX_ENABLED flag AND market has analog)
7. Per-pipeline env vars: `<pipeline>_DYDX_ENABLED=true`, `<pipeline>_DYDX_LEVERAGE=2`, `<pipeline>_DYDX_MAX_POSITION=100`
8. Watchdog rules: `dydx-funding-rate-spike` (alert on unusual funding), `dydx-margin-buffer-low` (alert <80% buffer), `dydx-liquidation-risk` (alert if position margin <120% maintenance), `dydx-vs-polymarket-price-drift` (alert if dYdX market price diverges from Polymarket by >X%)
9. Phase 4c starts on testnet, then minimum-position mainnet (e.g. $50 notional at 2x = $100 effective per trade)

**How (Phase 4d — scale, runs continuously after 4c proves out):**
1. After 30 days clean on Phase 4c (WR maintained, no liquidations, no funding-rate surprises), increase position sizes on a schedule (2x notional every 14 days)
2. Leverage stays at 2x until 90 days clean, then 3x, then re-evaluate
3. Cap on increase: don't exceed `<pipeline>_DYDX_MAX_ALLOCATION` of pipeline's total capital
4. Each leverage step is its own decision gate, NOT automatic

**Acceptance (Phase 4c):**
- dYdX execution path lives and tested on testnet
- Market-mapping layer covers ≥80% of price-of-asset Polymarket markets that signal-bot trades
- Per-pipeline subaccounts open and funded
- 30 days mainnet at minimum positions (2x leverage, $50 notional) without: liquidation event, funding-rate surprise >2% of position, dYdX-vs-Polymarket price drift >5%, or watchdog alert escalation
- Live P&L tracking integrated into bot status + Supabase

**Acceptance (Phase 4d):**
- Each scale-up step (2x → 4x notional, etc.) requires: prior 14 days clean + manual user confirmation. Not automatic.
- Pipeline never exceeds `<pipeline>_DYDX_MAX_ALLOCATION` of its total capital pool

**Estimate:** Phase 4c = 5-7 days dev + 30 days observation. Phase 4d = ongoing, no fixed end.

**Sequencing:** AFTER Phase 4b for any given pipeline. signal-bot likely first to hit dYdX (most-validated). copy-bot and geopolitics follow on their own timelines.

**Source:** 2026-05-09 conversation — Mission Board's original Phase 4c-d plan retrieved, gaps identified (market-mapping, sizing math, funding rates, subaccount strategy, liquidation safety), reframed for Option D + per-pipeline architecture. User confirmed: directional mirror, combined-bar gate, post-Polymarket-live sequencing.

---

## [Open] — 2026-05-09 — PATS-Copy: per-pipeline RiskManager + capital pools (Option D refactor)

**What:** Refactor the bot from one shared `RiskManager` (single balance, single drawdown breaker, single position cap, single max-loss cap) to per-pipeline `RiskManager` instances (one each for signal, copy, future Branch 3 geopolitics). Each pipeline gets a fixed capital allocation from total $6,300 (e.g. signal $4000, copy $2000, reserve $300). Single Node process, single pm2, single watchdog — but isolated capital pools and risk gates per pipeline.

**Why:** Verified 2026-05-09 by direct code inspection (`risk-manager.ts:23-35`, `runner.ts:144`, `position-lifecycle.ts`): `paperEngine` + `riskManager` are single instances shared by both `signalExecutor` and `copyExecutor`. The `MAX_OPEN_POSITIONS` cap, drawdown breaker, max-loss cap, balance, and peakBalance are all *shared state*. The 2026-05-07 −$943 SELL incident drained the shared balance, reducing risk gates that copy pipeline would have computed against — bad outcomes propagate across uncorrelated strategies, the opposite of why you run multiple strategies. The Branch 3 master-handoff plan (env-flag-on-shared-bot) would land on this same flawed foundation. Splitting now means Branch 3 (and any future strategy) plugs in cleanly.

**Why not full split (separate Hetzner / separate pm2 / separate repo):** Operationally expensive (2x infra, 2x watchdog, 2x heartbeat, 2x debugging surface) for diminishing returns. In-process pipeline isolation captures the value (capital + risk separation, independent tuning, trivial attribution) without the operational tax. This matches how multi-strategy hedge funds actually run: isolated capital pools, shared infrastructure.

**How:**
1. `RiskManager` constructor takes `(pipelineId, capital, riskDial, opts)`. State stays per-instance.
2. `Runner` holds `Map<PipelineId, RiskManager>` instead of `private riskManager: RiskManager`.
3. Each executor (`signalExecutor`, `copyExecutor`) receives its own `RiskManager` via constructor, not the shared one.
4. Capital allocation at startup from env vars: `SIGNAL_CAPITAL`, `COPY_CAPITAL`, `RESERVE_CAPITAL` (sum ≤ `TOTAL_CAPITAL_USDC`).
5. Supabase: add `pipeline` column to `copy_trades`, default backfill `leader_wallet === 'signal-bot' ? 'signal' : 'copy'`.
6. Position cap becomes per-pipeline (e.g. signal cap=3, copy cap=2). `maxOpenPositions` config moves under `risk.<pipeline>` namespace.
7. Drawdown breaker becomes per-pipeline. peakBalance persistence file gets a per-pipeline JSON structure.
8. STATUS log shows a row per pipeline.
9. Watchdog rules become pipeline-aware. The existing `low_priced_sell_max_loss` rule already groups by `leader_wallet` so it's halfway there — needs a pipeline column read.
10. Branch 3 (geopolitics copy revival) plugs in as a third pipeline (or as a sub-mode of the copy pipeline with its own RiskManager).

**Acceptance:** A −$1000 loss on the signal pipeline does NOT reduce the copy pipeline's available capital, drawdown headroom, or max-loss-dollar cap. Per-pipeline P&L is queryable directly from Supabase via the `pipeline` column without `leader_wallet` string filtering. The bot survives a 30-min stress test where one pipeline is forced to trade aggressively while the other remains healthy.

**Estimate:** 1–2 days focused work, plus a 24h paper-mode validation soak before live.

**Sequencing:** Do AFTER Phase 6 verdict on Branch 2 (don't refactor concurrently with shadow validation). Do BEFORE Branch 3 build (so Branch 3 lands on the better foundation, not retrofitted onto shared).

**Source:** 2026-05-09 conversation during Branch 2 deploy. User asked whether signal + copy should run as separate entities or share state. CTDD verification confirmed shared design is the architectural shape today (see Decision Log entry "Architecture decision — Option D: per-pipeline RiskManager + capital pools" in `JARVIS-BRAIN/Projects/PATS-Copy/04 Decision Log.md`). User preference confirmed for Option D.

---

## [Open] — 2026-05-09 — Re-evaluate GitNexus + Composio if specific gaps surface

**What:** Two HQ integration candidates evaluated 2026-05-09 and skipped. Park here so future-self can revisit without re-deriving the analysis. Full evaluation memory: `~/.claude/projects/-Users-sunil-rajput/memory/reference_gitnexus_composio_eval_2026_05_09.md`.

**Why skipped:**
- **GitNexus** (https://github.com/abhigyanpatwari/GitNexus) — ~80% of its 16 MCP tools duplicate code-review-graph already wired into HQ. PolyForm Noncommercial 1.0.0 licence permits use only "without any anticipated commercial application," which technically blocks application across PATS-Copy, Artist Video Tool, Wasserman, Corporate Brains. Two genuinely-new features (multi-repo group analysis, auto-generated per-repo skills via community detection) but no current pain point demanding them.
- **Composio** (https://docs.composio.dev) — Hosted credential broker. Direct violation of Lessons 14 + 15 (API keys, OAuth tokens live in macOS Keychain via local launchers, never on third-party servers). No SOC-2 / data-handling disclosure below enterprise tier. Free tier 20k calls/month exists but any HQ project crossing that line hits $29/month and a COST_CONTROL.md Tier 4 approval gate. Self-host enterprise-only.

**Revisit triggers (specific, measurable):**
1. **GitNexus revisit:** code-review-graph proves blind to multi-repo / cross-project queries during Option D refactor or Branch 3 build. Concretely — if user finds themselves manually correlating changes across `~/claude-hq/scripts/` and a project repo and wishing for a single graph query that spans both, that is the moment.
2. **Composio revisit:** Specific throwaway prototype needs ≥5 SaaS integrations in <1 day with no production credential exposure (e.g., Corporate Brains investor demo). OR: Composio publishes self-host + SOC-2 + clear data-handling at a reasonable tier.

**How to start:** Re-read the evaluation memory file, re-run `WebFetch` on both URLs to refresh state (releases / pricing / licence may have moved), re-test the specific pain point that surfaced, decide integrate / skip-permanently.

**Acceptance:** Decision logged either way. If integrated, add to `~/claude-hq/registry.json` with activation triggers + cost flag + Trust Gate exception note. If skipped permanently, mark this entry `[Done]` with the reason.

**Estimate:** 30-60 min to re-evaluate when triggered, plus integration time if proceeding.

**Source:** 2026-05-09 conversation. User asked for CTDD evaluation, accepted skip verdict, requested log for future reference rather than action. Full reasoning preserved in memory file above.

---

## Source

Captured 2026-04-22 during HQ activation conversation. User (Sunil) asked whether to install ruflo / seed / paul / TECCP into HQ. Conclusion was that adding more frameworks adds overhead without clear gain — these four actions are the higher-leverage alternatives. Full reasoning is in that session's transcript.

Items 5–11 added 2026-05-06 during the multi-model routing build session (Phase 0 + Phase 1 shipped, Trust Gate eval bug fixed). Items 5–9 are the Phase 2/3/4 + Watchdog listener + digest deferrals; items 10–11 are housekeeping found during the build.

Items 12–13 added 2026-05-06 after the claude-mem paid-tier flip exposed two upstream quirks during backlog drain. Both non-blocking.

Item 14 added 2026-05-06 after evaluating ScrapeGraphAI for HQ integration. Captures the Apify-class gap with three concrete paths so future-self doesn't redo the eval. ScrapeGraphAI itself was ruled out for HQ — see the entry's "Why ruled out" subsection.

---

## [Done] — 2026-05-11 — [PATS-Copy] Branch 3 Geopolitics Specialist Research Sprint

**Outcome (resolved 2026-05-11 same day):** Verdict **SWAP** — drop `0x5d05b1f5` from primary watch list, lead with `0x24c8cf69a0e0a17eee21f69d29752bfa32e823e1` (Phase 2 v2 passer: 149 geo positions, 62.4% WR overall, 69.6% resolved-only WR, +$142K all-time truePnl, +$116K resolved-only realized P&L, median bet $167). Keep `0x44c1dfe4` as Tier-2 candidate. Recommended sizing: **flat $75** (out-performed proportional in every cut). Sprint findings doc: `~/Desktop/POLYMARKET_TRADING_3.0/_NEXT_STEPS/branch-3-research-2026-05-11.md`. Decision Log entry: 2026-05-11 "Branch 3 research sprint COMPLETE — SWAP verdict" in `~/Vaults/Jarvis-Brain/JARVIS-BRAIN/Projects/PATS-Copy/04 Decision Log.md`.

**Big surprise:** the 2026-05-11 baseline measurement was structurally biased. `gamma-api/markets?condition_ids=` silently omits resolved markets, so the original backtest could only see still-open positions — which were systematically the wallet's still-winning bets. The unbiased `/positions?user=X` endpoint reveals `0x5d05b1f5` is actually NET NEGATIVE on its own track record (−$2,405 / 53.6% WR / median bet $5.44). This bug created 4 follow-up BACKLOG items (below).

**Build NOT yet started** — verdict is recommendation only, user-decision boundary respected per sprint constraints.

---

## [Done] — 2026-05-11 — [PATS-Copy] Fix `market-categoriser.ts` politics keyword gaps

**Outcome (resolved same day):** Landed in bot repo as commit `fix(categoriser): add Iran/Israel/Gaza/Netanyahu keywords to politics filter`. 28 keywords added (iran, israel, gaza, palestine, hamas, hezbollah, lebanon, syria, taiwan, north korea, jerusalem, west bank, middle east, venezuela, netanyahu, zelensky, erdogan, kim jong, starmer, lutnick, noem, rubio, hegseth, epstein, treaty, embassy, ambassador, diplomatic). Conservative scope: skipped bare ambiguous terms (war, strike, coup, invasion, occupation, china, russia) to avoid false positives on non-political contexts — sports keywords iterate first anyway. Verification: `scripts/verify-categoriser.ts` pins 36 sprint-discovered fixtures, all pass; `tsc --noEmit` clean. Branch 3 wallet-eligibility gate now sees Iran/Israel/Netanyahu titles correctly.

**What (original):** Add missing geopolitics keywords to `src/signals/market-categoriser.ts:KEYWORDS.politics`: `iran`, `israel`, `gaza`, `palestine`, `hamas`, `hezbollah`, `netanyahu`, `taiwan`, `north korea`, `jerusalem`, `west bank`, `middle east`, `lebanon`, `syria`, `erdogan`, `kim jong`, `coup`, `invasion`, `occupation`, `treaty`, `embassy`, `ambassador`, `diplomatic`, and several Trump-cabinet figures (`lutnick`, `noem`, `rubio`, `hegseth`). Same applies to `detectSpecialistCategory` consumer code if it has any dependent thresholds.

**Why:** The categoriser under-counts geopolitics activity. During the 2026-05-11 research sprint we found that a specialist with 26 broad-geopolitics positions only registered ~14 of those as "politics" via the current keyword list — the Iran/Israel/Netanyahu/Gaza titles fall through to 'other'. This skewed the Phase 1b watchlist audit and the Phase 3 backtest narrowing. Patch BEFORE Branch 3 ships — it currently uses the buggy categoriser for the wallet-eligibility gate.

**Estimate:** 30 min. Drop new keywords into the array, run `npm test` if any exist, commit.

**How to start:**
1. Open `src/signals/market-categoriser.ts`.
2. Extend the `politics` keyword array with the list above (full set in `scripts/research/phase2v2-screen-via-positions.ts:GEO_KW`).
3. Run any unit tests touching `categoriseMarket` (if absent, add a few examples from the sprint: "US forces enter Iran by March 31?", "Netanyahu out by June 30?", "Iranian regime fall before 2027?" — each should categorise as `politics`).
4. Commit: `fix(categoriser): add Iran/Israel/Gaza/Netanyahu keywords to politics filter`.

**Acceptance:** the 3 sprint-discovered test titles classify as politics. No regression on existing categorisation.

**Source:** 2026-05-11 Branch 3 research sprint (Phase 2 v2 deep-dive). Sprint findings doc has full surfaced keyword set.

---

## [Done] — 2026-05-11 — [PATS-Copy] Branch 3 backtest harness — replace Gamma MTM with combined `/positions` + `/trades`-flow aggregation

**Outcome (resolved same day):** Closed. Both the screening layer (`scripts/research/phase2v3-screen-combined.ts`) and the backtest harness (`scripts/backtest/branch3-geopolitics.ts`) now use the canonical truePnl measurement (per-position cashPnl + realizedPnl from `/positions`, with trade-flow cashflow fallback for sell-out positions).

Verdict reversal on the 3-wallet shortlist over the same 30-day window:

| | Old harness (Gamma-biased) | New harness (positions+trade-flow) |
|---|---|---|
| leader truePnl total | −$14,178 | +$173,348 |
| combined proportional | +$52 | +$11,505 |
| combined flat $75 | +$693 | +$31,163 |
| `0x24c8cf69` proportional | −$52 (the artifact) | +$10,794 (129% ROI) |

The corrected measurement reveals `0x24c8cf69`'s $82K April-22 Iran-peace redemption + $32K Iranian-regime-fall + $9.7K Trump-Iran-ops-end that Gamma had hidden. Same wallet, same trades, just the right tool.

Small follow-up flag: 212 positions skipped as "open w/o /positions entry" in the test run — probably small share balances under /positions' threshold or partially-redeemed positions. Worth a tiny investigation if maximum coverage matters; not blocking any current decision.

**What (original):** `scripts/backtest/branch3-geopolitics.ts` STAGE 3a uses `gamma-api.polymarket.com/markets?condition_ids=<cid>` to compute MTM. Gamma silently omits resolved markets — so the harness systematically excludes the wallet's longest-standing realised wins/losses. Replace this MTM source with combined `/positions` + `/trades`-flow logic (see `scripts/research/phase2v3-screen-combined.ts` for the canonical implementation pattern).

**Why:** This bias is what produced the misleading 2026-05-11 baseline verdict. Sprint Phase 3 re-run with new shortlist suffered from the same bias (119/177 positions skipped). The harness CANNOT measure cumulative geopolitics-specialist edge without this fix. Without it, every future Branch 3 calibration run will repeat the bias.

**Estimate:** 2-3 hours. Refactor STAGE 3a-b to fetch /positions per leader, join trades by conditionId+outcomeIndex, use truePnl = cashPnl + realizedPnl as the position outcome.

**How to start:**
1. Build a `fetchPositions(wallet)` helper modelled on `scripts/research/phase2v2-screen-via-positions.ts:fetchPositions`.
2. For each leader, fetch /positions ONCE, build a map keyed by `${conditionId}|${outcomeIndex}` → { cashPnl, realizedPnl, isResolved }.
3. In the per-position economic accounting (STAGE 3b/4), use truePnl from this map instead of (cashFlow + netShares × Gamma price).
4. Keep the current Gamma path as a fallback or remove entirely.
5. Re-run with the same WATCHED_WALLETS as Phase 3 sprint to verify the result matches /positions reality.

**Acceptance:** Backtest verdict for the sprint shortlist `[0x24c8cf69, 0x5d05b1f5]` matches the /positions data direction: challenger > baseline by a wide margin.

**Source:** 2026-05-11 Branch 3 research sprint Phase 3 — full caveat documented in sprint findings doc.

---

## [Done] — 2026-05-11 — [PATS-Copy] Fix leaderboard fetcher DOM virtualisation cap

**Outcome (resolved same day):** Solved via the SSR API instead of fixing the DOM scrape. Discovered the underlying route pattern: `polymarket.com/_next/data/<buildId>/en/leaderboard/<category>/<window>/<sort>.json` — one fetch returns the React Query dehydrated state with all 3 sort variants (profit / volume / biggestWins) for that (category × window). For politics across 4 windows: **134 unique wallets** with rich metadata (rank, name, pseudonym, amount, pnl, volume, realized, unrealized) vs the v1 DOM scrape's 71. Replaces the Puppeteer + DOM virtualisation path entirely — no browser needed.

Implementation: `scripts/research/phase1a-v2-politics-leaderboard.ts`. Build ID discovered automatically from the leaderboard HTML (regex `build-[A-Za-z0-9_-]+`). Output: `_NEXT_STEPS/branch-3-phase1a-v2-politics.json`. Unlocked the diversified-shortlist verdict for Branch 3 (12 passers vs 1 — see 2026-05-11 Decision Log "Branch 3 verdict UPGRADED").

**What (original):** `scripts/research/phase1a-leaderboard-fetch.ts` (and by extension the production `src/leaderboard/scraper.ts` Puppeteer path) scrapes wallet addresses from the rendered DOM. React virtualised lists only render visible rows — so the scrape caps at 27-35 wallets per time window, not the full top-100. Fix the fetcher to either (a) programmatically scroll past the virtualisation buffer, or (b) intercept the lazy XHR the leaderboard frontend MUST be making for paginated rows (recon script `scripts/research/phase1-leaderboard-recon.ts` captured no obvious leaderboard XHR but a fresh deeper inspection might find it).

**Why:** Sprint Phase 1a only got 71 unique candidates across 3 windows. With proper top-100 across 3 windows the candidate pool would be 200-250 (after overlap dedup), giving Phase 2 v2 much more material to find diversified specialists. The current SWAP recommendation rests on 1 strong wallet + 1 tier-2 — exactly the concentration risk the sprint was meant to address.

**Estimate:** 2-3 hours. Scroll-to-load approach is simpler; XHR-intercept is cleaner.

**How to start:**
1. Re-run `scripts/research/phase1-leaderboard-recon.ts` with response-body capture enabled (currently captures URLs + first-200-chars previews — extend to full bodies > 1KB for the candidate URLs).
2. Look for any URL that returns >100 wallet addresses or a clearly paginated structure (`{results: [...], next: '...'}` or similar).
3. If no XHR is found, implement scroll-to-bottom-N-times in `phase1a-leaderboard-fetch.ts` (the existing scroll loop has maxScrolls=8 but the leaderboard may need 20+ to load row 100).

**Acceptance:** Each time window yields ≥80 wallets. Combined unique pool ≥200.

**Source:** 2026-05-11 Branch 3 research sprint Phase 1a observation.

---

## [Open] — 2026-05-11 — [PATS-Copy] Adopt `/positions` as first-class leader-evaluation signal

**What:** Polymarket's `data-api.polymarket.com/positions?user=<wallet>&limit=500` returns per-position `cashPnl + realizedPnl` for every position a wallet currently holds, including resolved-but-redeemable ones. This is the closest thing to ground-truth wallet edge measurement on Polymarket. Currently the bot's leader scoring (`src/leaderboard/scorer.ts`) uses composite of WR + profit factor + frequency + recency derived from leaderboard scrape data. /positions data is richer and more decisive.

**Why:** Both the 2026-05-11 baseline and the Phase 3 backtest re-run produced misleading verdicts because they relied on trade-derived or Gamma-derived position-state inference. The /positions endpoint resolves this directly. Should become part of the leader-eligibility flow, not just an ad-hoc research tool.

**Estimate:** 3-4 hours for an MVP integration. Cache /positions per wallet for 5-10 minutes, expose `getLeaderEdgeSummary(wallet)` returning `{ totalGeoPositions, resolvedWr, allTimeTruePnl, medianBet, lastTradeAge }`. Optionally fold into the composite score (would need tuning).

**How to start:**
1. Lift `fetchPositions` + `isGeopolitics` helpers from `scripts/research/phase2v2-screen-via-positions.ts` into a new `src/leaderboard/positions-evaluator.ts`.
2. Add a unit test pinning the helpers' output against a known fixture (capture the live response from `0x24c8cf69` into `tests/fixtures/positions-0x24c8cf69.json`).
3. Wire into the watcher promotion/demotion logic OR expose as a stand-alone CLI for ad-hoc audits.

**Acceptance:** A new wallet can be audited via `node-script-or-CLI <wallet>` returning the per-position edge summary in <2 seconds.

**Source:** 2026-05-11 Branch 3 research sprint — the /positions endpoint was the discovery that resolved the baseline ambiguity.

---

## [Open] — 2026-05-11 — [PATS-Copy] Branch 3 Tier-1 auto-promotion loop (Phase A → B → C)

**What:** Close the loop on the static Tier-1 geopolitics watchlist by making it self-maintaining. Today (post Branch 3 build, commit `eb56980`), the Tier-1 list is hardcoded in `src/geopolitics/watchlist.ts` and requires manual edit + redeploy to change. As new geopolitics specialists emerge on Polymarket, we need a system that (a) detects them, (b) decides whether to promote, (c) acts on the decision — with watchdog backstop monitoring runtime performance afterwards. Build staged across three phases, each with its own kill-switch verification gate.

**Why:** The static-list architecture has a real gap — nothing today is automatically surfacing "a new wallet appeared that passes our filters". Without a closing mechanism, the watchlist quietly drifts out of date as the trader population evolves. Manual re-screening depends on Sunil remembering to do it.

Doctrinally (per feedback memory `feedback_automate_when_rules_airtight.md`, 2026-05-11): if rules are airtight and Claude would recommend on rule-pass, automate the promotion. Manual gates that don't add signal are ceremony. The right architecture is rich-rules + auto-execute + watchdog backstop + safety rails (churn cap, watchlist snapshotting). NOT a permanent manual approval gate.

**Why staged (not all-at-once):** Building full auto-promote today means locking in rules based on one observed miss (`yyyy77777` Tier-2 case). Not enough observation to be confident. CTDD says: don't ship automation faster than observation supports.

**Scope (sequenced, each phase gated):**

### Phase A — Watchdog weekly diff alert (~1–2h, schedule: NEXT SESSION)
- Cron runs `scripts/research/phase1a-v2-politics-leaderboard.ts` + `phase2v3-screen-combined.ts` weekly
- Diffs result against current `TIER_1` in `src/geopolitics/watchlist.ts`
- Telegrams plain-English alert: new passers + existing Tier-1 underperformers
- Zero impact on the bot. Pure visibility.
- Each weekly diff is a test case for Phase B (would current rules promote this? would I override? why?)
- Verification gate: runs cleanly, alerts useful, no false-positive flood

### Phase B — Rule set v2 (~3h, schedule: WEEK 2 OF PAPER SOAK)
- Use Phase A diff data to identify rules currently missing
- Extract implicit human judgements into deterministic rules. Initial candidate set:
  - `truePnl > 0` (deal-breaker even at high WR — catches `yyyy77777`)
  - WR consistency: ≥55% in BOTH last-30d AND last-90d windows (catches lucky streaks)
  - Sample size: ≥30 positions (was ≥15 — too noisy)
  - Wallet age: ≥60 days (catches Sybils / brand-new accounts)
  - Cooling-off check: internal `geopolitics-cooling-off` list maintained when wallets pull stunts
  - Strategy-type sanity: flag wallets whose P&L is heavily from disputed-market UMA resolutions (different mechanism than directional prediction)
- Verification gate: enriched rule set, applied retroactively to Phase A diffs, correctly identifies wallets that would have been manually rejected

### Phase C — Auto-promote + churn cap + snapshotting (~3–4h, schedule: AFTER PAPER SOAK PASSES)
- Cron wraps Phase A+B into a single decision pipeline
- New passer found AND not in TIER_1 → auto-add (commit + push + watchdog alert)
- Existing Tier-1 fails rules → auto-remove
- Every change: snapshot `watchlist.ts` to date-stamped backup (`watchlist-snapshots/2026-XX-XX.ts`) for one-command revert
- **Churn cap:** if >2 changes pending in any cycle → PAUSE auto-action, alert with full diff, require manual `ack` to apply. Catches regime shifts where the whole landscape is moving.
- Watchdog rules running in parallel: per-wallet truePnl ≥ 0 rolling 30d, activity ≥1 trade/14d, alert on Tier-1 entry/exit events
- Verification gate: dry-run auto-promote against last 4 weeks of Phase A diffs → confirm it produces same decisions a manual reviewer would

**Estimate:** ~7–10h total spread across three sessions. Phase A blocks B (uses A's data). B blocks C (rules need to be enriched first). C blocks live activation (requires soak verdict to confirm Branch 3 itself works).

**Acceptance per phase:** see verification gates above. Final acceptance for full loop: 4-week trailing dry-run matches manual decisions ≥95% of cases, churn cap fires correctly on synthetic regime-shift test, snapshot-based revert verified working.

**Source:** 2026-05-11 — conversation about whether the Branch 3 static watchlist can incorporate new wallets. Sunil pushed back on Claude's default of "manual approval forever"; Claude's CTDD-honest concession produced the staged automation plan. Doctrine captured in `feedback_automate_when_rules_airtight.md`.

---

## [PATS-Copy] Branch 3 Geopolitics Specialist Research Sprint — 2026-05-11 (HISTORICAL — sprint definition)

**What:** Time-boxed 4-6h research sprint to validate whether geopolitics copy edge generalises beyond wallet `0x5d05b1f5` before committing to Branch 3 build. The 2026-05-11 backtest showed MIXED verdict — positive PnL but all 8 sample positions came from one wallet, which is a single point of failure for the entire pipeline economics. Build cannot start until verdict is in.

**Context:** Option D shipped 2026-05-11 (per-pipeline RiskManagers + Supabase pipeline col + capital pools), which unblocks Branch 3 architecturally. Branch 3 itself is the path back to March-level monthly profits (~$1k/mo from copy pipeline alone per 2026-05-10 forensic). But the backtest sample is too thin and concentrated to ship to paper mode without first knowing whether `0x5d05b1f5` is one specialist of many or the only one.

**Why this matters:** Building Branch 3 with the current 11-wallet list risks shipping a pipeline whose entire P&L depends on a single wallet's continued performance. If that wallet goes silent, changes strategy, or regresses, Branch 3 dies. Research cost (4-6h) is small relative to the cost of post-build discovery.

**Scope (Phase 1-3):**

1. **Phase 1 — Source candidates (1-2h):**
   - Polymarket leaderboard top 100 wallets (last 30d, 90d, all-time)
   - Cross-check current 11-wallet watch list — which ones were actually active in geopolitics markets in last 90d?
   - Optional: Dune Polymarket dashboards for geopolitics-tagged markets

2. **Phase 2 — Screening filter (1-2h):**
   - Hard filters: ≥15 geopolitics-market trades in last 90d, win rate ≥55%, avg trade size $10-$500, active in last 14 days
   - Output: ranked shortlist of 5-10 candidates

3. **Phase 3 — Backtest validation (1-2h):**
   - Re-run `~/Desktop/POLYMARKET_TRADING_3.0/scripts/backtest/branch3-geopolitics.ts` with new shortlist
   - Compare proportional vs flat sizing on the diversified sample

**Decision criteria (set in advance, no goalpost-shifting):**

- Diversified positive PnL → **BUILD** Branch 3 with new wallet pool, flat sizing v1
- `0x5d05b1f5` remains the only consistent specialist → small-cap test ($200) or **KILL** Branch 3
- Shortlist outperforms `0x5d05b1f5` → **SWAP** in stronger wallets, build with new list

**Deliverables:**

- Updated `scripts/backtest/branch3-geopolitics.ts` with researched wallet list
- Research findings doc at `~/Desktop/POLYMARKET_TRADING_3.0/_NEXT_STEPS/branch-3-research-<date>.md`
- Obsidian Decision Log entry with verdict + provenance
- This BACKLOG entry marked `[Done]` with outcome

**Acceptance:** Verdict locked in Decision Log. If BUILD: Branch 3 build spec scoped + ready for next-session implementation. If KILL: rationale documented + Branch 3 removed from forward sequencing. If SWAP: shortlist locked + backtest harness re-validated.

**Estimate:** 4-6 hours total, single session.

**Source:** 2026-05-11 conversation. User asked "maybe we should research alternative geopolitics specialists first?" — CTDD analysis confirmed research-first beats build-first on this evidence. Recovery context in `~/.claude/projects/-Users-sunil-rajput/memory/project_session_handoff_2026_05_11.md` and `~/Desktop/POLYMARKET_TRADING_3.0/_NEXT_STEPS/2026-05-11-master-handoff.md`.

---

## [Open] — 2026-05-12 — PATS-Copy: extend per-pipeline balance tracking to signal + copy executors

**What:** Today's Option D fix wired per-pipeline `poolBalance` tracking into `geopolitics-executor.ts` so its `RiskManager` drawdown breaker operates on the geopolitics pool only. The same wiring is still pending for `signal-executor.ts` and `copy-executor.ts` — both call `riskManager.checkTrade()` on their per-pipeline RM, but nothing updates that RM's balance after open/close. Result: signal/copy pipelines currently have NO active drawdown breaker (their RM balance is static, DD stays at 0%, gate is a no-op). The bot-wide breaker that previously fired on signal-pipeline losses was removed today to fix the pipeline isolation leak.

**Why:** Before flipping `PAPER_MODE=false` (live trading) on signal or copy, each pipeline needs its drawdown breaker actually wired. Right now those pipelines have per-trade max-loss caps (`MAX_LOSS_PCT_PER_TRADE`) and per-trade size caps, but no aggregate "stop trading if this pool draws down >14%" gate. Acceptable in paper mode (no real $ at risk); not acceptable for live.

**How:**

1. In `signal-executor.ts`:
   - Add `private poolBalance: number` initialized to the signal pipeline's capital pool (from `runner.ts` wiring).
   - On every successful `executePaper` / `executeLive` open: `this.poolBalance -= ourSize; this.riskManager.updateBalance(this.poolBalance);`
   - On every close (wherever signal closes — likely in lifecycle handler called from runner): `this.poolBalance += ourSize + pnl; this.riskManager.updateBalance(this.poolBalance);`
   - Same handling for rollback / stop-loss close paths.
2. Same pattern in `copy-executor.ts` (currently disabled but should still be wired for completeness).
3. Verify: simulate a losing streak in a backtest harness; confirm the per-pipeline DD breaker fires at 14% of pool (not 14% of bot-wide).
4. Optional cleanup: `paperEngine.syncState()` currently still updates the `'global'` RM's balance — that's correct (cash ledger) but ensure no remaining code path treats it as a gate. Remove the `riskCheck` call from `paperEngine.executeCopyTrade()` entirely if no per-pipeline RM ever expects it (per-pipeline RMs are now the sole gate).

**Acceptance:** All three pipelines (signal, copy, geopolitics) have working per-pipeline drawdown breakers verifiable via log signature `Drawdown circuit breaker [<pipeline>]`. No "global" or bot-wide DD gate fires from `executeCopyTrade`. Before any live deployment, simulate a 14% pipeline-pool loss and confirm the breaker engages.

**Estimate:** 1-2 hours.

**Hard gate:** Must land BEFORE `PAPER_MODE=false` flip on signal or copy.

**Source:** 2026-05-12 incident — geopolitics paper soak captured zero data for 10 hours because bot-wide DD breaker (signal-pipeline-driven) blocked every geopolitics trade. Fix landed today on geopolitics; same pattern needed elsewhere. See vault Decision Log 2026-05-12 + commit `950982e`.

---

## [Open] — 2026-05-13 — Build 4 gbrain-inspired patterns into HQ memory stack

**What:** Mine 4 transferable patterns from `garrytan/gbrain` (CTDD verdict 2026-05-13, see memory file `project_repo_eval_gbrain.md`) WITHOUT installing gbrain. Build them natively in HQ:

1. **Memory eval harness** (~3-5d) — ~50 hand-curated Q&A pairs from prior sessions + replay script firing each through claude-mem + `~/claude-hq/scripts/memory-probe.sh` + scoring. Produces single retrieval-accuracy % that goes up/down on memory-stack changes. **Build FIRST** — it's the measurement layer that turns #2 and #3 into real pilots instead of vibes (Lesson 20).
2. **Nightly "dream cycle" synthesis** (~2-3d) — bash + Claude Sonnet API script, cron-fired ~3am, reads day's claude-mem observations + new Decision Log entries + MemPalace drawers, writes single daily digest into `~/.claude/projects/-Users-sunil-rajput/memory/MEMORY.md` (or a dated digest file). Closes the gap: existing stack captures but doesn't synthesise.
3. **Per-message signal-detector** (~1-2d) — UserPromptSubmit hook fires async Haiku call extracting entities/topics/intent from every message into a signals log. Tighter than Lesson 21's per-task probe; non-blocking.
4. **MCP server trust boundary** (0d now / 1d when triggered) — `OperationContext.remote = true/false` pattern; tighten behaviour when called from MCP vs local CLI. Only applies once HQ ships its first first-party MCP server (none exist today). Park until that trigger fires.

**Context:** Gbrain itself is SKIP wholesale per memory file `project_repo_eval_gbrain.md` — capability overlaps 80%+ with claude-mem + MemPalace + Obsidian + graphify + recall-stack; bus factor 1 (91% AI-coauthored); 5 weeks old; postinstall hook bypasses Trust Gate per Lesson 6. But these 4 ideas fill real gaps the existing stack doesn't cover (synthesis, measurement, per-message capture, runtime trust).

**Why this matters:** Lesson 20 — pilots without deadline + signal + default action are vibes, not experiments. #1 (eval harness) IS the signal layer. Without it, #2 and #3 are vibes. Building #1 first turns the other patterns into measurable experiments.

**Sequencing:**
- Critical path: #1 (3-5d) → #2 (2-3d), measure #2 lift via #1
- Stream B parallel: #3 (1-2d) — independent of #1 and #2
- #4 deferred until first first-party MCP server exists

**Estimate:** ~7-10 focused working days. ~14-20 calendar days alongside POLYMARKET work + soak monitoring.

**Ongoing cost flag (CTDD):** #2 adds ~$0.10-0.30/night in Sonnet (~$3-9/month). #3 adds ~$0.001/prompt in Haiku (~$1-6/month at current usage). Small but recurring forever.

**Scope-creep risk:** #2 has unbounded growth potential ("also do citation fixing, also do conversation summarisation, also..."). Lock the prompt scope on day 1 — produce ONE daily digest only.

**How to start:**
1. Re-read memory file `project_repo_eval_gbrain.md` for full context
2. Build #1 first — eval harness. Curate 50 Q&A pairs from past Decision Log entries / Branch 3 research / handoff memories / PATS strategy audit. Build `~/claude-hq/scripts/memory-eval.sh` that fires each pair through claude-mem + memory-probe.sh and scores answers vs expected.
3. Establish baseline retrieval-accuracy %.
4. Build #2 (dream cycle) and #3 (signal-detector) in parallel.
5. Re-run #1 after each → confirm absolute pp lift.

**Acceptance:**
- #1 produces a single number (retrieval accuracy %); baseline established; harness re-runnable
- #2 emits daily digest at ~3am; first 7 days reviewed for usefulness; cost tracked in HQ Watchdog
- #3 captures signals on every UserPromptSubmit; first 1000 captures reviewed for signal:noise; threshold tuned
- #4 deferred to a follow-up BACKLOG entry triggered by first-party MCP server creation

**Pilot kill-or-keep deadline (Lesson 20):** 30 days after start of build.
- **Signal:** #1's accuracy % before vs after #2 + #3 land
- **Default action on deadline:** drop #2 and #3 if combined lift is <3pp absolute. Keep #1 regardless (the harness has independent value as ongoing regression catch).

**Source:** 2026-05-13 conversation — three-repo CTDD evaluation (gbrain, agentscope, agent-native). User asked which to integrate to make Claude HQ "the most powerful model it can be." CTDD answer: none wholesale; build gbrain's 4 patterns natively. Full context in memory files `project_repo_eval_gbrain.md`, `project_repo_eval_agentscope.md`, `project_repo_eval_agent_native.md`.

---

## [Open] — 2026-05-13 — Borrow AgentScope OTel + A2A patterns when next touching HQ Watchdog / cross-agent comms

**What:** Two pattern-borrows from `agentscope-ai/agentscope` (CTDD verdict 2026-05-13, see memory file `project_repo_eval_agentscope.md`). NOT install — pattern-only:

1. **OpenTelemetry observability shape** — when redesigning HQ Watchdog telemetry, look at AgentScope's OTel span schema BEFORE designing our own. Their pattern: every agent action emits structured spans (Jaeger / Honeycomb / Datadog-compatible).
2. **A2A (Agent-to-Agent) protocol awareness** — Google-led open standard for cross-ecosystem agent comms. Keep in mind for the day Sunil wants Claude HQ agents to talk to non-Claude agents (Qwen / OpenAI / Gemini). Forward-looking; no action today.

**Context:** AgentScope is institutionally robust (Alibaba Tongyi Lab, 2.5 yrs, 30+ human contributors, Apache 2.0, arXiv-backed, only 14% AI-coauthored) but **wrong shape** for HQ — it's a Python multi-agent framework that would replace Claude Code as our agent, not augment HQ orchestration. SKIP wholesale per memory file `project_repo_eval_agentscope.md`; track these 2 patterns only.

**Why deferred:** Neither pattern is blocking today. HQ Watchdog telemetry works (Lesson 16 enforces plain-English alerts). No cross-ecosystem agent comms needed. Pulling patterns now would be pre-emptive infrastructure debt (Lesson 20).

**Trigger conditions (when to revisit):**
- HQ Watchdog telemetry redesign starts → fetch the `agentscope/observability/` module via `gh api repos/agentscope-ai/agentscope/contents/src/agentscope/observability`, study span schema, then design ours
- First non-Claude-agent integration in any HQ project → read their A2A skill + tutorial at `https://doc.agentscope.io/tutorial/task_a2a.html` as reference implementation

**Estimate:** 0.5-1 day per pattern when triggered. Pure pattern-mine, not import.

**How to start (when triggered):** Fetch only the specific files needed via `gh api repos/agentscope-ai/agentscope/contents/<path>`. Do NOT clone whole repo. Do NOT pull the package (53 MB + 40+ transitive deps, owner not on HQ allowlist).

**Acceptance:** When the trigger fires, the relevant AgentScope file is read and the pattern is either adopted (with citation in Obsidian Decision Log) or explicitly rejected (with documented reason). Either way, this BACKLOG entry flips to `[Done]`.

**Source:** 2026-05-13 three-repo evaluation. Full context in memory file `project_repo_eval_agentscope.md`.

---

## [Open] — 2026-05-13 — Register agent-native as Get-Rich-Scheme framework candidate

**What:** Add `BuilderIO/agent-native` (CTDD verdict 2026-05-13, see memory file `project_repo_eval_agent_native.md`) to `~/claude-hq/registry.json` as a **candidate** framework for Get-Rich-Scheme SaaS-pipeline deliverables. Surfaces in Commander Step 2 registry scan when classifying Get-Rich-Scheme tasks; NOT a default; presented alongside other options.

**Status:** Registry entry added in same change as this BACKLOG entry (2026-05-13). `id: agent-native`, `priority: MEDIUM`, `status: candidate`. Pre-install gates remain pending until first actual use.

**Context:** agent-native is **wrong altitude for HQ brain integration** (it's a project-level framework, not orchestration) but DIRECTLY relevant to Get-Rich-Scheme Reddit→SaaS pipeline. Templates Mail / Calendar / Forms / Content / Analytics / Slides / Video / Clips match the shape of apps Get-Rich-Scheme is supposed to validate and launch. CTDD verdict captured in memory file `project_repo_eval_agent_native.md`.

**Why this matters:** When Get-Rich-Scheme Phase 0 starts, the question "what framework do we build the deliverable in?" should have a pre-evaluated answer with known trade-offs, not be re-researched from scratch. The trust signals (bus factor 1, license ambiguity, AI session debris) need to be remembered, not re-discovered.

**Pre-install gates (MANDATORY before any actual install for Get-Rich-Scheme use):**
1. Read `LICENSE` file directly — README claims MIT but GitHub metadata `license` field is null. CONFIRM MIT content.
2. Full Trust Gate Tier C review on first clone — owner BuilderIO/steve8708 NOT on HQ allowlist.
3. Pin commit hash — no formal version tag released yet (project is 2 months old). Don't track `main`.
4. Accept stack lock-in knowingly: Drizzle + Nitro + React + Remotion + Yjs + shadcn + Cloudflare Workers + partial BuilderIO commercial dependency.

**Estimate:**
- Registry entry add: 15 min (DONE in same commit as this entry)
- Pre-install gates when triggered: 1-2h
- Actual scaffold of first agent-native template: ~1d when needed

**How to start (when Get-Rich-Scheme Phase 0 triggers):**
1. Re-read memory file `project_repo_eval_agent_native.md` for full verdict and signals
2. Run the 4 pre-install gates above
3. Compare agent-native vs alternatives (build from scratch, use other SaaS starters, use no-code)
4. If selected: clone to `~/projects/get-rich-scheme/templates/` at a pinned commit hash, NOT `main`

**Acceptance:**
- Registry entry visible to Commander Step 2 scan (DONE 2026-05-13)
- When Get-Rich-Scheme triggers, agent-native surfaces as ONE candidate (not the only option)
- First actual use is gated by the 4 pre-install checks above passing
- This BACKLOG entry flips to `[Done]` when either (a) first actual use begins, or (b) explicit rejection in favour of another framework is documented

**Source:** 2026-05-13 three-repo evaluation. Full context in memory file `project_repo_eval_agent_native.md`.

---

## [Open] — 2026-05-14 — Moodboard generator: upgrade upload panel to IndexedDB persistence

**What:** Replace session-only (in-memory blob URL) storage for the "My uploads" panel in moodboard-generator with IndexedDB-backed persistence so that uploaded image pools survive page refresh, tab close, and browser restart.

**Why deferred:** Sunil is pressed for time on another project. Option A (session-only) ships now; Option B (IndexedDB) ships later when bandwidth allows. The "BACKLOG.md is canonical 'note for later'" rule applies (Lesson 18).

**Why it matters when triggered:** The whole point of dumping a curated image pool is to iterate over multiple sessions. Losing the pool on accidental refresh defeats the workflow. Folder drops of ~50 high-res photos (~100 MB) cannot fit in localStorage (~5-10 MB cap) — IndexedDB is the only viable browser-native option for this volume.

**Estimate:** ½ to 1 day of focused work.

**How to start (when triggered):**
1. Install `idb` (Jake Archibald's IndexedDB wrapper, ~1 KB MIT, present in moodboard worktree's allowlist by virtue of being mainstream).
2. Create `lib/upload-store.ts` (~100 lines) — schema `{ id: string, blob: Blob, mime: string, originalName: string, uploadedAt: number, vibeTags?: VibeTagPayload }` keyed by SHA-256 content hash.
3. Refactor the "My uploads" tab to read/write through `upload-store.ts` instead of the in-memory map currently shipped (post-Option-A).
4. Add `URL.createObjectURL` lifecycle management — revoke on unmount to prevent memory leaks (well-known footgun).
5. Add a "Clear uploads" affordance in the panel UI (housekeeping).
6. Handle `QuotaExceededError` gracefully (rare, but possible on massive volumes).
7. Migration: existing in-memory uploads from a live session are simply discarded on reload — no formal migration needed since Option A is session-only by design.

**Acceptance:**
- Drop 30+ images, refresh the page → panel still populated, thumbnails render.
- "Clear uploads" empties the panel and IndexedDB store cleanly.
- No memory leaks (verify via Chrome DevTools Memory tab — object URL count returns to zero after closing panel).
- Quota-exceeded path shows a plain-English error (Lesson 16), not a stack trace.
- BACKLOG entry flips to `[Done]`.

**Source:** 2026-05-14 moodboard v2 enhancement scoping. CTDD comparison surfaced Option A vs B; user opted for A now, B parked here for future integration.

---

## [Open] — 2026-05-28 — Investigate secret-shaped strings in Fleet Decision Log

**What:** Local secret scrubber halted on `JARVIS-BRAIN/Projects/ai-agent-fleet-ventures/04 Decision Log.md` — reports secret-shaped strings detected. Pre-existing as of today's run (not introduced by insta-notion-sync work).

**Why:** Per Lesson 14 doctrine, secrets shouldn't live in vault files. Either the strings are real (need scrubbing + rotation) or false positives (need allowlisting in the scrubber config). Vault git backup pushes to private GitHub repo `SUNMANOFFICIAL189/jarvis-brain` — if real, the impression is already on a remote.

**Estimate:** 15–30 min triage.

**How to start:**
1. Grep the file for the scrubber's known patterns: `grep -E 'AIza[A-Za-z0-9_-]{35}|sk-ant-|ghp_|sk-[A-Za-z0-9]{32,}|AKIA[0-9A-Z]{16}' "$VAULT_PATH/Projects/ai-agent-fleet-ventures/04 Decision Log.md"`
2. If real secrets: rotate at source, scrub the file, force-push the vault repo (rewrite history), and rotate the impression-exposed credentials per Lesson 14 procedure.
3. If false positives (regex literals being discussed in design docs): add the file to scrubber allowlist or wrap the literals in code fences with a known-FP marker.

**Acceptance:** Scrubber `vault: HALT` line no longer triggers for this file. BACKLOG entry flips to `[Done]`.

**Source:** 2026-05-28 insta-notion-sync build session — scrubber ran for key-rotation cleanup, flagged this as side-finding. Discovered, not caused.

---

## [Open] — 2026-05-28 — Trust Gate parser: substring-matches "pip install" anywhere in command

**What:** `scripts/trust-gate.sh` flags any bash command containing the literal string `pip install` regardless of where it appears — including inside `echo` strings and code comments. Two false positives hit during the insta-notion-sync build:
1. `echo "=== Installing project deps ===" ; pip install ...` → parsed `Installing` as a flag, `project` as author → BLOCK.
2. `pip install --upgrade pip` (the SDK self-upgrade convention) → parsed `--upgrade` as author → BLOCK.

**Why:** The hook should match `pip install` only as the *start of a command word* (i.e., the executable being run), not as a substring anywhere on the line. Today's behaviour produces noisy false positives that erode trust in the gate, leading to reflexive `HQ_TRUST_OVERRIDE=1` use — which defeats the whole point of the gate.

**Estimate:** 30–60 min. Same parser-class problem as Lesson 7 (`git clone` URL extraction) — needs proper tokenisation, not regex substring match.

**How to start:**
1. Reproduce: `bash -c 'echo "pip install foo" ; ls'` — should NOT trigger; today it does.
2. Refactor `parse_pip_install` in `trust-gate.sh` to:
   - Tokenise the full command with Python `shlex` (same pattern as `parse_git_clone_url` after the 2026-04-21 fix).
   - Walk tokens; require `pip` to be a command-position token (immediately after `;`, `&&`, `||`, `|`, or at the line start), followed by `install`.
   - Skip flags-with-values explicitly: `--upgrade`, `--user`, `--no-deps`, `--no-cache-dir`, `--target N`, `-r REQ`, `-c CONS`, `-e .`, etc.
3. Add a regression test: a fixture command with `echo "pip install foo"` followed by a real shell command should not block.
4. Mirror the fix for `npm install`, `pipx install`, `cargo install`, and any other "<tool> install <pkg>" parsers — same shape, same bug class.

**Acceptance:** All five reproduction cases pass (real installs of unknown-author packages still block; echo-string-containing-install-words no longer blocks).

**Source:** 2026-05-28 insta-notion-sync build. Lesson 7 already established the parser-discipline rule for `git clone`; this is the same fix applied to `pip install` and friends. Override used today: `HQ_TRUST_OVERRIDE=1` for google-genai, notion-client, python-dotenv — all canonical, trusted publishers, logged.

---

## [Open] — 2026-05-28 — PATS-Copy: wallet-watch.py daily rotation-alert TG ping

**What:** Extend `scripts/wallet-watch.py` with a post-snapshot rotation-alert mode. After the daily snapshot writes, apply LESSONS.md #25 6-gate to each watched wallet (currently 9: 1 TIER_1 StarMaster + 8 TIER_2). Emit plain-English TG alerts (per Lesson 16) when either condition fires:
1. **TIER_1 wallet fails any 6-gate** — immediate concern, surface for operator review (potential demotion/pool reduction).
2. **TIER_2 wallet passes ALL 6-gates for 4+ consecutive daily snapshots** — promotion candidate, surface for operator rotation decision.

**Why:** Phase 1.5 rotation (2026-05-28) made it operationally meaningful: now that we know wallets can be rotated cleanly, the bottleneck is detecting WHEN to rotate. The 6-gate is mechanical and already implemented in `cmd_compare`; just needs to fire daily off the snapshot output instead of requiring manual `compare` invocation. The "4+ consecutive days" threshold avoids whipsawing on single-snapshot variance.

**Estimate:** 30–60 min. Mostly composing existing `cmd_compare` gate logic into a `cmd_alert` mode + Telegram send + state tracking for "consecutive days passed" via a small JSON cursor file.

**How to start:**
1. Read `scripts/wallet-watch.py` `cmd_compare` (lines 350-410) — gate logic already exists.
2. Add `cmd_alert(snapshot_path)` that reads the snapshot, applies the 6 gates per wallet, compares to a state file at `logs/wallet-snapshots/.alert-state.json` for consecutive-days tracking.
3. For TIER_1 wallet failing any gate: TG fire immediately (no state needed).
4. For TIER_2 wallet passing all 6: increment its `consecutive_pass_days` counter; if ≥4, fire TG with promotion candidate framing; reset on first fail.
5. Update the `com.pats.wallet-watch` launchd plist to chain `python wallet-watch.py snapshot` followed by `python wallet-watch.py alert <newest-snapshot>`.
6. Plain-English template per Lesson 16: `what_happened` + `what_to_do` fields.

**Acceptance:**
- StarMaster's snapshot today (still passing) → no alert fires (he's the active TIER_1)
- A simulated TIER_1 fail (manually edit snapshot file) → fires TG alert with `what_to_do: "review wallet X in watchlist.ts, consider pool reduction or demotion"`
- A simulated 4-day TIER_2 pass streak → fires TG alert with `what_to_do: "consider promotion; first run Path B if not already built"`
- Launchd job runs daily 07:00 UTC, alert fires within minutes if conditions met

**Source:** 2026-05-28 Phase 1.5 rotation deploy. Operator explicitly asked for "keep track of other wallets simultaneously, to understand if another rotation needs to take place." Deferred to follow-on session per LESSON 27 (don't ship sloppy on tired attention after 12+ hour session).

---

## [Open] — 2026-05-28 — PATS-Copy: per-feed RSS circuit breaker in NewsScanner

**What:** Add per-feed exponential-backoff circuit breaker to `src/signals/news-scanner.ts`. After N consecutive failures on a feed (default N=5), disable that feed for an exponentially increasing cooldown period (15s → 60s → 5min → 30min → 1h, capped). Reset counter on successful fetch.

**Why:** DL News was removed today (2026-05-28) because its SSL cert is misconfigured server-side. Without a circuit breaker, the bot retried every 15 seconds indefinitely, producing 5,760 log lines/day of pure noise (which also burned CPU on doomed `fetch + AbortController` setup). A general circuit-breaker pattern would have:
1. Auto-stopped the doomed retries within 1-2 minutes of detection
2. Surfaced "feed X disabled after N failures" as a single TG alert (per Lesson 16) instead of buried log noise
3. Future-proofed against any other feed cert expiry / discontinuation

The next feed to die (statistically inevitable for 19 external sources) will repeat today's failure pattern unless this lands.

**Estimate:** 1–2h. Touches one file (`news-scanner.ts`); add `Map<feedName, {failCount, nextRetryAt, backoffMs}>`; `fetchRSS` checks `nextRetryAt > now` before attempting; catches increment `failCount` and double `backoffMs`. Plain-English TG alert on feed-disable per Lesson 16.

**How to start:**
1. Extend `RSSFeed` interface or add a parallel `feedState: Map<string, FeedState>` field on `NewsScanner`.
2. In `poll()`, filter feeds where `state.nextRetryAt > Date.now()`.
3. In the per-feed catch, increment counter + compute next retry via `Math.min(state.backoffMs * 2, 3_600_000)`.
4. After 5 consecutive failures, fire a single TG alert: `"Feed X disabled after 5 failures (cert/network/source issue). Will retry in Y minutes. Other 18 feeds unaffected."`.
5. On successful fetch, reset counter + backoff to default 15s.
6. Unit test the backoff math in isolation (pure function).

**Acceptance:**
- A test fixture feed that always throws → disabled after 5 attempts within 75 seconds.
- Real feeds with intermittent failures (1-2 in a row, then success) → backoff stays at default.
- TG alert fires exactly ONCE per disable event, not on every subsequent failed poll.
- Re-enabled feed (caught up) → resumes normal polling.

**Source:** 2026-05-28 DL News removal. Operator explicitly asked for the immediate fix (remove DL News); the general fix pattern (per-feed circuit breaker) is the structural answer that prevents the next occurrence. Lesson 7/24-class problem: a minimum-diff fix today protects against one specific failure; the architectural fix protects against the failure class.

---

## [Done] — 2026-06-05 — /capture skill (frictionless capture inbox)

**What:** Built `/capture` skill — frictionless dump → never-lose (append to `captures/INBOX.md`) → auto-categorize (TASK/IDEA/REFERENCE/NOTE/EVENT) → route to HQ homes (BACKLOG / memory / Obsidian) → archive-never-delete. Stolen from the Obsidian Personal OS eval (`project_eval_obsidian_personal_os.md`), adapted to HQ's existing homes (not the doc's 8-folder vault). Canonical in `skills/capture/`, symlinked to `~/.claude/skills/capture`, on main + feature branch.

**Why:** HQ had no frictionless capture→auto-file flow — only manual BACKLOG edits. This was the strongest gap surfaced by the eval; completes the `/sync` + `/save` + `/capture` persistence family.

---

## [Open] — 2026-06-05 — Scheduled morning briefing + weekly review digests

**What:** Stand up two scheduled digests (from the Obsidian Personal OS eval): a brief morning "most important action + open loops + project status" and a Sunday weekly review (what progressed/stalled + next-week priorities). Reuse the deferred weekly routing-digest spec (MODEL_ROUTING §8) + watchdog/telegram.py; deliver via `/schedule` or a LaunchAgent. PlainAlert/Lesson-16 compliant.

**Why:** HQ has the data (cost ledger, watchdog, project state) but no proactive daily/weekly surfacing. Overlaps the already-deferred "weekly Telegram routing digest" BACKLOG item — consider merging. Low-cost, high-visibility.

**Estimate:** ~3-4 hours (generator + schedule + dry-run + jargon-lint). Pairs with the existing weekly-digest backlog item.

**How to start:** Decide channel (Telegram vs chat vs file). Write the generator reading cost-ledger + watchdog state + active project handoffs. Schedule it. Dry-run before enabling.

**Acceptance:** A morning + weekly digest fire on schedule, plain-English, no jargon, accurate against disk state.

---

## [Open] — 2026-06-05 — Personal-life vault layer (separate from dev projects)

**What:** Evaluate building a dedicated personal-life knowledge/management layer (health, finances, relationships, career, personal admin) modelled on the Obsidian Personal OS doc — distinct from HQ's dev/project memory. Would organize currently-scattered personal projects (Malaysia residency, property hunt, FlightClub planning) under one life-OS taxonomy with capture + digests.

**Why:** HQ is project/dev-centric; personal-life items live as loose memory files. The doc is a good blueprint for THIS specific gap. Bigger scope — a separate session. Only worth it if the operator wants life-management inside the system.

**Estimate:** ~1 session to scope + scaffold the vault layer; ongoing to populate.

**How to start:** Decide if in scope at all. If yes: scaffold a `Life/` area in the Obsidian vault with fixed folders, a single life `CLAUDE.md` SoT, wire `/capture` + `/save` + digests to it. Do NOT rebuild HQ's dev memory stack.

**Acceptance:** Decision logged. If built: a life-OS layer exists, capture/save/digests work against it, personal projects migrated in.

---

## [Open] — 2026-06-06 — PATS-Copy: upsertLeaders bulk upsert ON CONFLICT dup-key error

**What:** `upsertLeaders` (`src/data/supabase.ts`) periodically logs `"upsertLeaders bulk upsert failed (20 rows): ON CONFLICT DO UPDATE command cannot affect row a second time"`. Pre-existing since the May 28 bulk-upsert refactor (commit `188e288`). Non-fatal — the catch handles it — but it means some scoring updates are silently dropped each time it fires.

**Why:** Postgres' `ON CONFLICT DO UPDATE` semantics: if two rows in the same `INSERT` batch share the conflict-target value (here, `wallet_address`), Postgres refuses to update the same row twice in one statement. The bulk batch must have a duplicate. Most likely cause: the leaderboard scorer is returning the same wallet under two different ranks/categories in one rescore, OR there's case-sensitivity mismatch (we lowercase before insert but the original dataset has both cases).

**Estimate:** 30-60 min. Deduplicate the input array by `wallet_address.toLowerCase()` BEFORE the upsert, picking the highest-`composite_score` row when duplicates exist.

**How to start:**
1. Reproduce by adding logging: `console.log(leaders.map(l => l.walletAddress.toLowerCase()).filter((x, i, a) => a.indexOf(x) !== i))` before the bulk upsert — see what's duplicate.
2. Fix in `diffLeaders` or in the upsertLeaders call site: dedup by lowercase address before passing to `.upsert([...])`.
3. Add a unit test in `scripts/test-leader-diff.ts` covering the dedup case.

**Acceptance:** error log line stops appearing. All unique leaders still updated correctly.

**Source:** 2026-06-06 Fix A deploy — error visible in post-deploy log scan. Surfaced, not caused.

---

## [Done] — 2026-06-08 — PATS-Copy: wallet-watch.py scaling-artifact filter for tiny positions

**Resolved:** schema 1.7 shipped at PATS-Copy commit `c81438c`. Added `MIN_POSITION_SIZE_FOR_SCALED = $50` filter to wallet-watch.py — positions with leader `initialValue < $50` are excluded from `scaled_dollar_pnls` computation.

Trigger: 2026-06-08 health check surfaced StarMaster's `worst_scaled_trade = -$1,499`. Investigation showed her actual position was $3 on a 2026 Peruvian presidential candidate that lost $97; the $50-scaling formula multiplied by $50/$3 = 16.7x produces the scary number. Pure math artifact, no real exposure.

Verified: pre-filter StarMaster 6-gate failed 2/6 gates (Z=+0.46σ, worst=-$1,499); post-filter all 6 gates pass (Z=+2.15σ, worst=-$112). 24 tiny positions correctly excluded. Schema bumped 1.6 → 1.7, new diagnostic field `scaled_excluded_tiny_n`.

---

## [Done] — 2026-06-08 — PATS-Copy: Fix B signal-log JSONL for rejected-signal visibility

**Resolved:** shipped at PATS-Copy commit `c81438c`. New file `/opt/polymarket-bot/data/signal-log.jsonl` (env-overridable via `SIGNAL_LOG_FILE`). Append-only, one JSON object per line. Records EVERY geopolitics `execute()` attempt with `disposition` (executed | blocked) + `reason` + leader/market/side/price/size/our_trade_id.

Closes the visibility gap exposed by the "blocked=25" STATUS counter that had no per-rejection detail. Read with `tail -50 .../signal-log.jsonl | jq .`. Fire-and-forget; diagnostic channel never breaks trading path.

Scope: geopolitics pipeline only (Phase 1). Signal pipeline visibility deferred. File will be created on first geopolitics signal attempt post-deploy.

---

## [Parked] — 2026-06-10 — Refresh expired Codex API key (cross-vendor review + /codex:rescue)

**What:** The Codex CLI key is invalid (HTTP 401, `sk-proj-…xh0A`). While dead, the cross-vendor lens in `/adversarial-review` and the `/codex:rescue` delegation path are non-functional (intra-vendor reviews only).

**Action when unparked:** refresh the OpenAI API key (operator task — key paste/login), then verify `codex exec -s read-only "ping"` returns a result.

**Parked by operator 2026-06-10** ("I won't be doing this yet"). No urgency; surfaced during the harness-audit adversarial-review (project_ecc_harness_eval_2026_06_10).

---

## [Open] — 2026-06-10 — Secret-scrubber v2: deferred non-critical hardening

Scrubber `scripts/lib/secret-scrub-incremental.py` is v2.1 (all CRITICALs C1-C5 + new MED-3 fail-open fixed; Stripe/JWT added; blind-reviewed). Deferred fast-follows (none merge-blocking, none a leak risk today):

1. **HIGH-1 (deep): AWS *secret* access key heuristic** — 40-char base64 with no prefix; add a proximity-bounded pattern (near `aws`/`secret` keyword) to limit false positives. Only matters if AWS secret keys are ever pasted into notes.
2. **HIGH-2: scan-time vs SessionEnd budget** — `scrub_vault` scans the full diff-vs-origin set (~6003 files now, inflated by the halted-backup backlog). Fails CLOSED (silent no-push) if killed. Mitigations: scan the actual `git add -A` push-diff, raise the hook timeout, commit-aggressively, or add a loud slow-scan warning. Re-measure AFTER the vault clears its unpushed backlog — likely self-mitigates.
3. **MED-2: `*.db`/`*.sqlite`-in-vault guard** — push-safety currently relies on "no DB tracked in vault." Add an assert that refuses the push if a DB appears in the push set.
4. **LOW-2: mask the mempalace 80-char secret preview** in `.secret-scrub.log` (already gitignored+untracked, so local-hygiene only).

**Source:** 2026-06-10 blind /adversarial-review of scrubber v2 (project_ecc_harness_eval_2026_06_10).

---

## [Open] — 2026-06-10 — Scrubber v2.1 proof-check LOW/MED (non-blocking, cleared to merge)

From /proof-check pre-merge inspection (no CRITICAL/HIGH):
1. **MED — JWT over-redaction audit:** `eyJ…` JWT pattern over-redacts on the rare benign `eyJ`-prefixed dotted string (near-zero real rate, SAFE fail direction). Optional: log JWT redaction previews like claude-mem already does, so an accidental over-redact is auditable.
2. **LOW — null-byte heuristic:** a file with a real secret AND a NUL byte in its first 8 KB is skipped (pre-existing; unrealistic for markdown notes).
3. **LOW — installer mktemp guard:** `install-design-skills.sh:47` — if `mktemp` fails under `set +e`, `STAGING=""` (benign, non-destructive; near-impossible).

---

## [Open] — 2026-06-10 — proof-gate SEC_RX: anchor `payment` (LOW, non-blocking)

From the re-/proof-check of proof-gate.sh v2 (CLEAR TO MERGE): `payments-readme.md` flags via the unanchored `payment` token in SEC_RX. Harmless over-flag (extra proof-check on a doc); anchor it like `auth`/`token`/`guard` were if it gets noisy.

## 2026-06-10 — FC33 5a.3 proof-check residual (LOW)
- Reconcile/curation POST bodies carry client PII over HTTPS (token in header, no logging today — SAFE as-written). **Watch when adding any frontend logging/telemetry middleware**: do not log POST bodies for `/reconcile` or `/curate`. Source: adversarial-review of curation UI, finding #8.

## 2026-06-10 — FC33 vision: learning/template system (counterpart-validated → AI accelerator → graduated auto-gen)
**Operator vision:** capture every counterpart-validated client plan → AI learns recurring patterns → builds templates → eventually generates the playbook/guide itself for "seen enough" situations, shrinking counterparts to paperwork-execution + doc-supply.
**CTDD verdict (Class 4): SPLIT.**
- ✅ APPROVED — build as a DRAFTING ACCELERATOR: validated-case corpus + similarity retrieval (pgvector, already planned) → AI proposes a precedent-grounded baseline → expert REVIEWS/CONFIRMS not analyses-from-scratch. Most of the time-saving, safely.
- ⚠️ REWRITE the "without counterpart experts" end-state — NOT a blanket switch-off (worst case: unsigned AI tax plan reaches client + is wrong = the product's core promise breaks; pattern-match ≠ correctness: one fact flips outcome, law goes stale, automation bias). Safe form = operator's OWN doctrine [[feedback_automate_when_rules_airtight]]: auto-gen ONLY per-pattern, promoted by evidence (expert signs off AI draft ~unchanged across N cases), with a freshness check (law change → retire template) + a novelty gate (unusual client → back to human). Expert shifts author→validator; load shrinks to edge cases.
**Foundation already being laid:** the 5a AI-baseline-vs-counterpart-final cross-check diff = the labelled training signal. RECORD each diff with provenance (expert, date, law/snapshot version, sources, client fact-pattern) — that's the dataset this needs. Prereqs: case volume + pgvector validated-case store + staleness invalidation + confidence/novelty gating. Build AFTER the counterpart pipeline (5b) is live and producing validated cases.

---
## 2026-06-11 — FLIGHTCLUB.33-WEBAPP-v2 Phase 5b Inc 2: doc_requests reminder audit-consistency (LOW)
**Source:** adversarial-review of Inc 2 (doc_requests + reminder scheduler), Finding 3. Fresh-Claude-agent review (Codex blocked, OpenAI 401).
**Finding (LOW):** `db.bump_reminder()` / `db.mark_doc_escalated()` run an UPDATE without a rowcount check. If a `doc_requests` row were deleted (e.g. case ON DELETE CASCADE) between `outstanding_doc_requests()` reading it and the bump, the audit log would record `doc_reminder_sent` for a row that no longer exists — an audit-trail inconsistency. NOT a safety issue: the reminder cap can't be exceeded (a gone row is never re-selected), no PII exposure, no data loss.
**REJECTED fix:** the reviewer's suggested `raise ValueError on rowcount==0` is rejected — it would make `run_reminders` CRASH-HALT on a concurrently-deleted row, violating the "skip-not-crash / never take the whole scheduler down" contract. Worse than the symptom.
**Safe fix (if/when addressed):** make `bump_reminder` return the rowcount and have `run_reminders` only emit the `doc_reminder_sent` audit when a row was actually updated (skip the audit on 0 rows). Cosmetic; defer until the scheduler is wired to a real cron trigger (Inc 3+).

## 2026-06-11 — FC33 5b Inc2 reminder scheduler: concurrency guard (LOW, trigger-gated)
- `reminders.run_reminders()` has no lock; two concurrent invocations could each read the same outstanding set and double-send. SAFE under the current design (single cron tick; Inc 2 isn't wired to any trigger yet). **Trigger to fix:** when Inc 3 wires an HTTP/cron trigger for the scheduler, add a guard (advisory lock / single-flight / `SELECT … FOR UPDATE SKIP LOCKED`). Source: adversarial-review of Inc 2 (finding #3, downgraded HIGH→LOW after verification — single-flight assumption holds today).
- Residual accepted: email send is non-transactional → at-least-once on a crash between send and the (now batched, all-or-nothing) state write. Safe direction for a reminder/escalation; not exactly-once and shouldn't be (email can't be).

---
## 2026-06-11 — FLIGHTCLUB.33-WEBAPP-v2 Phase 5b Inc 3: proof-check follow-ups (MED + LOW)
**Source:** adversarial-review of Inc 3 (operator packet UI). Fresh-Claude-agent (Codex blocked, OpenAI 401). Proof-check PASSED (no CRITICAL/HIGH).
- **MED (partially addressed):** `/api/operator/reminders/run` is GLOBAL (all outstanding cases) but the button lives in the per-case PacketsSection. Inline fix shipped = honest relabel ("Run reminders (all cases)" + clarifying note + tooltip). DEFERRED option: add optional `?case_id=` to scope a run to one case (needs `outstanding_doc_requests(case_id=...)` filter), and/or move the control to a top-level Scheduler section once the real cron trigger lands at deploy. main.py `operator_run_reminders` + reminders.py `run_reminders`.
- **LOW (code smell):** `backend/app/specialist_routing.py:171-173` folds case `email` into `answers["email"]`, but `email` is in NO `_SET_*_FIELDS` list, so it's never routed into a packet → no leak today. Fragility: if a future dev adds `"email"` to a field list, the leak becomes invisible. Fix when next touching that file: drop the email fold (keep only name→fullName) or rename to make "not routed" explicit. NOT fixed now — specialist_routing.py is frozen Inc-1 proof-checked code; don't churn it for a LOW.

## 2026-06-11 — FC33 5b Inc3 + Inc4-shell adversarial-review findings (3× MEDIUM, no CRITICAL/HIGH)
Reviewed: committed Inc 3 (operator packet UI, mailer.compose_packet_email PII→specialist) + UNCOMMITTED Inc 4 client shell (token-gated /api/client/{token}/... endpoints). Contract SOLID: PII egress minimised (the split) + internal-placeholder recipients + LogMailer default; operator endpoints all require_operator; client endpoints IDOR-safe (case_id scoped IN SQL), token=secrets.token_urlsafe(16) 128-bit, ZERO file bytes (route takes no body — Phase-3 gate holds), no enumeration, no status-downgrade, minimised client view. Findings:
- **[Inc3, MED] send-packets re-blasts the specialist email on every click** (seed is idempotent, email send is not). Draft/LogMailer-safe today; in real-send mode = duplicate specialist emails. Fix: gate the send on first-dispatch (a packets_sent flag) or make "Re-send" explicit. `main.py operator_send_packets`.
- **[Inc4-shell, MED] intake_token travels in the URL** (path/query) → leaks via server logs / referrer / history. Documented MVP (magic-link deferred). **Trigger: MUST harden before real-client go-live** — magic-link (signed, expiring) or token in header/POST body + don't-log + short TTL. Ties to the delivery/Phase-3 security gate.
- **[Inc4-shell, MED] no rate-limiting on /api/client/{token}/...** — defense-in-depth (token is strong + IDOR-safe, so low today). **Trigger: add before client-facing go-live** (per-token request cap).
NOTE: Inc 4 client shell is UNCOMMITTED/in-progress; the client-facing-access design decision (intake-token-as-credential) the handoff flagged "confirm first" is being made — operator to confirm intent + the go-live hardening above.

---
## 2026-06-11 — FLIGHTCLUB.33-WEBAPP-v2 Phase 5b Inc 4: client upload shell — deploy hardening (deferred)
**Source:** adversarial-review of Inc 4 (client document upload shell). Fresh-Claude-agent (Codex 401). Proof-check PASSED, zero CRITICAL/HIGH — all 8 client-surface security properties verified (ownership/no-bytes/non-enumeration/minimization/no-token-leak/atomic/no-XSS/no-injection).
**Deferred (ship with the magic-link delivery-phase work, NOT now):**
- Token-in-URL tradeoff (operator-approved MVP = reuse per-case intake_token as the client credential). Upgrade = signed, EXPIRING magic-link emailed to the client (token not returned in any response). Concrete interim mitigation when /documents goes near production: set `Referrer-Policy: no-referrer` on the /documents page (or globally) so the URL token can't leak via the Referrer header to external links.
- intake_token column is nullable but unreachable via the client surface (`_case_id_for_token` rejects empty/None before the query; create_case_from_application always generates a token). No action needed; noted for completeness.

---
## 2026-06-11 — flightclub33.com www↔apex canonical redirect (PARKED, optional)
**Source:** session re-pointing the custom domain to flightclub33-v3-demo. Operator chose to park.
Both `www.flightclub33.com` and apex `flightclub33.com` currently serve the Cloud Run app **independently** (both mapped to flightclub33-v3-demo). No error for visitors. Optional polish = pick ONE canonical host and 301-redirect the other. Value: (1) avoids Google "duplicate content" splitting SEO across www/non-www; (2) uniform address. **Why deferred:** minor, not a fix; on Cloud Run it's fiddly (redirect must live in app code via Host-header check or an extra layer, not a console toggle). **Trigger to revisit:** when organic-search/SEO becomes a priority for the members-club site. Wiring details in memory `reference_flightclub33_domain_mapping`.

---

## [Done 2026-07-12] — 2026-06-14 — model-router.py: tier_for_model() docstring omits 'fable'

**Closed:** docstring fixed as part of the FABLE_METERED / FABLE-OK sentinel change (Fable metering transition build, 2026-07-12).

**What:** `scripts/lib/model-router.py` — `tier_for_model()` docstring says "Extract tier (haiku/sonnet/opus)…" but the function also returns `"fable"`. Update the docstring to list fable.

**Why:** Cosmetic accuracy. Surfaced by the 2026-06-14 Fable-disable adversarial review (LOW-2). Pre-existing since the 2026-06-10 Fable addition — NOT introduced by the disable change, so left out of that focused edit to avoid scope creep.

**Estimate:** 2 minutes.

**How to start:** Edit the one-line docstring; no behaviour change.

**Acceptance:** Docstring matches the function's actual return set.

---

## [Open] — 2026-06-14 — Codex OpenAI API key invalid (401) — cross-vendor review lens down

**What:** The Codex CLI reports "logged in via API key" but a real `codex exec` call fails with `401 Unauthorized — Incorrect API key provided` (key fragment redacted) against `https://api.openai.com/v1/responses`. The cross-vendor (Codex) lens of `/adversarial-review` is therefore currently UNAVAILABLE — reviews fall back to fresh-Claude-agent only (intra-vendor).

**Why:** Cross-vendor independence is the gold standard for the proof gate (different model than the one that wrote the code). A dead key silently degrades every adversarial review to single-vendor. Per LESSON 14 spirit, a 401 can also mean a revoked/leaked key — worth checking, not ignoring.

**Estimate:** 10–20 minutes.

**How to start:**
1. Confirm the stored key: `codex login status` vs the key OpenAI actually expects (platform.openai.com/account/api-keys). Check for API billing enabled (ChatGPT Plus ≠ API access).
2. Refresh the key into wherever Codex reads it (per LESSONS 14–15, prefer Keychain + launcher, never plaintext).
3. Re-verify: `codex exec -s read-only -C ~/claude-hq "echo ok"` returns a real response.

**Acceptance:** `codex exec` completes a read-only review without a 401; adversarial-review cross-vendor lens restored.

---

## [Open] — 2026-06-14 — proof-gate SEC_RX `vault` token false-positives on every vault save

**What:** `scripts/proof-gate.sh` SEC_RX (line 34) includes the bare token `vault`. Because the Obsidian vault lives under `~/Vaults/…`, the PostToolUse hook flags EVERY edit to any vault file (Decision Log, Hub, etc.) as "security-critical," which then BLOCKS the next `git push`/`merge` until `/proof-check` re-runs or `PROOF_OK=1` is set in the hook env. Net effect: a routine Decision Log save (e.g. during `/save`) blocks the code push even when the actual code was already proof-checked.

**Why:** Recurring friction + a "boy who cried wolf" risk — operators learn to reflex-clear the gate, eroding the gate's value for genuine security-critical changes. The intent of `vault` was presumably a secrets-vault path/file, not the Obsidian knowledge vault. (This is likely the "SEC_RX improvement noted" from the 2026-06-13 session.)

**Estimate:** 20–30 min (change + the change itself needs a `/proof-check`, since proof-gate.sh is on its own SEC_RX list).

**How to start:**
1. Anchor the token like the auth/token/guard ones already are, e.g. `(^|[/._-])vault([/._-]|$)` AND/OR exclude the known Obsidian vault root (`~/Vaults/`) from the PostToolUse path match.
2. Confirm a Decision Log edit no longer populates `~/.claude/.proof-needed`, while a real secrets-vault path still does.
3. `/proof-check` the proof-gate.sh change (it gates itself), then commit.

**Acceptance:** Editing a file under `~/Vaults/` does not flag the proof-gate; editing `secret`/`.env`/`model-router`/etc. still does. A `/save` no longer needs a `PROOF_OK`/flag-clear just for the Decision Log.

---

## [Open] — 2026-06-25 — insta-notion-sync: bound the AITransient retry path

**What:** In `~/projects/insta-notion-sync`, transient AI-tagging failures (`AITransient`, incl. the new unparseable-JSON case) are handled by `reset_to_unprocessed()` (processor.py `_process_one`, via the `AIQuotaExceeded` alias) which has NO retry counter — unlike `retry_old_failures` which caps `failed` rows at `[retry 3]`. A row that *persistently* looks transient (e.g. `claude -p` returns unparseable JSON for it every single time, or the CLI is down for hours) is reset to `unprocessed` and re-attempted every cycle indefinitely.

**Why:** Low impact (no data loss, doesn't block other rows — they still process after it within the 25/cycle loop), but it wastes ~30–60s/cycle on a pathological row forever. Surfaced by the 2026-06-25 proof-check adversarial review (the one MEDIUM that stood after the video-leak finding was fixed same-session). The strengthened tagging prompt made unparseable-JSON rare (3/3 clean in testing), so this is tail-risk hardening, not urgent.

**Estimate:** 30–45 min (needs care: `reset_to_unprocessed` is shared with the quota path where unbounded retry is INTENTIONAL — must distinguish "wait for quota/throttle to clear" from "this row never parses").

**How to start:**
1. Add a bounded-transient counter (mirror the `[retry N]` pattern in the Error field) for the unparseable-JSON / non-quota transient cases; after N (e.g. 5) → `mark_failed` so `retry_old_failures` then governs it.
2. Keep quota/rate-limit transients unbounded (correct — they clear on their own).
3. Verify a row that always fails to parse eventually lands in `failed`, while a quota'd row still retries until quota resets.

**Acceptance:** A deterministically-unparseable row stops being re-attempted after a bounded number of cycles; a genuinely-transient (quota/throttle) row still recovers without a cap.

---

## [Open] — 2026-06-25 — session-end.sh Layer 6: Path string-interpolation breaks on quoted repo paths

**What:** The graphify re-export block in `~/.claude/hooks/session-end.sh` (Layer 6) builds its Python `-c` program by shell-interpolating `'$PROJECT_DIR'` / `'$OBSIDIAN_VAULT'` / `'$PROJECT_NAME'` into single-quoted Python string literals. A single quote in any of those paths produces a Python SyntaxError at compile time — which the 2026-06-25 logging fix (follow-up #1) cannot catch (the try/except runs after compile), so the re-export silently fails for that edge case, defeating the fix's purpose.

**Why:** Surfaced by `/proof-check` (adversarial review) 2026-06-25 as the lone MEDIUM on the graphify work. Pre-existing pattern across the whole Layer 6 + 6.5 blocks — NOT introduced by the 2026-06-25 edit. Near-zero real risk today (operator path `/Users/sunil_rajput/claude-hq` has no quotes), but a latent silent-failure trap worth tidying next time the hook is touched.

**Estimate:** 20-30 min.

**How to start:**
1. In session-end.sh Layer 6, pass PROJECT_DIR/OBSIDIAN_VAULT/PROJECT_NAME to the Python via the environment, read with `os.environ[...]` inside the `-c` program.
2. Replace each `'$VAR/...'` literal with `Path(os.environ['VAR']) / '...'`.
3. Test with a temp repo path containing a single quote.

**Acceptance:** A repo whose path contains a single quote re-exports without a Python syntax error, and any genuine failure is recorded in `graphify-out/graphify-export-errors.log`.

---

## [Open] — 2026-06-27 — Build the transcript watchdog: catch recommendations surfaced without ctdd-precheck (the "won't-fire" enforcer)

**TRIGGER MET 2026-07-05 (instance #3 of the class):** the BidFill Spike-2 placement verdict was self-certified GREEN with a safety gate that existed only in prose and a headline number not reconstructable from the raw data; caught ONLY by an operator-requested adversarial review (after 2026-05-28 / LESSON 27 and 2026-06-26 / LESSON 28). Per LESSON 27.10's own default action, the deferred status has met its build condition. Awaiting operator scheduling decision; do NOT rush a fail-open scanner (original deferral rationale still applies to the BUILD QUALITY, no longer to the decision to build). Interim mitigation in place: phase-gate dual review standing order (feedback_phase_gate_dual_review_fable memory + BidFill MISSION_BOARD).

**What:** An after-the-fact transcript scanner (Stop hook or periodic sweep over `~/.claude/projects/*/` transcripts) that flags any case where a recommendation was surfaced to the operator WITHOUT a preceding `CTDD-PRECHECK[...]` verdict block (and, now that Step 0 exists, without the Step-0 grounding artifacts). This is the "Layer 3" enforcement referenced in LESSON 27.10 and is the ONLY mechanism that guarantees the grounding + recommendation discipline fires even when I forget to invoke the gate. Doctrine (Lesson 28) + the hardened Step-0 gate (shipped 2026-06-27) reduce the skip rate; only this watchdog catches the *skip itself*.

**Why:** 2026-06-26 — an 8-agent ~500k-token analysis re-derived an already-PLANNED fix because grounding was skipped/shallow (see Lesson 28). ctdd-precheck is mandatory but SELF-invoked; both the 2026-05-28 and 2026-06-26 incidents happened WITH the mandatory gate nominally in place, because a self-invoked gate depends on the assistant remembering and not self-certifying shallow artifacts. A separate "groundwork" skill was designed, adversarially reviewed, and REJECTED 2026-06-27 (would rot like the `/rpi-*` commands; renames rather than prevents the fake-compliance failure). The fresh-agent review's verdict: the only real fix for "won't fire" is this transcript watchdog. **Deferred (not built now) per operator decision 2026-06-27 (option b: ship the rule + hardened gate now, watchdog as its own reviewed build)** — because the detection is genuinely hard (a "recommendation" is free assistant text with NO clean PreToolUse signal) and a rushed fail-open watchdog becomes the exact FALSE-ASSURANCE trap the proof-gate.sh holes already demonstrated.

**Estimate:** ~half-day build + MANDATORY adversarial-review / proof-check before it is trusted + a short tuning soak (the free-text "is this a recommendation?" detector will need iteration to avoid both false flags and misses). Do NOT ship it fail-open.

**How to start:**
1. Detection surface: there is NO PreToolUse signal for "about to surface a recommendation" (it's assistant text), so this is an AFTER-THE-FACT transcript scan (Stop hook or periodic scanner), NOT a blocking PreToolUse hook.
2. Heuristic v1: detect recommendation-shaped assistant turns ("I recommend", "we should", option menus, change/ship/close/expand verbs) NOT preceded in the same turn-window by a `CTDD-PRECHECK[...]` block. Start permissive; measure false-positive rate before alerting.
3. Plain-English alert via existing `watchdog/telegram.py` PlainAlert (Lesson 16); an undetectable case is LOGGED for review, never silently passed as clean.
4. Adversarial-review the watchdog against the proof-gate.sh fail-open lessons BEFORE trusting it.
5. Track its own adoption signal (Lesson 20): does it catch real skips without crying wolf?

**Acceptance:** A deliberately-planted "recommendation without a preceding ctdd-precheck verdict" in a test transcript is flagged; a properly-gated recommendation is NOT flagged; the false-positive rate is low enough to act on; it has passed an adversarial-review for fail-open holes. Cross-ref: LESSON 27.10, LESSON 28, ctdd-precheck Step 0.

---

## [Open] — 2026-06-28 — PATS fidelity proof-check leftovers (M1 + 2 LOW; non-blocking)

From the Tier-1 fidelity adversarial proof-check (memory `project_pats_fidelity_proofcheck_2026_06_28`). All deferred, none block the Tier-1 deploy.

- **M1 (MEDIUM) — legacy geo row mis-charged a fee on close.** `src/core/paper-trading.ts:403-406` `pipelineFromRow` maps a hydrated Supabase row with a null/missing `pipeline` column + a non-`signal-bot` leader to `'copy'`, so a LEGACY geopolitics row (written before the `pipeline` column existed) hydrates as `copy` and is charged a Polymarket taker fee on close that a real geo trade must never pay (geo is fee-free). Current geo writes set `pipeline='geopolitics'` (geopolitics-executor.ts:491/532), so only pre-migration rows bite. **Fix:** also derive geo from the leader wallet (Tier-1 specialist watchlist) in `pipelineFromRow`, or treat unknown-pipeline non-signal rows conservatively.
- **L1 (LOW) — non-atomic JSON writes.** `src/core/map-persistence.ts:22,49` use `writeFileSync` (truncate-in-place), so a crash mid-write truncates the file. Mitigated: load is non-fatal on corrupt JSON (returns empty) and the state self-heals (cooldown/consensus windows repopulate). **Fix:** temp-file + rename for durability.
- **L2 (LOW) — `recentlyClosedMarkets` grows unbounded.** `src/execution/signal-executor.ts` set is pruned only on load; now that 3.3 persists it, the file grows with every market ever closed. Negligible at current scale. **Fix:** prune-before-persist.
- **Also noted (already tracked, Tier-2):** unrealized (mark-to-market) drawdown blind spot in the equity breaker is PRE-EXISTING (old cash breaker had it too); the 30% stop-loss + 50% deep-drawdown backstop are the MTM net. Equity-based `max_drawdown` now surfaces to the dashboard (supabase.ts:291) — lower/more honest, display-only. Capital-partition overlap ($7050 > $6300) warn→throw is the existing Tier-2 (e) item.

---

## [Open] — 2026-06-29 — proof-gate hardening (from the cross-project block incident)

The bare-'vault' SEC_RX false-positive was FIXED 2026-06-29 (commit bb5de44 — anchored 'vault' so Obsidian /Vaults/ docs stop flagging). Two follow-ups remain, intentionally NOT rushed into a security gate:

- **Per-repo scoping (P1).** The push-block is GLOBAL: a non-empty `~/.claude/.proof-needed` blocks EVERY project's pushes, even when the flagged files belong to a different repo (stale PATS entries blocked a FlightClub push 2026-06-29 — collateral; the flagged file is not even in the other repo's changeset). Make the block check whether a flagged file belongs to the pushing repo (record repo root per entry; only block same-repo). CAUTION: narrowing a security gate must not open a bypass — adversarially review + proof-check before shipping.
- **Flag hygiene / auto-clear (P1).** Entries linger because work cleared via `adversarial-review` does NOT wipe the note (only `/proof-check` does). Either have `adversarial-review` clear its reviewed entries on a clean pass, or add an age-based prune + a "reviewed" wipe. Interim rule: when a SEC_RX file is flagged, clear via `/proof-check` (wipes on a clean pass), not bare `adversarial-review`.

Provenance: 2026-06-29 — stale PATS entries (risk-manager.ts proof-checked clean + 2 Obsidian docs false-positive) cross-blocked an unrelated FlightClub push. Memory: `project_session_handoff_2026_06_29`.

---
## 2026-06-29 — FLIGHTCLUB.33-WEBAPP-v2 Inc 5 proof-check follow-up (LOW)
**Source:** adversarial-review of Inc 5 (Phase-3 secure storage). Fresh-Claude-agent (Codex 401). Proof-check PASSED — zero CRITICAL/HIGH/MEDIUM; all 10 security contract clauses verified solid.
**LOW (data-integrity, not security):** client-claimed `content_type`/`size` at `upload-complete` can differ from what was minted/PUT (both must still be allowlisted; bucket bytes are content-type-bound by the signed PUT; key is scoped to the client's own case/request → no cross-case leak, no traversal). DB stores the client's claim as advisory metadata. **Fix when convenient (NOT blocking):** in `client_upload_complete`/`attach_object_for_token`, reconcile the claimed content_type/size against the upload-url's minted values (or, at go-live, read the object's true size/content-type back from GCS after the PUT). Files: backend/app/main.py (upload-complete), backend/app/db.py (attach_object_for_token).

---

## [Open] — 2026-07-04 — /handoff skill proof-check deferrals (2 items; non-blocking)

From the wide adversarial proof-check of the new `/handoff` skill build (this session). CRITICAL C1 (secret-gate NUL fail-open) and HIGH H1 (constitution → AMBIGUOUS locator) were FIXED + re-verified inline; M1/M2/L1/L3 also fixed. These two remain, deferred:

- **M3 (MEDIUM) — multi-line / header-stripped secrets are undetectable by the line-based gate.** `~/.claude/skills/handoff/scripts/secret-gate.sh` HIGH patterns are single-line ERE, so a JWT wrapped over several lines, a PEM body pasted WITHOUT its `-----BEGIN…-----` header, or a bare high-entropy base64 blob will pass "clean". Mitigations already in place: NUL files are refused outright (fail-closed), and the skill + gate header forbid pasting multi-line credential blobs (env-var NAMES only). **Fix when convenient:** add a base64/high-entropy run heuristic (warn on any line with a ≥40-char high-entropy base64 run) to catch header-stripped key material. Non-blocking because the doctrine already bans multi-line secret pastes.
- **L2 (LOW) — pre-existing: session hooks' `curl` to Hindsight has no timeout → can hang session start/end.** `~/.claude/hooks/session-start.sh` + `session-end.sh` call `curl -sf "$HINDSIGHT_URL/…"` with no `--connect-timeout`/`--max-time`. Default `localhost:8888` refused → instant (fine), but an env-overridden or black-holed host makes curl wait the full default timeout, blocking the interactive session — which the hook contract says must never hang. Pre-existing (not introduced by the /handoff work). **Fix:** add `--connect-timeout 2 --max-time 4` to both curls.

Provenance: 2026-07-04 — proof-check of the /handoff build. Plan: `~/.claude/plans/wild-churning-thunder.md`.

---

## [Open] — 2026-07-06 — BidFill Phase 1 deferred items (from the output phase gate)

From the Phase-1 (data + auth) output gate (ctdd-precheck + 3 Fable-5 lenses). CRITICAL/HIGH findings were FIXED + tested this session (bid_jobs forged-`profile_id` exfil → `create_bid_job` RPC; rate-limiter IP spoof; open-redirect; attribution-500; unbounded-PII list; two TOCTOU races; PUBLIC execute grants; secrets-in-repo; CI fail-open). These non-blocking items are deferred to their natural phases:

- **Live Google OAuth + Resend SMTP (before real users).** Magic-link is verified via the Supabase admin API (generateLink+verifyOtp), NOT a real email round-trip; Google OAuth provider is unconfigured. Configure Google Cloud OAuth creds in Supabase + wire Resend as custom SMTP, then add the B9 attribution test + an identity-linking test (magic-link then Google, same email → one users_profile).
- **pg_cron heartbeat (do BEFORE leaving the dev DB idle).** Supabase free project pauses after 7 idle days; add a pg_cron ping or scheduled health hit. `docs/SUPABASE_CONFIG.md` notes it.
- **Expired-PDF purge cron (Phase 2).** Soft-delete + 7-day TTL exist; hard-delete of versions + R2 objects after grace is unbuilt (Phase 2, R2). `rate_limits` table also needs a periodic purge.
- **teams.max_seats client-writable (Phase 4).** An owner can set max_seats to any value; accept_team_invite then enforces a cap the client wrote. Lock at team-creation in Phase 4 (Office monetization).
- **stripe_events dedupe + credit-ledger tables (Phase 4).** Additive Phase-4 migrations (webhook idempotency by event.id; Top-Up/Founder Fill-Bank as a credit ledger, not a subscription row).
- **Account-deletion / email-change / invite-send flows.** Schema decisions landed (restrict/set-null, accept_team_invite); user-facing flows are Phase 3/5.
- **Test rigor: two-connection versioning-concurrency test.** The row-lock SQL is correct (verified by reading); the Promise.all test rarely overlaps in-DB, so it proves "no collision this run", not serialization. Add a `pg` two-open-transaction test.
- **middleware.ts → proxy.ts re-check.** Next 16 deprecates middleware.ts for proxy.ts, but OpenNext Cloudflare does not run proxy.ts (opennextjs-cloudflare#962). We use middleware.ts (CI-guarded). Re-check at any Next upgrade / when #962 closes.

From the final `/proof-check` of the fixes (2026-07-06, all fail-closed/latent, none blocking):
- **accept_team_invite email match is case-sensitive (latent).** `team_invites.email` is stored as the owner typed it; GoTrue lowercases `auth.users.email`, so an invite for `Bob@Acme.com` would permanently reject the legit invitee. Latent (no invite-creation UI yet). Fix when the invite flow lands: `lower(btrim(...))` compare, or normalize at insert.
- **Anon RLS tests pass via the error path, not "0 rows".** After the anon revokes, an anon query on a policy that calls `get_my_team_id()` errors (permission denied) instead of returning empty; the tests assert `data ?? []` so they pass either way. Fix (test rigor): assert `error` is null (or explicitly expect 42501) in the anon cases so they prove what they claim.
- **create_bid_job validates profile_id but not source_object_key (Phase 2).** Not a regression (no upload surface exists yet). When the R2 upload layout lands, enforce a per-tenant key prefix (`p_source_object_key like uid || '/%'`) inside the RPC so a client can't point a job at another tenant's uploaded PDF.

Provenance: 2026-07-06 — BidFill Phase 1 output gate + final /proof-check. Repo `~/projects/bidfill`; detail in its `MISSION_BOARD.md` checkpoint 2026-07-06 + `HANDOFF.md`.

## 2026-07-07 — BidFill Phase-2 task 2.5 deferrals (from the Fable-5 gate)
- **below_rule (label-above-blank) needs a blank-OWNERSHIP model before it can auto-ink.** A 2.5 attempt with a "closest-label" guard was reverted: the 3-lens Fable-5 gate reproduced 3 e2e wrong-ink holes (multi-column rows merge into one Line → neighbour's blank claimed; owner label left of the rule / `By: ___` signature underline invisible; real underscore blank skipped as ignorable). Root cause: the resolver has no column model, so "nearest ROW above" ≠ "the LABEL that OWNS the rule". Dedicated task: build column/ownership segmentation (recommended safe restriction: fire ONLY for a standalone-label row + same-row-owner rejection + label-token-span overlap + occupied-nearest hard-stop), each guard with a fails-without-it test, then re-gate. Spec = the 3 lens outputs + scratchpad phase2_4_engine_gate_findings.md. below_rule stays review-only until then.
- **Rotation: /Rotate=180 is a safe, cheap recovery win left on the table.** 90/270 break the resolver (transpose), but 180 keeps text horizontal so the resolver works; needs the visual→media position transform (x'=W−x, y'=H−y) + glyphs drawn rotated 180° + tests. 90/270 need orientation normalization ahead of the WHOLE pipeline (transfer_rotation_to_content broke pdfplumber extraction — needs a different normalizer).
- **DB-layer profile schema hygiene:** `create_profile`/`create_profile_version` RPCs accept raw jsonb with no schema check, so a direct PostgREST caller could store keys past the app-layer zod strip. Not a fill-engine safety hole (no worker code consumes an entity discriminator), but tighten if/when a `business_structure` enum is added, or the entity-section resolver could later read a smuggled key.
- **Inherited /Rotate test coverage:** rotated-page tests use page-level `page.rotate()`; add a fixture with tree-inherited /Rotate to pin `rotated_pages` against a pypdf upgrade (mechanism verified sound per pypdf 6.14.2 source).
- **OPERATOR DECISION (BidFill):** to auto-fill mutually-exclusive entity sections ("If a corporation…/If a partnership…"), the profile schema needs a `business_structure` enum (corporation/partnership/sole_prop/llc/joint_venture) — a web-app change (schema + onboarding wizard). Until then exclusive sections correctly demote to review.

## 2026-07-09 — HUES strategy deck image polish (from adversarial-review, LOW/MED deferred)
Deck: /Volumes/Elements/My_Stuff/OFFLIMITS/_CLIENTS/HUES/deck/hues-deck.html
- [ ] Cover-right meta ("Prepared by Offlimits · 2026") low-contrast (~0.73 lum) — no scrim in .titletake .box. Consider subtle bottom scrim or crop nudge.
- [ ] P7a `p7a-field.avif` is the only AVIF in an otherwise JPG/PNG deck — re-encode to JPG for non-Chromium export robustness.
- [ ] Cover `cover-hero.jpg` is 4.17 MB (4000×6000) shown ≤1880px — downscale to ~2000px wide.
- [ ] P4 `p4-audience.jpg` low-res (474×594, ~1.48× upscale) — swap for ≥1000px source if available.
- [ ] Stale HTML comments still say "placeholder/to be supplied" (hues-deck.html ~L37,102-103,338-339,367) — doc drift, tidy when convenient.

---

## [Parked] — 2026-07-10 — PATS (Polymarket bot) — parked; superseded by QUANTUM

**What:** PATS-Copy (the Polymarket copy/geo/StarMaster trading bot) is formally PARKED as of 2026-07-10, by operator decision during QUANTUM Phase-0 scope-lock. No PATS *code* is imported into QUANTUM; only its *lessons* carry over (encoded as QUANTUM design requirements: fills-only accounting, no fabricated exits, isolated per-strategy pools, honest gates). This entry is the single durable record of the park.

**Why:** Verified across multiple deep dives (verdicts 2026-06-28 and 2026-07-03): the headline dashboard P&L was a **fabricated-exit-price artifact**; honest realized performance is **lifetime-negative**; there is **no validated edge**; bot is **paper-only, $0 real capital**. QUANTUM's explicit purpose is to STOP serial-edge-chasing (Master Plan risk #6), which forces an explicit disposition on every open trading effort rather than leaving them to accrete. Parking (not closing) keeps the artifacts recoverable without keeping it as an active drain on attention.

**State at park:** paper-only, $0 real; nothing running (no processes/daemons for it in this context); code LIVE @74b8bc3; signal idle, copy disabled; geo/StarMaster were the only live traders. Rectification plan + resume anchor already exist.

**Revisit trigger (any one):** (a) QUANTUM's honest test rig proves out — i.e. a strategy clears the ETF benchmark in the Phase-3 tournament and the operator wants to reconsider a Polymarket strand; OR (b) trading capital ≥ £25k; OR (c) a materially new, *verified* edge hypothesis specific to Polymarket/prediction-markets appears (routed through QUANTUM's hypothesis registry + Lesson-25 battery, never resurrected on vibes).

**How to resume:** read memory `project_pats_rectification_handoff.md` (RESUME ANCHOR) → plan `~/.claude/plans/joyful-singing-dusk.md`. Do NOT restart trading without re-running the ctdd-precheck + the no-edge verdict review first.

**Provenance:** 2026-07-10 — operator decision (AskUserQuestion: "Park with revisit date") during QUANTUM Phase-0 scope-lock. Cross-ref: `~/projects/trading/MISSION_BOARD.md` (P0.7), QUANTUM Master Plan finding M7 (PATS disposition gate).

## 2026-07-11 — Content-engine proof-check findings (MED/LOW; HIGH handled separately)
Source: /proof-check on the strategy re-grade (v1.1/v1.2) + BUILD_TIMELINE.md. HIGH (RESEARCH_FINDINGS.md:109,154 unflagged fabrications) surfaced to operator, NOT filed here (gate-blocking).
- [MED] Kill criterion unfalsifiable: P5 "beat the manual baseline" but no manual baseline was measured. Capture time-to-deliverable + client-acceptance rate BEFORE P3, else the kill gate can't fire.
- [MED] Re-grade over-stamp: Buffer numbers (+109% carousel / +36% Reels reach / +21% reply lift) carry [verified 2026-07-11] but rest on a single Lane-8 subagent read; refutation pass died on spend limit. Re-fetch Buffer on limit reset OR soften stamp to [single-source, unrefuted].
- [MED] Brand-system lock (HUES redesign, operator-owned, still pending) is the TRUE critical path for P3 but plan lists it only as a dependency. Promote to an explicit dated P2-parallel milestone.
- [LOW] Cross-file inconsistency: TikTok "70% completion" flagged in manuscript §5 but stated plainly in STRATEGY_FINDINGS §3.2 + §1.2.
- [LOW] CONTENT_CRAFT.md:34 + repurposing-orchestrator SKILL.md:50,68 use "30-90s" as craft/format guidance (now permitted) — add a one-line note so it's not mistaken for the discredited ranking claim.
- [LOW] 8-week timeline has zero slack buffer; any operator-input slip cascades to the September date.
- [LOW] "£0 until P2" framing omits that the build consumes Claude quota (limit already hit this session).

---

## [Open] — 2026-07-12 — trust-gate-post.sh: post-clone scan misses clones with explicit destination paths

**What:** `PostToolUse` scanner logged `post-scan: could not locate cloned dir (cwd=..., cmd=... git clone ... ~/claude-hq/repos/ponytail)` for BOTH evaluation clones on 2026-07-12 — Magika + secret-scan were silently SKIPPED. The dir-locator only handles `git clone <url>` into cwd (derives dir from repo name); it fails on an explicit destination arg and on `~` expansion.

**Why:** Defence-in-depth gap: any clone with a destination path (the standard HQ pattern — `~/claude-hq/repos/<name>`) gets NO automatic post-scan. The 2026-07-12 evals ran the scans manually, but ambient Tier B should not depend on remembering.

**Estimate:** 30–60 minutes (tokenise the command with the same shlex parser trust-gate.sh already uses — Lesson 7 — take the last non-flag arg as destination, expand `~`, fall back to repo-name-in-cwd).

**How to start:** `~/claude-hq/scripts/trust-gate-post.sh` — find the dir-location logic; reuse `parse_git_clone_url`'s tokeniser; add a test with an explicit-dest clone.

**Acceptance:** A `git clone <url> ~/claude-hq/repos/x` command triggers an automatic Magika + secret-scan of `~/claude-hq/repos/x`, visible in `.trust-gate.log`.

---

## [Open] — 2026-07-12 — Fable metering review follow-ups (5 MEDIUM + 8 LOW from the proof-gate)

**What:** The 2026-07-12 adversarial review of the Fable-metering build passed CRITICAL/HIGH to the operator (fix-before-ship) and filed the rest here. Full detail with file:line in `docs/reviews/adversarial-review-2026-07-12-fable-metering.md`. MEDIUM: M1 real-deny stderr banner never says DENIED; M2 protected-universe gaps (ANTHROPIC_MODEL/--model/project-settings session model uncovered by the session-start warn; inheritance blind spot; MCP/Bash sessions) — document as accepted-uncovered + add hq-foreman rail; M3 fable-spend.sh day-boundary over-count (`WHERE datetime(ts) >= …` fix verified); M4 MODEL_ROUTING header/§1/§3/§4 still say "automatic enforcement"/stale §4 "preserved"; M5 state plainly that the sentinel is an intent signal, not verified consent. LOW: L1 spend-estimate understates big briefs + noisy empty-ledger errors; L2 gpt-fable over-block + banner/JSON mismatch; L3 COMMANDER SSOT pointers + stale opusplan tip; L4 model-router.sh "never blocks" comment; L5 retry-table "top tier" ambiguity; L6 space-form /route refs; L7 route-fable allowed-tools brittleness; L8 own-verifier vs /proof-check guidance line.

**Why:** LOW/MEDIUM per /proof-check triage — do not block proceeding, must not be lost.

**Estimate:** 1-2 hours batched.

**How to start:** Work through the review doc's M/L sections; most are one-line doc/wording fixes; M3 is a verified one-word SQL fix.

**Acceptance:** Each M/L item either fixed (with file:line) or explicitly accepted-uncovered in MODEL_ROUTING.md; review doc annotated.

---

## [Open] — 2026-07-12 — Fable deny-gate residual LOWs (from the re-review, defense-in-depth)

**What:** The 2026-07-12 re-review of the hardened deny gate confirmed all fixes hold and cleared the gate; these three LOWs are accepted-as-documented, none reachable via model-controlled tool_input: (1) nonce single-use is TOCTOU — `nonce_already_used` reads then `consume_nonce` appends with no lock; two concurrent identical-nonce dispatches could both pass (bounded to a deliberate simultaneous double-dispatch of ONE nonce). (2) the C1 fail-closed backstop checks sentinel PRESENCE only, not reuse, and doesn't consume on the crash-allow path (a forced crash with a reused-but-present nonce would fall through to allow) — crash vector is non-model-controllable (`cwd`). (3) nonce-store read-error fails OPEN for the reuse sub-check only (the core no-sentinel deny still fails closed) — store path not model-controllable. Also: `docs/reviews/...:22` proposes a space-form `FABLE-OK <nonce>` where the shipped form is colon `FABLE-OK:<nonce>` (historical review artifact, non-authoritative).

**Why:** Hardening completeness, not active risk. The unforgeable nonce FORMAT is the primary defence; these are secondary layers.

**Estimate:** 30–45 min if ever prioritised (file-lock or atomic O_APPEND+dedup for the race; add reuse-check to the backstop).

**Acceptance:** Concurrent identical-nonce double-dispatch cannot double-spend; backstop denies a reused nonce on crash.

---

## [Open] — 2026-07-12 — /sync STEP 8: reconcile global COMMAND symlinks, not just skills

**What:** Global slash-commands are surfaced via manual symlinks in `~/.claude/commands/` → `~/claude-hq/commands/*` (scout, skill-audit, and now route-fable/route-preview/route-table). The `/sync` skill STEP 8 reconciles `~/claude-hq/skills/*` → `~/.claude/skills/` but does NOT touch commands, so on a fresh-machine re-clone the command symlinks need manual recreation. Not a regression (consistent with how scout/skill-audit have always been) — a durability nicety surfaced by the 2026-07-12 route-* globalization adversarial review.

**Why:** Reproducibility — the live wiring should be recreatable by `/sync`, not hand-made.

**Estimate:** 20 min — mirror STEP 8's skill loop for `~/claude-hq/commands/*` → `~/.claude/commands/<name>` (non-destructive: create if missing, report non-symlink conflicts, never delete orphans).

**Acceptance:** Running `/sync` in claude-hq recreates any missing `~/.claude/commands/route-*` (+ scout/skill-audit) symlinks and reports conflicts without deleting anything.

---

## [Open] — 2026-07-13 — insta-notion-sync: retry `[retry N]` counter is clobbered → cap is soft

**What:** In `~/projects/insta-notion-sync`, `mark_failed()` (src/notion_client.py:322) overwrites the Error field on every failure, wiping the `[retry N]` suffix that `retry_old_failures()` parses to enforce `max_retries=3`. So the retry cap never triggers — failed rows retry indefinitely after each cooldown. Surfaced by the 2026-07-13 adversarial review (secondary to the HIGH stranded-rows fix, which was shipped: retry now falls back to last_edited_time). Accepted for now because rows only reach `failed` for transient reasons (permanent cases — photo/unavailable/too-long/private — already `mark_skipped`), so uncapped retry of a transient failure is desirable, not harmful; only a genuinely-permanent non-auth error (e.g. an operator-saved malformed URL) would churn ~1 no-network call/hour.

**Why:** Bounded correctness — the cap exists for a reason; churn on a permanently-bad row is wasteful even if cheap.

**Estimate:** 30 min — make `mark_failed` preserve an existing `[retry N]` from the row's current Error (one extra read), OR track attempts in a dedicated field/property instead of parsing the Error text.

**How to start:** src/notion_client.py `mark_failed` (:322) + `retry_old_failures` (:104). Decide: preserve-suffix vs dedicated attempts column.

**Acceptance:** A row that fails N times is not reset once N ≥ max_retries; verified by a small unit test with synthetic page dicts (no live Notion needed if the counter logic is extracted).

---

## [Open] — 2026-07-13 — Compact the auto-memory MEMORY.md index (approaching read limit)

**What:** `~/.claude/projects/-Users-sunil-rajput/memory/MEMORY.md` is ~20.6KB, approaching the 24.4KB read limit (hook warns at ~17.1KB target). ~70 one-line pointer entries. Needs a deliberate compaction pass: keep one short hook per entry, ensure all detail lives in the topic files (not the index), and merge/drop genuinely superseded entries (e.g. multiple PATS health-check/handoff notes could collapse to the latest + an archive pointer; repo-eval entries that reached a terminal verdict could shorten).

**Why:** Once MEMORY.md exceeds the read limit, session-start memory recall degrades (the index is the always-loaded tier). But dropping/merging entries is lossy and needs care — must not silently lose a pointer the operator still relies on, so it should be done deliberately with operator awareness, not reactively by a hook mid-task.

**Estimate:** 45–60 min — read the index, cluster entries by project, for each cluster confirm the topic file holds the detail, then trim the index line to a one-line hook; propose any merges/drops to the operator before deleting.

**How to start:** `wc -c MEMORY.md`; group by project prefix; identify superseded sets (PATS handoffs, session-handoff dates, closed repo-evals). Trim in place; NEVER delete a topic file, only shorten/merge its index pointer.

**Acceptance:** MEMORY.md < 17.1KB, every remaining entry is a single hook line with detail in its topic file, and no project lost its pointer (operator signed off on any merges/drops).

---

## [Closed 2026-07-19] — 2026-07-13 — OFFLIMITS INTEL ENGINE: open design items to resolve at EP9/EP11 kickoff

**Closure:** all four items resolved in `_METHOD/ENGINE/design/EP9_11_INTEL_ENGINE.md` (T0, commit ea2b1d3) and exercised through the full EP9-11 build; pilot COMPLETE 2026-07-19 (9 framework grafts, Gap 8 closed, OFFLIMITS @53a7c0f).

**What:** Four design items recorded by the pre-approval adversarial review of the INTEL ENGINE extension block (`/Volumes/Elements/My_Stuff/OFFLIMITS/_METHOD/ENGINE/BUILD_PLAN.md`, "EXTENSION BLOCK: INTEL ENGINE"): (1) graft-routing map — claim-type → target doctrine surface → consumer, and verify EP4's read-set covers every graft surface once EP4 exists (a graft to a file its consumer does not read is a silent no-op); (2) quarantine read-guard — machine-readable DO-NOT-SURFACE header + lint on `_METHOD/INTEL/` entries, or home the quarantine outside the doctrine tree (verified: no consumer globs `_METHOD/` today; convention is the only guard); (3) EP10 must call the existing competitor-teardown §3.1 hook-classification path, not reimplement it; (4) retention policy for named-practitioner verbatim transcripts/dossiers. Context: intel engine is designed + sequenced post-EP8 (operator decision 2026-07-13), nothing built yet.

**Why:** These were MEDIUM/LOW findings from the gated design review; not blocking the doc-only step, but each becomes load-bearing the moment EP9-EP11 build. Filing here so they cannot silently vanish between now and EP9 kickoff.

**Estimate:** Resolved as part of EP9/EP11 kickoff design tickets (each is a bounded design decision, ~30-60 min inside those tickets, not standalone work).

**How to start:** At EP9 kickoff, read the extension block's "Open items" list + the gate record in `~/.claude/plans/tidy-sprouting-frog.md`; fold each item into the corresponding EP9/EP10/EP11 ticket's MUST-DO.

**Acceptance:** Each of the four items is either implemented or explicitly decided-against in the EP9/EP11 ticket evidence; none remains unaddressed when EP11's promotion gate goes live.

---

## [Open] — 2026-07-13 — OFFLIMITS EP3 scoring gate: two deferred design items

**What:** (1) Newsletter/relationship-platform scoring (EP3 design OQ-9): v1 machine-scores only the 4 IG formats; newsletter assets route to human review, explicitly labelled UNSCORED. Build a lightweight text-only voice+objective check when a real client ships newsletters (PG pilot is IG+IG, unaffected). (2) Carousel slide-to-caption coherence via DeepEval's image-coherence metric (OQ-10): v1 uses critic judgment (£0); DeepEval adoption needs Trust Gate Tier-C first. Design: `_METHOD/ENGINE/design/EP3_SCORING_GATE.md` §10.

**Why:** Both are real capability gaps deferred deliberately (cost-first, pilot-scope); filing so they resurface when a client's platform mix or carousel volume makes them load-bearing.

**Estimate:** (1) ~1 day inside a later EP3 iteration; (2) Trust Gate review + integration, ~1 day.

**How to start:** Read EP3_SCORING_GATE.md OQ-9/OQ-10 + the rubric templates; for (2) run /scout + Trust Gate on DeepEval first.

**Acceptance:** (1) newsletter assets get a machine pre-check before human review; (2) C3 scored with tool-assist or explicitly decided-against.

---

## [Open] — 2026-07-13 — OFFLIMITS EP5: JSONL append ledgers not tmp+rename atomic (LOW)

**What:** `_METHOD/ENGINE/production/cogs.py:113` (append_ledger_row), `review_queue.py:34` (_append), `runner.py:121` (_write_unresolved_refusal) use plain `open(path,"a")`+write, unlike the manifest/asset writers which use tmp+os.replace. A hard crash mid-write-syscall could leave a torn final JSONL line; the next `read_ledger`/`read` raises JSONDecodeError = fail-CLOSED (blocks that client until fixed), not fail-open. Flagged by the EP5+voice blind review (2026-07-13) as acceptable-but-hardenable.

**Why:** The COGS ledger is the money-audit record; a torn line blocks the client. Single-process/single-threaded appends are atomic under normal op, so real-world risk is low, but an fsync + skip-malformed-line-on-read pass would harden the money ledger specifically.

**Estimate:** 30-45 min — add fsync after the ledger append; on read, skip+warn a trailing malformed line rather than raising.

**How to start:** cogs.py append_ledger_row + read_ledger; decide fsync vs tmp+rename-per-append (tmp+rename loses append efficiency; fsync is the lighter fix).

**Acceptance:** a simulated torn final line in COGS_LEDGER.jsonl is skipped-with-warning on read, not fatal; append fsyncs.

---

## [Open] — 2026-07-14 — OFFLIMITS content engine: TIER-2 build-audit findings (1 HIGH must-fix-before-LIVE + 2 MED + 4 LOW)

**Source:** the 2026-07-14 BUILD AUDIT Tier-2 adversarial review (fresh Opus agent, money path + scoring gate). Full record: `_METHOD/ENGINE/reviews/BUILD_AUDIT_2026-07-14.md`. ALL findings are LIVE-mode / hardening only — the offline core loop verdict is GREEN and unaffected (dry-run cannot spend; scoring backstopped by package.py in the runner path). Nothing was auto-fixed (proof-check discipline).

**★ H-1 (HIGH — MUST FIX BEFORE THE FIRST LIVE CYCLE):** a halted LIVE attempt's already-incurred Higgsfield spend is dropped from `COGS_LEDGER.jsonl`, so the monthly cap (which sums the ledger) can be exceeded across operator-cleared over-ceiling cycles. `production/runner.py:529-548` returns `EXIT_HALTED` after only a 0-credit `write_halt`, before `write_cost_record`/`evaluate_and_record` at 560-564. Verified repro: monthly cap 60, two cycles × 40-credit ceiling, each attempt really cost 50 → 100 real credits spent, ledger MTD = 0. `test_h1` actually encodes the buggy behavior ("the 50 must never be metered"), which is why 290 green tests missed it. Compounded by a halt message that frames already-spent credits as prospective ("would reach/exceed"). **Fix:** meter the true cost record FIRST, then halt; reword the halt to say the credits were already spent; update `test_h1` to assert the halted spend IS recorded.

**M-1 (MEDIUM):** the production spend gate (`production_gate.py:115`) accepts on `verdict == "CLEARED-TO-PRODUCE"` alone and ignores the validator's `judgment_required`/`unresolved_judgment_count` (the fixture returns CLEARED with `judgment_required: true, count 5`), contradicting `validate_engine.py:292-296` which made those machine-visible precisely so a spend-gating caller wouldn't treat CLEARED as fully cleared without a human-judgment pass. Compensating control: operator-signed strategy-approval + per-cycle CREDIT_AUTH are still required. **Fix:** refuse (or require explicit override) when `judgment_required` is true.

**M-2 (MEDIUM):** the scoring gate detects but does not CAP the verdict on reel-length (R4, non-hard-gate) or carousel-slide-count; a 120s reel scored directly via `score.py` → PASS exit 0. Backstopped by `package.py:96-122` assembly enforcement (the runner path always hits it), so not exploitable in the current runner path — a single-point-of-enforcement fragility. **Fix:** make R4 + slide-count real hard-gates, or clamp to REVISE on a failed shape check inside `score.py`.

**LOW:** (1) rollup readers `.get("higgsfield_credits_actual", 0)` at `cost_schema.py:109,121` — H2-sibling, not exploitable today; prefer strict read. (2) `subprocess.run(score.py)` has no `timeout` (`runner.py:397,567`) — a hang hangs the runner; add bounded timeout → GATE-CRASH. (3) live 3-attempt budget caller-supplied (`--attempt`), not cross-checked vs `package.next_attempt_number` — REVISE→REJECT dodgeable by resubmitting attempt-1 (no PASS/spend leak). (4) dual YAML parser divergence risk on non-PyYAML hosts.

**Why:** LIVE money-path integrity + audit faithfulness. H-1 is the money-audit ledger under-counting REAL spend and a porous monthly backstop — it must be closed before any real Higgsfield spend. The rest are hardening.

**Estimate:** H-1 ~1-2h (re-order meter-before-halt + reword + fix test). M-1 ~30min. M-2 ~1h. LOWs ~1-2h batched.

**How to start:** Read `_METHOD/ENGINE/reviews/BUILD_AUDIT_2026-07-14.md` Tier-2 section; fix H-1 + M-1 before enabling `--live`; re-run `/proof-check` on the money path after (catches fix-introduced regressions).

**Acceptance:** a halted live attempt's true cost lands in COGS_LEDGER (monthly cap can no longer be exceeded across cycles); the spend gate refuses/flags `judgment_required`; `/proof-check` on the money path is clean before the first live cycle.

## 2026-07-16 — ai_layer.py `claude -p` agentic-bypass risk (from INTEL EP10 incident)
- `~/projects/insta-notion-sync/src/ai_layer.py:168-236` (`_tag_with_claude`) composes `claude -p` with default tools enabled — the exact pattern that went agentic in the INTEL extractor on 2026-07-16 (model wrote output files itself, bypassing wrapper validation; also caused fake "timeouts"). The INTEL fix: `--disallowedTools "Write,Edit,MultiEdit,NotebookEdit,Bash"` + `--strict-mcp-config` + 240s timeout (`OFFLIMITS/_METHOD/ENGINE/intel/extract_claims.py:_call_claude`). ai_layer's blast radius is smaller (tags, not validated claims) but the same hardening applies. LIVE pipeline (LaunchAgent) — apply only with operator go + its own test pass. Memory: feedback_claude_p_compositions_must_deny_tools.

## 2026-07-16 — BidFill task 2.6 (spend ledger) Fable-5 gate deferrals
- **Per-process daily call backstop is restart-resettable + N-worker-multiplied** (Fable lens-2 F3, MEDIUM). `spend._proc_calls` is module state; a crash-restart grants a fresh 2000-call budget, and N workers = N×2000/day. Now LOW because 2.6 fixed the dollar-cap fidelity (parse-after-settle + zero-usage floor), so the $1/day cap is the real bound and the call counter is belt-and-suspenders. Robust fix when needed: back the daily call counter with the ledger (`count(*) where created_at >= utc_day`), which also survives restarts. Do alongside 2.7.
- **Mid-job cap crossing terminally fails a job (no requeue)** (Fable lens-2 F5, MEDIUM). A job claimed at spend=cap-ε raises DAILY_SPEND_CAP retryable=False and fails permanently (the pre-claim gate narrows but can't close the window; there is no requeue path yet). When task 2.7 adds the fenced requeue RPC, DAILY_SPEND_CAP should requeue (the pre-claim gate then makes it wait `queued` until the cap resets), NOT terminal-fail. Tie to 2.7's `retryable` requeue-path decision.
- **Dead error codes DOWNLOAD_FAILED / UNREADABLE_PDF** (Fable lens-3 F6, LOW). Defined but nothing raises them; boto/PdfReader failures in processor.py fall to `unexpected` (PII-safe but wrong for triage). Small fix: wrap `storage.download_to_temp` / `PdfReader(...)` in the processor and raise the specific codes.
- **Timeout-after-billing edge** (Fable lens-1/2, sub-finding). A 300s client timeout (or connection drop) firing AFTER the Google server processed+billed the request is voided 'failed' at $0 — a rarer sibling of the parse case (that one is now fixed via parse-after-settle). The stale-reserved reconcile catches the crash variant; a network-timeout-after-bill still under-counts by one call. Acceptable (bounded by backstops + the $0.50 per-job cost cap); revisit if billing-vs-ledger drift shows up.

## 2026-07-16 — BidFill task 2.7 (least-priv role) Fable-5 gate deferrals
- **[DONE 2026-07-17 — migration 0017, task-2.9 gate]** ~~Reaper (reap_stuck_jobs) is NOT ledger-aware~~. The 2.9 cross-cutting Fable gate ESCALATED this from LOW-holds-today to HIGH: the timing invariant only covers heartbeat-staleness, not a hard crash (OOM/kill/reboot) that leaves settled spend, so a reaped+re-claimed job re-ran its billed calls = double-spend. FIXED: `reap_stuck_jobs` now requeues only jobs with NO non-'blocked' ledger row (job_id OR claim_token) and terminal-fails spent ones ('reaped_with_spend'); `requeue_bid_job` widened from claim-scoped to job-scoped in the same migration. DB-integration tests added (reaper-spent + prior-claim-spend). Applied + verified on dev.
- **Reaper-staleness invariant is comment-only, hand-synced across 3 sites** (Fable lens-3 F4). JOB_WALL_TIME_S=600 (consumer.py), reap_stuck_jobs default 900 (0004), and bidfill_cron_tick's hardcoded reap_stuck_jobs(900) (0011) must stay staleness >= wall + max-call(300). Mechanical enforcement: extend the boot contract check (uncallable_queue_functions) to read the scheduled cron staleness and refuse to boot if < JOB_WALL_TIME_S + MAX_CALL_TIMEOUT_S.
- **DAILY_SPEND_CAP retryable only resumes a job that spent NOTHING yet** (Fable lens-2 F2). A job that settled calls then crosses the cap mid-fill terminal-fails (requeue refuses to avoid re-spend) — the user's fill is consumed for nothing. The real fix is per-call checkpoint/resume (a retry skips already-settled pages). Bigger feature; comment now honest. Consider a user-facing "hit daily cap, resubmit tomorrow, no extra fill charged".
- **Expired-while-queued jobs sit as broken rows** (Fable lens-3 F1 residual). The purge (correctly) never deletes queued/processing jobs, but a queued job older than 7 days has no source PDF (R2 lifecycle deleted it) and will fail when claimed. Add a visible-expiry policy: mark very-old queued jobs failed with error_code='source_expired' (NOT delete — keep it visible in the dashboard).
- **get_job_status is unfenced** (Fable lens-1 F2, LOW). Returns a job's status enum for any job_id, granted to bidfill_worker. No PII, job_id is a random uuid (not enumerable) — accepted; note the asymmetry vs get_job_profile's fence.
- **handle_new_user() not revoked from PUBLIC** (Fable lens-1 F4, INFO not-exploitable). It's a trigger fn (returns trigger), so a direct call raises — not callable. Add the revoke for consistency when next touching functions.sql.
- **Phase-3 R2 orphan sweep:** list_expired_object_keys exists (built-not-running) but is NOT granted to the worker; grant it + wire the sweep caller in the Phase-3 deploy migration. The DB-row purge now keeps 'ready' rows 7 days past filled expiry so the sweep has a window to find R2 stragglers before the key record is gone.

## 2026-07-17 — BidFill task 2.8 (deploy artifact) Opus gate deferrals
- **Commit the reviewed hashed lock at Phase-3.** requirements.lock is generated + hash-installed by CI (job worker-lock) but NOT committed (gitignored), so it's a resolvability/hash-install smoke, not committed-baseline supply-chain integrity (Opus lens-2 F1/F2). At Phase-3: generate once on the linux/py3.12 box (or take the CI artifact), REVIEW the diff, COMMIT worker/requirements.lock, then switch the worker-lock CI job to install --require-hashes from the COMMITTED lock + `pip-compile` diff against it (fail on drift — never regenerate-and-trust). The deploy installs the committed lock.
- **Faster graceful shutdown (optional enhancement).** Today SIGTERM sets _stop, checked only between jobs, so a deploy restart can take up to ~900s (TimeoutStopSec=960) for an in-flight job to finish. Making JobContext.check() also raise on _stop would abort the current job at the next checkpoint (fail cleanly, ledger-safe, no re-spend) — shrinking shutdown to ~one call. Board says "finish-OR-fail", so abort-at-checkpoint is compliant. Deferred (config TimeoutStopSec=960 is safe now).
- **Lock toolchain is unpinned** (Opus lens-2 F7, LOW): generate-lock.sh installs pip-tools>=7.4 unhashed + CI upgrades pip unpinned — the tools that build the "secure" lock are themselves fetched without hash verification. Inherent bootstrap gap; note in the threat model, argues again for the committed reviewed baseline.

## 2026-07-17 — BidFill task 2.9 (phase-end cross-cutting gate) — FIXED + deferrals
**FIXED this session** (3 Fable-5 lenses over money/PII/fill; all committed, tests fail-without-fix, re-read by an Opus lens = SAFE): CRITICAL same-line neighbour-blank capture (a label whose own blank was undetected inked into the NEXT field's blank — live on the shipped safe methods, geometry.py `_span_between_is_clear` guard); HIGH entity-section wrong-fill (duplicate demotion counted post-gate, so a high-conf placement whose low-conf twin was gated out auto-inked the wrong of a corporation-vs-partnership pair — pipeline now counts raw Gemini mappings pre-gate); HIGH reaper not ledger-aware (see the DONE line under the 2.7 section); HIGH billed-but-failed Gemini call voided to $0 (hidden from the daily + per-job cap — now settles at the unknown-usage floor); MEDIUM requeue claim-scoped→job-scoped (folded into migration 0017); LOW settle-not-exception-safe in the new exception path (wrapped to match `void`).

**Deferred (MEDIUM/LOW — none block Phase-2 push):**
- **[MEDIUM] Loser filled.pdf + review.json are invisible to the DB-backed R2 sweep** (PII lens). On a reap+re-claim, `complete_bid_job` records only the WINNER's `filled_object_key`; the loser claim's `filled.pdf` and the PII-bearing `review.json` sidecar have no DB row, so `list_expired_object_keys` (the Phase-3 orphan sweep) can never enumerate them — they rely solely on the R2 bucket's 7-day lifecycle rule, and if that rule is prefix-scoped to `*/filled.pdf` it misses `review.json`. Same-tenant PII. Fix at Phase-3: record loser/sidecar keys in a `pending_object_deletions` table the sweep drains, OR upload `review.json` under a winner-stable folder; at minimum the bucket lifecycle MUST be a **whole-bucket (empty-prefix) 7-day rule** — R2 lifecycle prefixes are literal strings, not globs (`*/filled.pdf` is not a valid rule) and the per-job `<uid>/<uuid>/` prefix is not enumerable, so only an empty-prefix whole-bucket rule actually purges `review.json` + loser PDFs. Keep the nightly `pg_dump` backups in a SEPARATE bucket so the whole-bucket rule does not age them out. (Corrected 2026-07-17 by the Phase-3 plan adversarial gate — findings H1/M2; supersedes the earlier "whole `<uid>/<uuid>/` prefix" wording.) Ties to the existing Phase-3 R2 sweep item.
- **[MEDIUM] Over-text guard blind to sub-40-confidence OCR words** (fill lens). `extract.py` drops words below `OCR_WORD_MIN_CONF` from the ONLY word list, so `_band_has_text` sees an empty band where handwriting sits (handwriting OCRs ~20-50 conf, print stays high) → the engine can auto-ink over existing handwriting on a scanned form. Fix: keep sub-threshold words as `blocker_words` for `_band_has_text` while excluding them from anchoring/underscore candidacy. (Also: `_band_has_text` sees words only, not image/vector pre-filled marks in a digital PDF — smaller facet.)
- **[MEDIUM] Ink choke-point truncation/overflow has no CI lock** (fill lens). `overlay.py` font-shrinks then truncates (`text[:-1]+"..."`) or overflows a too-long value; the pipeline `_value_fits` demotion (the only thing keeping that dead) has no test asserting the PIPELINE demotes an unfitting value — delete that one `elif` in a refactor and every test still passes. Fix: `overlay_autoink` raises `UnsafeInkAttempt` when the value can't fit at min font; delete the truncation/overflow fallback; add a pipeline test (too-long high-conf mapping → review) + a writer test (unfitting placement raises).
- **[LOW] Predicate CI lock is enumerative** (fill lens). `test_engine.py` locks a fixed method list, so `should_autoink(...) or method == "smart_below"` passes all three lock tests; exploiting needs a second change (a producer emitting the name) — the shape of a future new-method diff. Fix: source-level lock on the `should_autoink` body (`inspect.getsource`) + a few fuzz method names asserted False at high confidence.
- **[LOW] `_fail` ignores `fail_bid_job`'s fenced-out result** (money lens). `consumer.py` logs "job failed" unconditionally even when `fail_job` returns False (claim fenced out), muddying logs during a reap-race. Fix: branch on the boolean like `complete_job` does.
- **[LOW] `purge_soft_deleted_profiles` can strip a long-parked live job's PII snapshot** (PII lens). A job queued before a profile soft-delete, parked >30 days (behind the cap/backlog), loses its version snapshot when the profile is hard-purged (FK `set null` + `cascade`) → the job later terminal-fails `PROFILE_MISSING` (does NOT leak, does NOT delete the job row). Fix: skip profiles referenced by a non-terminal `bid_jobs` row (`and not exists (select 1 from bid_jobs where profile_id = company_profiles.id and status in ('queued','processing'))`).
- **[MEDIUM] Stale-reserved reconcile runs only at process startup** (money lens). A `settle()` that raises leaves a row 'reserved' at $0 (counted at $0); a long-uptime systemd worker never re-surfaces it and never re-settles it to a floor. Fix: run `stale_reserved_calls` on the ~60s reap cadence and settle rows stale >900s at the conservative floor. (Related to the 2.6 "timeout-after-billing edge" item.)

Provenance: task-2.9 phase-end gate, 3 Fable-5 lenses + 1 Opus regression re-read. Detail: scratchpad `phase2_9_gate_findings.md`; repo `~/projects/bidfill`.

## 2026-07-18 — proof-gate.sh over-match + stale flag (from INTEL session)
- **FALSE POSITIVE:** the gate's publish-regex matches the word "pushed" INSIDE a `git commit -m "..."` message (its `.*` spans the -m string) — it blocked an innocent INTEL docs commit today; it also fails closed on any Bash whose raw text merely QUOTES a publish-shaped string (bit me when appending this very BACKLOG entry via heredoc). Hardening candidate: match the git subcommand position on parsed argv, or strip quoted strings before matching. NOTE: proof-gate.sh is itself in its own SEC_RX — change it only through a proof-checked cycle.
- **STALE FLAG:** `~/.claude/.proof-needed` still lists the BidFill migration (stamped 07-17 13:11) although that session ended proof-check CLEAR and shipped — the clean pass did not clear the file. Operator: clear the flag; also investigate why the skill's clean-pass clear step didn't fire (known op note: the classifier blocks Claude from clearing it, but the skill's own clear should have run).

## 2026-07-18 — INTEL pre-T8 proof-check: MEDIUM/LOW findings (HIGHs gated separately)
- **[MED F3]** extract_claims.py:538 — skip path trusts any existing claims file; a model-written residue would ride through silently. Fix: code-only `validated_by` provenance stamp + skip path refuses files lacking it.
- **[LOW F4]** push_to_notion.py:334 — URL-less reel bypasses idempotence pre-query → duplicates on rerun (latent).
- **[LOW F5]** intel_guard.py check (c) literal-substring lint evadable via composed paths.
- **[LOW F6]** WebFetch/WebSearch not denied in extraction call (network hygiene, not a write vector).
- **[LOW F7]** synthesize_principles.py suffix filter lacks isfile() guard.
- **[LOW F8]** stray hook_type on non-hook claims pollutes draft cluster metadata (cosmetic).
Provenance: ADVERSARIAL_REVIEW_2026-07-18_T7_CHECKPOINT.md in OFFLIMITS _METHOD/ENGINE/reviews/; fresh-Opus-agent lens (Codex install broken — separate item: `codex` binary ENOENT at /opt/homebrew/lib/node_modules/@openai/codex/..., reinstall needed).

## [Open] — 2026-07-19 — BidFill fill-engine ACCURACY build (the product's hard core)

**What:** A focused, MEASURED build to make the BidFill fill engine reliably auto-fill diverse real agency forms. Phase-3 DEPLOY is DONE + live (worker on Hetzner 77.42.43.44, all creds validated, first real fill proven $0.0028), but the fill ENGINE under-fills and, when pushed for coverage, over-fills. Treat the engine as its own project with a measurement harness + a failure-class backlog. Do NOT ad-hoc tune (it kept surfacing new failure modes on 2026-07-19).

**Why:** 2026-07-19 session, real spike forms + a fabricated profile (Ironline Mechanical): ODOT acroform 1->8 (own-company, correct) after a session's coverage work; BUT NJ Treasury "16 filled" was ~15 WRONG (vendor data in SUBCONTRACTOR blocks — engine ignored the "other party" qualifier); Reston oversized-font overflow + redundant "office if other than parent" fill + segmented phone missed. The engine is the product's core value AND its hardest part; needs systematic engineering, not tuning.

**Three pillars:**
1. Test-form corpus — categorize ~20 spike PDFs (~/projects/get-rich-scheme/spike/pdfs/): acroform vs digital; SINGLE-party vs MULTI-party; well-labeled vs messy. Add more real agency forms.
2. Precision harness — run engine per form with a fabricated profile; score CORRECT vs WRONG vs MISSED against a per-form ground-truth expectation set; measure before/after EVERY change. Extends the WIP scratchpad harness.
3. Failure classes (each with a fail-without-fix test):
   - **Own-company vs OTHER-party** (CRITICAL correctness): skip/route-to-review subcontractor / agency / prime / "other than parent" fields. The comprehensive-map prompt over-reaches here. FIRST item.
   - Combined fields: compose full address for "address city state zip" one-liners (line1+city+state+zip).
   - Formatted fields: segmented phone (___)___-___, split date/zip.
   - Rendering: oversized/overflowing AcroForm text -> set sane field font size/DA in overlay.py acroform_fill_autoink.
   - Contact-name person-vs-company disambiguation (needs PRECISE context — broad nearby-text caused a phone-in-fax wrong-fill 2026-07-19).
   - Signature: capture signer's signature IMAGE once at onboarding (profile schema + UI) + place/confirm in the REVIEW UI, NOT engine auto-guess (real forms have ~25 entity-specific signature blocks). Signature fields already route to review (2026-07-19 _SENSITIVE_FIELD guard in pipeline.py).

**Session WIP (2026-07-19, UNCOMMITTED, Mac-only, NOT deployed — live box runs the OLD conservative engine):** worker/src/engine/llm.py (comprehensive acroform prompt + labels + no 200-cap) + pipeline.py (_tier0_acroform: label-feeding, fuzzy field-name match, deterministic scalar override _SCALARS, duplicate-relax for scalars, _SENSITIVE_FIELD signature guard). 116 unit tests pass. IMPROVED single-party (1->8 ODOT) but introduced multi-party over-fill (NJ). Keep as a starting point; own-company-vs-other-party is the first fix. Harness at scratchpad/engine_harness.py.

**How to start:** build the precision harness + ground-truth for 5-6 corpus forms (mix single/multi-party, acroform/digital); baseline the WIP; take own-company-vs-other-party FIRST. Every change measured + test-locked. Phase-gate before any deploy (money/PII fill path).

**Acceptance:** high correct-fill rate with ZERO wrong-fills (incl. no other-party over-fill) across single- and multi-party forms; clean rendering; then re-deploy + phase-gate.

### Instafill benchmark — the accuracy-build YARDSTICK (added 2026-07-19, part of the fill-engine build above)
**Instafill.ai** is the direct competitor and the one that RAISED prices (dropped its ~$19.99 SMB tier -> now ~$99 Professional [50 docs, 25-page cap, NO reusable profiles] + ~$299 Business [profiles + API]). It does the EXACT same job (save profile -> auto-fill bid PDFs) with a 6-9 month head start + construction case studies + table/row support + flat-PDF->fillable + API. Same validated premise as ours.

**A $0 head-to-head IS possible:** Instafill has a genuine FREE tier — 10 credits/yr, no card — that (a) processes only the FIRST 2 PAGES of a doc and (b) is review-on-screen only (download is paid). So the benchmark: OPERATOR creates the free account (Claude never signs up for a competitor / accepts its ToS / enters payment); then Claude drives via browser — upload the SAME corpus forms, screenshot Instafill's on-screen fill, and score CORRECT/WRONG/MISSED vs our engine on pages 1-2 (where the company-detail fields live). Fair-enough slice for fill-quality on company info.

**Use as the accuracy-build TARGET metric, not a blocker.** Strategy reminder (from the origin research): we are NOT pitched as "more accurate than Instafill" — the play is good-enough accuracy + 5x cheaper ($19/$39 vs $99/$299) + construction-vertical depth (the moat). The moat is fragile (a single Instafill pricing-page edit reopens the sub-$30 lane) — so the product ACTUALLY WORKING + vertical depth is what matters, not price alone. Sources: instafill.ai/pricing, blog.instafill.ai/2026/04/29. Full competitor dossier: ~/projects/get-rich-scheme/_research/02_dossier_sig-D-01.md + 04_pricing_research.md + PROJECT_PREMISE.md.

## [Open] — 2026-07-20 — Pickle Garden (OFFLIMITS): Higgsfield image-production bridge for the calendar

**What:** A feature that connects the calendar image prompts (Notion Bible-shaped calendar + `_CLIENTS/PICKLE-GARDEN/PHOTOGRAPHY_MANUAL.md`) to the Higgsfield MCP so the manual-assembled prompts actually generate on-brand images, with the Tier-5 QC + a cost gate + write-back. Parked 2026-07-20 (operator: build later). Full design was researched this session (Higgsfield generate_image schema loaded + engine production path mapped by Explore agent).

**Why:** The calendar posts (12+ in the Notion DB `59e42ac21810492c8b7970a0b6682173`) each carry a ready AI image prompt built from the tiered PHOTOGRAPHY_MANUAL, but nothing turns them into images. Operator wants the prompts to "connect to Higgsfield MCP so it also has access to the photography playbook."

**Key findings (so a future session doesn't re-explore):**
- **The bridge is AGENTIC, not code.** The engine's Python spine deliberately cannot call MCP tools (EP5 design §2.3; `_METHOD/ENGINE/production/runner.py:22-24`, `EP5_PRODUCTION_RUNNER.md:119-121`). Only a Claude session makes the Higgsfield calls. So the "feature" = a runbook/protocol a session (or spawned agent) runs, NOT a script that generates unattended.
- **GPT Image 2 is reached THROUGH Higgsfield MCP** (`.claude/skills/visual-style-lock/references/engine-adapters.md:15,20` — model lock `gpt_image_2`, internal id `imagegen_2_0`). Call = `generate_image({model:"gpt_image_2", prompt, aspect_ratio:"3:4", medias:[{value, role:"image"}], get_cost})`. Verify gpt_image_2 is still live via `models_explore get`; if deprecated, fall back to an editorial photoreal model (soul_2 for people, nano_banana_pro for detail) + re-tune.
- **Anchor/media mechanism:** `medias[].value` = a Higgsfield `media_id` (from media_upload/media_import_url) or a prior `job_id`. The COLOUR anchors `72827920`/`6e53a374` are already Higgsfield job outputs → reference by job_id directly. The REAL court/café stills (`assets/_PHOTOS/Screenshot 2026-07-19*.png` courts + café stills) are local files → need a ONE-TIME OPERATOR UPLOAD into Higgsfield (the sandbox CANNOT upload — egress allowlist blocks the host; `engine-adapters.md:43`, `PHOTOGRAPHY_PLAYBOOK.md:241`). Then record the media ids via `show_medias` into an anchor registry.
- **Cost gate:** real credits spent. Per-cycle `CREDIT_AUTH.yaml` + monthly `budget_caps.higgsfield_credits_per_month` (`cost_schema.py`, `cogs.py`, `production_gate.py`); `_cost.json` fail-closed. Known bug H-1 (halted-credit-drop, `runner.py:529-548`) — a real spend right before a halt can go unlogged; fix or work around. Bridge must: read `balance` → `get_cost` preflight → generate → read credit delta (`transactions`/`job_status`) → log.
- **Consistency mechanism (PHOTOGRAPHY_PLAYBOOK §1.6):** attach an anchor frame in `medias` + append the white-balance clause to the prompt (already in the manual's Tier-4 tail).

**What to build (design):**
1. `_CLIENTS/PICKLE-GARDEN/HIGGSFIELD_ANCHORS.md` — anchor registry mapping the manual's anchors (E1 court stills, E2 café, colour anchors 72827920/6e53a374) → Higgsfield media/job ids (filled after the operator's one-time upload). Includes the upload bootstrap steps.
2. A **production runbook** (a per-client impl of the existing `_PROMPTS/ENGINE_PRODUCE_ASSET.md` contract, not a parallel path): for a calendar post → assemble prompt from PHOTOGRAPHY_MANUAL Tier-4 → resolve model + aspect 3:4 + anchor ids → cost preflight → `generate_image` → poll → Tier-5 QC (regenerate on fail) → write the image back onto the Notion post (external image URL as cover/embed) + set Status → log credit spend.
3. (Optional) a manifest-generator script that emits per-post `generate_image` call specs (JSON) from the Notion posts + the manual — code is fine (it only assembles specs; the session makes the MCP call).

**Open decisions (2 forks, unanswered — operator to pick when building):**
- **Surface:** Notion-direct (generate for Notion posts, attach images back — aligned with where the calendar lives; simplest) vs route through the engine EP5 (inherits the cost-gate + review-queue but needs a Notion→brief bridge). Recommended: Notion-direct now, EP5 door open.
- **Automation:** assisted + cost-gated per post/small-batch (preflight + operator go, QC each — recommended, given spend sensitivity) vs batch-auto under a ceiling.

**How to start:** operator uploads the real court + café anchor stills to Higgsfield; build HIGGSFIELD_ANCHORS.md from `show_medias`; write the runbook; do ONE live test generation (1 image, get_cost preflight, Tier-5 QC) to prove it lands before any batch. Phase-gate (money path = credit spend).

### UPDATE 2026-07-20 — Higgsfield bridge GRADUATED (entry above largely CLOSED)
The "Pickle Garden: Higgsfield image-production bridge" entry above is now BUILT: operator chose Notion-direct + assisted/cost-gated. Shipped: `Generate 🎬` checkbox on the calendar DB + `/pipeline produce` trigger (OFFLIMITS `.claude/skills/pipeline/`) + `_PROMPTS/ENGINE_PRODUCE_CALENDAR.md` sweep protocol (Approved-only governance, 40-credit ceiling, idempotent attach, one-regenerate rule). REMAINING from the original entry: (a) story-VIDEO routing (generate_video via seedance/sora/veo/kling) = sweep v1.1; (b) operator upload of the real court/café anchor stills into Higgsfield + a HIGGSFIELD_ANCHORS registry (colour anchors already work as job-ids); (c) EP5 cost-ledger integration if sweeps should count against engine budget caps (currently session-logged only); (d) unattended automation (webhook/scheduler) = pipeline Stage 7.

## [Done 2026-07-29] — 2026-07-21 — OFFLIMITS: deck-system V1→V2 path sweep across the constant docs
> Closed by the Window-1 A9 hygiene package (BUILD_PLAN_2026-07-28 §A9): all five docs swept (plus five more the fuller enumeration found), version banners on the four linked CSS/JS files, `system/CURRENT` machine anchor, `_SCRIPTS/check-system-pointers.sh` guard (exit 0 on the swept tree; planted-pointer negative test exit 1; bump-simulation proven), `_SYSTEM/VERSIONING.md` protocol. Adversarially reviewed twice (initial + delta); residual LOW hardening parked in the 2026-07-29 entry below.

**What:** Five non-archive docs still name the FROZEN V1 constant path `OFFLIMITS/system/design/offlimits-deck-system.css` as if it were current: `OFFLIMITS/system/INSTANTIATE_PROTOCOL.md` (line 20, the File map), `OFFLIMITS/system/BRAND_STYLE.md`, `OFFLIMITS/system/BRAND_PLAYBOOK.md`, `OFFLIMITS/system/_SYSTEM/HOUSE_SIGNATURE.md`, and `HANDOFF.md` §8. Sweep each to `design-v2/` (or mark the reference explicitly as V1-historical), then re-grep to empty.

**Why:** The 2026-07-08 operator decision renamed `design-v3/` → `design-v2/` and recorded the lineage as `design/` V1 (frozen) → `design-v2/` current, but only the HUES deck's own links were updated. The docs were not swept. On 2026-07-21 that drift propagated into a build plan: both the Part-2 plan file and `HANDOFF.md` §8 instructed the new Pickle Garden strategy deck to link the V1 constant. Building on V1 would have silently dropped the widow-guard JS runtime that the 2026-07-21 ruling made BINDING on all on-image text. Caught by the ctdd-precheck Step-0 grounding gate and independently confirmed by a read-only inventory pass, which named the version skew as the build's single biggest trap. This is exactly the failure class HQ LESSON 29 describes: a ruling is not embedded until the old-spec sweep returns empty.

**Estimate:** 30-45 min. Five files, mechanical, but each needs reading in context so a genuine V1-historical reference is not wrongly rewritten.

**How to start:** `grep -rln "system/design/offlimits-deck-system" --include="*.md" .` from the OFFLIMITS repo root, excluding `_ARCHIVE/`. Decide per hit: current-spec (rewrite to `design-v2/`) or historical (annotate as V1, frozen). Then re-grep to empty.

**Acceptance:** the grep returns only `_ARCHIVE/` files and explicit V1-historical annotations; a fresh session reading `INSTANTIATE_PROTOCOL.md` gets the current path.

## [Open] — 2026-07-21 — Pickle Garden: two stale system-state claims + the unresolved promote-cap conflict

**What:** Three linked items found while grounding the Kat strategy deck. All verified against the live Notion calendar (data source `e5acae0b-fc5d-4c1c-8b47-b6c4e9b28cf0`), not from any hand-typed table.

1. **STALE** — `04_CONTENT_STRATEGY/CONTENT_BIBLE.md` §"How the ratios are verified", History paragraph asserts *"`Pillar` is not a field on the calendar, so nothing records what the pillar was before the post was written."* Disproved: `Pillar` and `Ask?` are both live, populated fields on every row. The same section's earlier paragraph already records that they were added and backfilled on 2026-07-20; the History paragraph was never reconciled with it. The document contradicts itself.
2. **HALF STALE** — `01_STRATEGY/POSITIONING_LAYER.md` §Provenance asserts *"the precedence rule is unenforceable until `Pillar` exists as a calendar field. Both are open."* The field now exists, so the rule is enforceable as a control. Whether the mix itself reconciles remains genuinely open (item 3).
3. **UNRESOLVED, and it is an operator call** — the promote cap. Measured 2026-07-21: BOFU = 2 of 12 posts = **16.7%**, against a **10% cap** and the **15% house ceiling**. Both BOFU posts are Thursdays, and both of the calendar's Thursdays are BOFU. `CONTENT_BIBLE.md` §"The weekly rhythm" records a 2026-07-20 decision that Thursday now *alternates* and claims *"BOFU share drops to roughly 8%, under the cap without any cap change"* — but that decision was **never applied to the calendar**. The same document's §"The promote cap" still correctly describes the conflict as open. Two sections of one document disagree; the calendar settles it in favour of the second. Resolution is the operator's: either Thursday moves to fortnightly, or the cap moves toward the 15% house ceiling.

Related observation, not a defect: the pillar mix currently reads The Invite 33.3% / Your Four 25% / First Serve 16.7% / After the Game 16.7% / The Grounds 8.3% against targets 20/25/25/20/10. This is a 12-post window and the Bible is explicit that a window that size, lacking Saturdays and occasions, **cannot validly verify these ratios** — so it is not a failed check, it is the absence of a passed one. A valid check needs a full four-week window.

**Why:** Items 1 and 2 are LESSON 26 self-confirming-degradation risks: a false claim about system state survives because nothing forces verification. Item 3 is a live governance conflict that would have been shipped to the client as settled. The strategy deck was going to present "promote capped at 10%" to Kat while the calendar she can open runs 16.7%.

**Handled for now:** the deck presents the mix as a designed target and names the open item plainly as a decision to take with the client (operator ruling, 2026-07-21). That is a presentation fix, not a resolution.

**How to start:** decide item 3 first (it is the only real decision); items 1 and 2 are then mechanical corrections that should quote the verification query. Re-run the Bible's own prescribed check over a full four-week window before asserting any ratio is met. Do not compute the mix by hand in the document.

**Acceptance:** the promote-cap rule is stated once, consistently, in both `CONTENT_BIBLE.md` sections and reflected in the calendar; items 1 and 2 corrected with the query as the artifact; `validate_engine` still READY-TO-PLAN.

## [Open] — 2026-07-22 — OFFLIMITS: the CREATIVE-TREATMENT / THEME layer is missing from the method and the engine

**What:** There is no creative-treatment layer anywhere in the OFFLIMITS system — no library, no taxonomy, no brief field, no selection step, no gate. Content is modelled by pillar / persona / day-slot / franchise / occasion / visual-class / funnel-stage, and by *what a piece is about*, never by *how it is made and how it feels as a craft object*. Operator raised it 2026-07-22; a full audit confirmed it.

**Verification artifacts (all checked, not inferred):**
- `_METHOD/CONTENT_BRIEF_SCHEMA.md` §3–4: fields are `format` (container: reel/carousel/story), `narrative_framework` (pixar_spine/aida/pas…), `hook_type` (first 3 seconds), `register` (premium/standard/vernacular/scrappy). **No `treatment`, no `theme`.**
- Repo grep across `_METHOD/ENGINE/`: `theme` → **0 matches**; `treatment` → 1 match, a prompt-builder comment (`design/EP5_PRODUCTION_RUNNER.md:156`) referencing a brief field that does not exist. `asmr`/`timelapse` → 0.
- `_METHOD/CONTENT_CRAFT.md` — despite the name, contains **zero craft techniques**; it is narrative architecture + copywriting frameworks + hook taxonomy + repurposing.
- Live PG Notion calendar (`e5acae0b-…`): **9 of 12 posts are the same visual treatment** (Photo+overlay). No treatment field on the DB.
- Generated `CALENDAR.md` columns: `Date | Platform | Pillar | Format | Cluster/topic | Hook type | Brief id`. That is the whole dimensional space of a generated month.

**The root cause is OUR port, not a gap in the client's thinking.** The client's Bible carries ~9 treatment-led franchises out of 31 (V2 animated chat-overlay, V3 pure ASMR, V4 timer-on-screen, V5 mic'd-up, V6 silent/reaction-only, V7 split-screen dual interview, V10 fixed audio sting, 5B-2 macro+near-silent, 5C-6 zero-VO montage). Our `04_CONTENT_STRATEGY/CONTENT_BIBLE.md` §"signature franchises" flattens each to **Franchise | Persona | Pillar | Funnel** and **discards every structure line — i.e. exactly the treatment information.** "Seedlings (Mic'd Up)" survives only as a parenthetical inside a name; **"The Sound of RM90" is absent from our table entirely.**

**Two live contradictions this surfaced (must be resolved by any theme build):**
1. `_CLIENTS/PICKLE-GARDEN/REFERENCE_MAP.md` §Motion grammar states *"Sound-off discipline; every sequence reads muted."* That is in **direct tension** with a sound-led treatment such as the ASMR franchise. Nothing reconciles them.
2. `_METHOD/CONTENT_STRATEGY_MANUSCRIPT.md` Phase 4 prescribes *"quarterly themes + monthly execution + weekly batching"* — **the engine implements no theme at any stage.** "Theme" is a dangling doctrine word with no field, reader, emitter or calendar column.

**Also noted:** `_METHOD/ENGINE/design/EP9_11_INTEL_ENGINE.md:55` defines a graft-routing row literally named *"Format craft / asset-class arc"* — the slot exists and nothing treatment-shaped has ever landed in it. And when the pricing register adopted "The Sound of RM90" (2026-07-22) it harvested the format for **tone doctrine** and left the ASMR treatment unused.

**Why it matters:** without this layer the feed goes static — proven empirically at 9/12 identical treatment — and the brand reads stale even while the strategy is sound.

**Status 2026-07-22:** operator has commissioned a **bi-weekly theme layer, 8–10 themes across the year**, each laddering to the brand premise. Web research on themed brand presences commissioned first to derive principles before designing PG's own. Seed example from operator: "The Professional" — a character archetype per pillar whose ritual precision is the treatment (a technique tutorial delivered by a figure whose obsessive particularity shows in how he arranges the lounge table or moves through the amenity).

**How to start:** research → principles → theme set design → adversarial review (highest risk: a theme layer that merely duplicates pillars under new names) → brief-schema + engine field decision (deferred; the layer can run as doctrine before it becomes a field).

## [Open] — 2026-07-22 — Pickle Garden: Class-D real-footage OPERATIONS — capture loop + consent registry
**What:** Two operational gaps behind the new Class-D (real-footage reel) doctrine, found by the proof-check completeness critic. (1) CAPTURE LOOP: reels route to capture and vanish — no batch-day schedule exists, no captured/edited/posted status tracking, and no timing rule that an emphasis fortnight's footage must exist BEFORE the fortnight runs (the Bible's monthly batch day vs the fortnightly emphasis is an unaddressed cadence mismatch). (2) CONSENT REGISTRY: QC demands "§6.4 consent confirmed for every face" and member-series activation is cast→consent→capture, but nothing defines WHERE WhatsApp confirmations / cut approvals / guardian forms are recorded or how QC verifies one exists per face (the records live on the client's phone today).
**Why:** Without (1) the first emphasis fortnight ships with no footage to cut; without (2) the consent gate is unauditable — a face could ship with no verifiable consent artifact, which is a brand/legal exposure on a premium club.
**Estimate:** (1) half-day — batch-day cadence rule + a capture-status field in the Notion calendar; (2) 1-2h — a CONSENT_LOG.md (or Notion property) spec + a QC line pointing at it; needs one client conversation about where her §6.4 confirmations live.
**How to start:** `_CLIENTS/PICKLE-GARDEN/04_CONTENT_STRATEGY/EMPHASIS_LAYER.md` §3.2/§3.3 + `03_PLAYBOOKS/GRAPHIC_SYSTEM.md` Class D + the client Bible §6.1/6.2/6.4. Resolve BEFORE the first face-forward member-series feature ships; the capture loop before the first Class-D fortnight is planned for production.
**Acceptance:** a planned Class-D fortnight shows its footage captured before the fortnight starts; every face-forward post can point at its consent record from the calendar entry.

## [Open] — 2026-07-28 — PG plan review: 16 MEDIUM/LOW findings to fold into the revision + doctrine-edit session
**What:** Adversarial review of the Pickle Garden revision/build plan returned NOT-CLEAR (4C/8H stop the plan — handled live); the 11 MEDIUM + 5 LOW findings are parked here per /proof-check. Highlights: C1 supersession list incomplete (8+ fortnight loci incl. board 12 + Emphasis field semantics); spine-card ≤1/wk cap unallocated across threads; photo re-weight collides with locked master prompt + 2026-07-20 reversal ruling (no plate-library migration path); trough is actually 13:00–16:00 and WED 10–11 is the seniors block; collab categories were "under consideration" at source but "operator-approved" downstream (fix wording at source; partner commits = Kat §6.3b); shoot day ends 19:00 = no Grade A-evening; shoot-day court-occupancy collision (clean windows: MON, WED pm); consent BACKLOG item is two-part (capture loop + registry) and model releases sit outside Bible §6.4; zone naming vs The Grounds live trigger + POV "movement club" clause; stale doctrine lines CONTENT_BIBLE.md:147/:127 + VOICE_GUIDE status "pending"; BUILD_PLAN says 58 stale briefs, disk = 52; no rollback named for Notion schema / Emphasis semantics / photo re-weight; no trademark check on Holding Court / Open Court.
**Why:** These don't block the plan revision but WILL bite during the doctrine-edit session or the first shoot if lost. Full report: session scratchpad `pg_research/ADVERSARIAL_REVIEW_PG_PLAN_2026-07-28.md` (copy into OFFLIMITS repo as review-of-record when the PG write gate opens); memory `project_pg_kat_feedback_revisions_2026_07_28.md`.
**Estimate:** absorbed into the PG plan-revision + doctrine-edit sessions (no standalone work).
**How to start:** open the review report §MEDIUM/§LOW alongside the revision checklist; tick each finding as the corresponding doc is re-cut.
**Acceptance:** every M/L finding either fixed in the edit session, explicitly ruled out by the operator, or re-parked with a reason; stale-line fixes verified by re-grep (Lesson 29 sweep-to-empty).

## [Open] — 2026-07-29 — OFFLIMITS version guard: 4 LOW hardening notes from the A9 delta re-review
**What:** The A9 hygiene window shipped `_SCRIPTS/check-system-pointers.sh` with all HIGH/MEDIUM findings fixed and bump-simulation proven; four LOW residuals were accepted-and-parked. (1) N1: `_CLIENTS/*/deck/DECK_BUILD_HANDOFF.md` is path-excluded from the scan (its lineage lines carry no same-line qualifiers), so its ":16 Design system = current (design-v2)" claim goes stale invisibly at the next version bump — cleaner fix is dated qualifiers on :5/:7/:16 of the HUES baton and dropping the exclusion (the file sat outside the Window-1 scope fence). (2) grep read-errors inside the two main scans are visible but don't fail the guard (exit codes unchecked in the pipeline). (3) The canary floor (≥20 docs + BRAND_STYLE.md + HANDOFF.md) won't catch a partial find-walk that loses only a client subtree — both canaries are root/system files; add one _CLIENTS canary. (4) The `./HANDOFF.md` canary match is an unanchored regex any `*/HANDOFF.md` path satisfies — anchor it.
**Why:** All four are same-threat-model hardening on a human-run doc-hygiene guard (not internet-facing); none blocking today — the guard fails closed on the paths that matter (malformed CURRENT exit 2, missing anchor/CSS, planted pointer exit 1, bump-simulation exit 1 with the full sweep list).
**Estimate:** 30-60 min total, single file + one HUES doc edit.
**How to start:** `_SCRIPTS/check-system-pointers.sh` (canary block + pipeline exit codes); `_CLIENTS/HUES/deck/DECK_BUILD_HANDOFF.md` :5/:7/:16 dated qualifiers then remove its path exclusion; re-run the T1–T4 battery (clean 0 / plant 1 / malformed 2 / bump-sim non-zero) recorded in the Window-1 session.
**Acceptance:** exclusion list one entry shorter; a deliberately broken grep or half-walked tree makes the guard exit non-zero; battery still green.
**Addendum (same day, map-guard delta review):** two LOW holes in the sibling `_SCRIPTS/check-architecture-map.sh` join this entry: (5) its TO-BUILD/planned skip is LINE-scoped, so a real existing path sharing a line with a declared-future item (e.g. the `_CLIENTS/_TEMPLATE/` slot on the map's C1 row) escapes checking — make the skip token-scoped; (6) its multi-root fallback certifies existence, not location — a short token can resolve at the wrong root (e.g. a bare `design/` via the ENGINE namespace) after the intended home moves — consider recording the resolved root per token and flagging when it changes.

## [Open] — 2026-07-30 — PG PHOTOGRAPHY_RULEBOOK v6.1: 4 MEDIUM + 3 LOW residuals from the proof-check
**What:** The consolidation of the Pickle Garden photography doctrine into `03_PLAYBOOKS/PHOTOGRAPHY_RULEBOOK.md` (v6.1) passed its post-fix gate PASS_WITH_NOTES. The 2 HIGH regressions were surfaced live to the operator; these 7 residuals are parked. (M3) QC-7 says "below the frame type's required count → re-roll" but no frame type in §5b declares a required device count — the agent has no number to compare against. (M4) Two validated camera rows were altered without a §12 log entry, breaching the file's own one-variable rule: frame 10 moved 20–30° → 0–14°/Mode A (the old band already sat inside Mode B, so the disjointness fix didn't require it), and frame 1 changed BOTH height and lens (hip/28mm → chest/35mm). (M5) No light line exists for the outdoor anchor's own conditions — §3 offers only high-sun and low-sun crisp-shadow lines, but `retest1v2_garden_stagger` was shot in diffuse open shade with a blown-white sky, so §9.6's worked bracket cannot reproduce the anchor QC-9 judges coherence against. (M6) Frame 7's light line is undefined — §9.2 makes a verbatim §3 light line mandatory, §3 says frame 7 is "a grade swap, not a light line", and the worked bracket contains none; derivable but never stated. (L7) The §11 arbitration clause reads "the grade reference exactly" where the locked original reads "the grade reference image exactly" — a one-word paraphrase of a clause §12 declares never-paraphrased. (L8) §9.2 has no n/a path for object frames — step 3 mandates per-person casting and step 7 mandates the full location block, but a flat detail on court paint shows none of the courts-hall architecture, leaving QC-5 nothing to compare. (L9) `SHOT_LIST_MATRIX.md`'s supersession banner claims the "lens kit" migrated, but only the 24mm proximity warning survived — the 28/35/50 character notes have no home in the rulebook.
**Why:** None blocks generation; all four MEDIUMs will bite at the first gated grade test (M5/M6 directly — an agent shooting the outdoor or warm-daylight frame types), and M4 leaves two silently-changed geometries that a future session cannot distinguish from validated ones. L7 matters because the clause exists to stop amber contamination and the file's own change-control forbids paraphrasing it.
**Estimate:** 45–60 min, single file plus one banner line.
**How to start:** `_CLIENTS/PICKLE-GARDEN/03_PLAYBOOKS/PHOTOGRAPHY_RULEBOOK.md` — add a device-count column to §5b (M3); log or revert the two geometry changes in §12 (M4); add an "outdoor, diffuse open shade" light line to §3 and re-point §9.6's worked bracket (M5); state frame 7's light explicitly (M6); restore "reference image" verbatim (L7); add an object-frame n/a path to §9.2 (L8); fix the SHOT_LIST banner or migrate the lens notes (L9).
**Acceptance:** an agent can assemble a prompt for all 10 frame types with no undefined value; every §5b row's geometry either matches `SHOT_LIST_MATRIX` or carries a dated §12 amendment; the arbitration clause matches the locked original word for word.

## [Open] — 2026-07-31 — Trust Gate + doctrine residuals: 5 MEDIUM + 5 LOW from the cooling-off reconciliation proof-check
**What:** The 2026-07-31 reconciliation of the expired vercel cooling-off passed its gate only after 3 HIGH self-inflicted findings were surfaced live. These are the parked residuals. (M1) Tier C "Layer 4 reputation" is a `log` statement, not a check — `scripts/skill-install.sh:118-121` logs "reputation check skipped (v2 TODO)", yet `commands/scout.md:28`, `CLAUDE.md:61` and `commander/LESSONS.md:30-31` all assert "all 5 layers" run; `commander/TRUST_GATE.md:190-191` discloses it honestly and the other three do not. Newly load-bearing now that vercel-labs skills are surfaced by `/scout` rather than filtered out. (M2) `commander/MODEL_ROUTING.md:382` claims "chain is built fresh from INCIDENT_LEDGER.md minus cooling-off entries" — no router code reads the ledger at all (`scripts/model-router.sh`, `scripts/lib/model-router.py` contain no reference). A doctrine asserting a supply-chain check that never runs. (M3) `commander/INCIDENT_LEDGER.md` — the `## Format reference` fenced block contains a line-start `COOLING_OFF: <github-owner>/* until <YYYY-MM-DD>`; the parser is line-based and NOT markdown-aware, so the fence does not protect it. Inert today only because `<YYYY-MM-DD>` fails the `[0-9-]+` class — verified `COOLING_OFF: acme/* until 2027-01-01` MATCHES. A future editor writing a realistic example date creates a phantom block. Also makes `grep -c "^COOLING_OFF:"` return 1, not 0, so an agent following scout.md's new "read the live list" instruction gets a false hit. (M4) `commander/TRUST_GATE.md:94-105` lists 10 allowlisted authors; the real array at `scripts/lib/advisory-check.sh:25-38` has 12 — `ethers-io` and `Polymarket` (both added 2026-05-08) are missing from the doc. (M5) `commander/TRUST_GATE.md:197` mandates a MONTHLY ledger review to expire past-date entries; no reminder exists anywhere (`watchdog/reminders.json` has 5 entries, none about the ledger; no launchd job; nothing in `hooks/`). It lapsed 11 days. Note the asymmetry: a lapse in the expire direction leaves docs stale, but a lapse in the ADD direction is a straight fail-open, since the ledger's own header claims vendors are "auto-demoted" and nothing automates that. (L1) `~/.claude/CLAUDE.md:20` now reads "(tool + stack inventory — counts self-declared inside)" but `registry.json` has no stacks-count key — only `tool_count`/`skill_count`; `README.md:16` handles this correctly, so the two edits disagree in rigour. (L2) `advisory-check.sh:98` uses strict `<`, so a 90-day window blocks only 89 days. (L3) Residual stale counts of the same class: `commander/PLANNING.md:29,305`, `.claude/AGENTS.md:169`. README's old "138 subagents" was unsupported anyway — `agents/registry.json` declares 1. (L4) `INCIDENT_LEDGER.md`'s `## Format reference` prose ("Then a prose block following the template above") now points at the Expired block, so the add-a-new-vendor path is no longer self-demonstrating. (L5) `commander/TRUST_GATE.md:33` says "all 4 layers mandatory" three lines above "## The 5 layers".
**Why:** None blocks the gate today. M1/M2 are doctrine asserting protections that do not exist — the exact self-confirming-degradation shape Lesson 26 was written for, and the kind of claim a future session will propagate as fact. M3 is a live trap in the one file that is machine-parsed. M5 is why this reconciliation was needed 11 days late in the first place: a process with no signal and no default action (Lesson 20).
**Estimate:** 60–90 min for all 11, mostly single-line doc edits; M5 is the only one needing a new artefact (a reminders.json entry or a session-start check).
**How to start:** M3 first (neutralise the `COOLING_OFF:` template line in `## Format reference` — indent it or rename the token so no line starts with the literal except real entries). Then M1/M2 — either qualify the claims or implement them. M4 add the two authors with their provenance comments. M5 add a monthly `watchdog/reminders.json` entry, or better a `hooks/session-start.sh` check that flags any `COOLING_OFF:` line whose date has passed — that converts the manual review into a signal.
**Acceptance:** `grep -c "^COOLING_OFF:" commander/INCIDENT_LEDGER.md` returns 0 when no vendor is in cooling-off; every "all 5 layers" claim either matches the code or carries a not-yet-wired qualifier; the TRUST_GATE.md allowlist matches the code array exactly; an expired cooling-off date surfaces automatically without a human remembering.

## [Open] — 2026-08-10 — Persistence mandate covers memory files but not working artifacts — scratchpad loss recovered by luck of context
**What:** During the white-label banking research checkpoint, the session scratchpad holding the research working files (`R1_kalzero_findings.md`, `R2_alternatives_findings.md`, `MISSION_BOARD_kalzero_research.md`) was found **wiped** between the research turn (2026-07-28) and the checkpoint turn (2026-08-10) — temp-directory cleanup. Recovery succeeded only because (a) the two worker reports were still in the main thread's context window and (b) the raw session transcript survived at `~/.claude/projects/-Users-sunil-rajput/<session-id>.jsonl`. Had the session been compacted first, or had the checkpoint come one context-window later, the full R1/R2 reports (~350k subagent tokens of research) would have been **unrecoverable** — the durable memory file held only a compressed summary, not the sourced detail.
**Why:** The global mid-session-persistence mandate in `~/.claude/CLAUDE.md` is explicit about **memory files, Decision Log, and project state** — and that layer worked perfectly (the memory file and MEMORY.md index line both survived untouched). But it says nothing about *working artifacts*, and the Commander/foreman flow actively encourages writing mission boards and worker findings to the scratchpad, whose own tool description advertises it for "storing intermediate results or data during multi-step tasks." So the doctrine points two ways at once: persist immediately, but stage your work in volatile storage. The near-miss cost nothing this time; the same shape on a longer research fan-out loses the expensive artifact and keeps only the cheap summary. Note this is a *different* failure class from the 2026-04-27 compaction incident (which was about not persisting at all) — here persistence happened, to the wrong tier of storage.
**Estimate:** 20–30 min. One clause in `~/.claude/CLAUDE.md`, one line in `commander/COMMANDER.md` Step 4/5, optionally one in the `hq-foreman` skill's "Durable state" section (which already says mission boards live in the project's MISSION_BOARD.md — that guidance is right and was simply not followed, so the gap may be enforcement rather than doctrine).
**How to start:** Decide the rule first — candidate: *"any artifact a later session would need to re-derive (worker reports, mission boards, research findings) is written under the project directory, never the scratchpad; the scratchpad is for artifacts that are genuinely disposable within the turn."* Then sweep: `~/.claude/CLAUDE.md` persistence block, `commander/COMMANDER.md` Steps 4–5, `~/.claude/skills/hq-foreman/SKILL.md` "Durable state". Per Lesson 29, grep the old framing to empty before claiming it is embedded.
**Acceptance:** a fresh agent reading the persistence doctrine can answer "where does a subagent's research report go?" with "the project directory" and not "the scratchpad"; and a spot-check of the next multi-worker fan-out shows worker outputs landing under `~/projects/<name>/` at the time they return, not at checkpoint time.

## [Open] — 2026-08-14 — Web arm: vercel-labs `find-skills` install (deferred from the activation wave by operator ruling)
- **What:** Install the `find-skills` skill from `vercel-labs/skills` into the web-arm toolkit via the full Tier C pipeline (G5 route: gated clone + lib scan + manual skill-dir copy — `skill-install.sh` cannot resolve its `skills/<name>/` layout).
- **Why:** Operator ruling 2026-08-14: "lets have this as a task in itself, which is carried out afterwards... we have plenty of other tools we can utilise." Vercel context: cooling-off EXPIRED 2026-07-20 but NOT re-admitted to allowlist; ledger criteria (b) post-mortem and (c) supply-chain review remain UNVERIFIED → full-scrutiny lane. Also note: the skill teaches agents to self-install via `npx skills add`, which HQ doctrine overrides (G-routes only); that teaching needs a doctrine wrapper at install time.
- **Estimate:** ~30-45 min including the Tier C run and doctrine note.
- **How to start:** Read `project_offlimits_web_arm_build_2026_08_12.md` (memory) + the activation plan's G4/G5 mechanics; clone `https://github.com/vercel-labs/skills` with the logged override form, scan, copy `find-skills`, wire, verify in listing.
- **Acceptance:** skill live in listing + invocation test; Tier C scan logs on record; doctrine note appended to the web-arm LIBRARY entry; this item flipped to [Done].

## [Open] — 2026-08-17 — NTF Phase A1: 7 MEDIUM + 6 LOW residuals from the post-fix proof-check (notes/labels + 4 seams)
- **What:** The proof-check on the NTF landing wave (guide v2 + narrative L1–L5 + ch7 review read) passed with 0 CRIT/HIGH; residuals are label/note slips in the disposable read file (2 patched by the foreman same day), 6 partial closures of first-pass findings (fragment changelog pointer, Action Plan body still Mode-P-worded beyond its amendment block, corpus/fingerprint notes, read §11), 3 open by design (HANDOFF stale until `/handoff save`; the A4 confirmation email collides with the new "Kept." moment; the untracked CIRRANEU tree has no independent baseline), and 1 operator-ear item (06a M6 solo-attendance reading of "you won't be the only one who remembered").
- **Why:** Lesson 26/29 hygiene: partial closures become false claims if left; the email collision must be resolved in A4 before Mode L copy ships.
- **Estimate:** 1 short Opus fix ticket (~30 min) + `/handoff save`.
- **How to start:** Read `/Volumes/Elements/My_Stuff/OFFLIMITS/_CLIENTS/CIRRANEU/PROJECTS/NEVER_2_FAR/TOV/A1_RECALIBRATION/07_PROOF_CHECK.md` ("Pre-fix findings re-checked" table + new MEDIUM/LOW), batch into one ticket, re-grep.
- **Acceptance:** every partial-closure row flips to closed with evidence; Action Plan body no longer teaches Mode P; HANDOFF refreshed; A4 ticket carries the email-collision item explicitly.

## [Open] — 2026-08-17 — NTF: choose the handwritten-look typeface (operator parked the exploration)
- **What:** At checkpoint 24 the operator ruled that a handwritten-look FONT (not real or generated handwriting imagery) carries the family's hand on Never Too Far, naming Caveat as the family of feeling, and explicitly parked the typeface choice: "we can explore other fonts with a handwritten look, but we will do this later." Pick the actual typeface (licence, weights, CJK coverage if Q14 lands multilingual, legibility at ad and mobile sizes, how it behaves beside the Mazius/spoken-serif pairing).
- **Why:** This overrules the LOCKED Creative Direction §3 ("Never a script font doing an impression of one") and is recorded as Direction deviation #5, so the choice is load-bearing for the whole brand hand: postcards, family lines, ad lines. Leaving it unchosen blocks nothing today but blocks Fold 2 asset production and any ad art direction.
- **Estimate:** Half a day inside Fold 2 (shortlist 4 to 6, set the same line in each, operator picks).
- **How to start:** Read `TOV/N2F_Voice_and_Language_v2.md` §6.6 "The type" (deviation #5, ruled) and the locked `PREMISE/NEVER_2_FAR_Creative_Direction_v1_The_Postcard_Home.md` §3 and §4; set the ad-line RIGHT example and one postcard fragment in each candidate; check licence and CJK before showing the operator.
- **Acceptance:** one typeface named and licensed, recorded in the Fold 2 brand guidelines with the deviation note carried; the guide's §6.6 updated from "the Caveat family of feeling" to the chosen face.

## [Open] — 2026-08-17 — NTF voice guide v2: 10 LOW residuals from the final gate re-run (09c)
- **What:** The guide passed its final gate (PASS_WITH_NOTES, 0 critical, 0 high, 19/19 prior findings closed, no fix-introduced regressions). Its two MEDIUMs were applied by the foreman before sign-off (the Time-of-day law no longer cites a chapter 7 or gendered-microcopy line as protected; §9's handover checks gained an evidence test and a time-of-day test). The 10 LOW items in `TOV/A1_RECALIBRATION/09c_PROOF_CHECK_RERUN.md` remain: presentational counts, locator sentences, cross-reference polish.
- **Why:** Lesson 29 hygiene. None blocks the operator's sign-off or any downstream writing; left unfixed they slowly become false claims inside the doc that governs every word the brand ships.
- **Estimate:** One short Opus ticket (~20 min) folded into the next NTF writing session.
- **How to start:** Read the LOW section of `09c_PROOF_CHECK_RERUN.md`, batch into one fix ticket against `TOV/N2F_Voice_and_Language_v2.md`, re-grep, no gate re-run needed (LOW only).
- **Acceptance:** every LOW row closed with evidence; the guide's own counts and locators verify by grep.

## [Open] — 2026-08-17 — NTF: 7 LOW residuals from the checkpoint-25 gate chain (10b + FIX2 deferrals)
- **What:** The cp25 change (new chapter 6 step 1 + the generalise-by-the-act law) passed its gate after two fix waves. Residual LOWs remain, including two the last wave could not apply because they need `WEBSITE/N2F_Site_Narrative_v1.md` and it was outside that ticket's write set: a note pointing at flag 12 instead of the integration plan, and the file's line-5 governance banner sitting inside a block the file's own reading rule calls copy (pre-existing, predates this change). The rest are presentational (locators, cross-references).
- **Why:** Lesson 29 hygiene. None blocks writing or sign-off; left alone they slowly become false statements inside the two files that govern every word the brand ships.
- **Estimate:** One short Opus ticket (~20 min), folded into the next NTF session, ideally alongside the A4 microcopy sweep.
- **How to start:** Read the LOW sections of `TOV/A1_RECALIBRATION/10b_PROOF_CHECK_CP25_RERUN.md` and the "Not applied" note in the FIX2 ledger on the MISSION_BOARD; batch into one ticket across both files; re-grep; no gate re-run needed (LOW only).
- **Acceptance:** every LOW row closed with evidence; the narrative's ">" copy lines still hash to cb720d26703cf1a599042c97677960f56b00f19c.

## [Open] — 2026-08-25 — Trust Gate hole 4: `/plugin marketplace add` bypasses the gate entirely
- **What:** Claude Code plugin installs are a BUILT-IN command, not a Bash tool call, so the PreToolUse Trust Gate never fires. Verified: `~/.claude/settings.json` registers the gate with `"matcher": "Bash"`, and `grep -c 'plugin\|marketplace' ~/claude-hq/scripts/trust-gate.sh` returns 0. So `/plugin marketplace add OWNER/REPO` + `/plugin install NAME` lands arbitrary third-party skills, hooks, agents and scripts with ZERO Magika, ZERO secret-scan, ZERO Socket, ZERO cooling-off. Discovered evaluating `nateherkai/scroll-craft`, whose README instructs exactly this.
- **Why:** This is the LARGEST of the four known holes. Holes 1–3 need a mistyped command (`pip3`, `npm i -g`) or an internal error; this one is the documented, recommended install path for every plugin in the ecosystem — the route a README tells the operator to take. It also cannot be SHA-pinned: `/plugin marketplace add` tracks a moving branch, so a clean review never binds the next commit.
- **Estimate:** Investigation first (~1h): determine whether any hook matcher can see plugin installs on this build at all. If none can, the fix is doctrine + a pre-install checklist, not code.
- **How to start:** Read `~/.claude/settings.json` hook matchers; check whether Claude Code exposes a plugin-install hook event; if not, add a standing rule to `commander/TRUST_GATE.md` that every `/plugin` install is treated as ungated and requires remote inspection (GitHub API + raw reads, no clone) before installing. Cross-ref `project_trust_gate_holes_2026_07_31.md` hole 4.
- **Acceptance:** either a hook that fires on plugin installs, or TRUST_GATE.md carries the ungated-by-design warning and the pre-install checklist, and the three other docs claiming "every install is gated" are corrected (Lesson 29 sweep to empty).

## [Open] — 2026-08-25 — scroll-craft eval: 5 MEDIUM + 2 LOW residuals from the adversarial review
- **What:** The `nateherkai/scroll-craft` admission review returned 2 CRITICAL + 4 HIGH (all resolved by rejecting adoption) plus these residuals: M-1 the repo's own README says "Only ever run on Windows... no build has been done on a Mac" (we are on macOS) and adoption would force `npm i playwright-core` into the NTF build as an unrouted dependency decision; M-3 MIT attribution has no mechanism in the arm — `.provenance` records `repo @ sha` with no licence column, and the nearest precedent (`skiper40`, HANDOFF.md "attribution question at use") is an OPEN question not a mechanism; M-4 any skill adoption breaks two RECONCILE invariants (expected 29 web-arm symlinks, 23 `.provenance` lines — both verified exact today) and would read as drift on the next reconcile; M-5 no NTF ticket is permitted to execute a vendoring (G-CURATE selects and must not install; B1 must not adopt an unselected stack; B2 scaffolds the client build) so any arm amendment needs a named owner outside the NTF chain; L-1 vendoring a skill re-imports the same agent-context cost the plugin was rejected for; L-2 `kie.mjs` `download()` writes remote-controlled content to a caller-supplied path (moot while excluded, but not on the record).
- **Why:** M-3 and M-4 are general — they bite on the NEXT tool the arm admits, not just this one. The arm has no licence field and no counter-update step in its adoption procedure, so both will recur silently.
- **Estimate:** M-3 + M-4 together ~1h (add a licence column to `.provenance`; add "update the RECONCILE expected counts" to the adoption checklist in ACTIVATION_PLAN). M-1/M-5/L-1/L-2 are eval-specific and die with the rejection.
- **How to start:** Resolve the `skiper40` attribution question first — it sets the precedent for every MIT source on the shelf. Then add the licence column and the counter-update step to the arm's adoption procedure.
- **Acceptance:** `.provenance` carries a licence per source; the arm's adoption checklist names the RECONCILE counter update; the skiper40 attribution question is closed with a ruling.

## [Open] — 2026-08-26 — N2F cp69 proof-check MEDIUM/LOW findings (non-blocking, filed per gate)
**What:** (1) hero sentence width cap 669px is dead measure after the rewrap — no line exceeds 611.6px; re-cap to ~605px and re-check the wrap. (2) Pre-existing handnote mobile clipping: `site.css` late `white-space:nowrap` overrides the 860px media rule; #ache's fragment clips at 390px, the moved gate note fits by luck — move the base rule above the media block. (3) LOW: `aria-label` on a paragraph is ARIA-prohibited (use role="text" wrapper or visually-hidden copy); `scene4_interior.jpg` now unreferenced on disk; the untracked CIRRANEU tree means the cp69 wave has no revert baseline (standing operator-accepted risk, restated by the reviewer).
**Why:** Surfaced by the blind cp69 proof-check (verdict FAIL on separate CRITICAL/HIGH); MEDIUM/LOW do not block per the gate but must not evaporate.
**Estimate:** 30–60 min total, all mechanical.
**How to start:** `_CLIENTS/CIRRANEU/PROJECTS/NEVER_2_FAR/WEBSITE/BUILD/src/css/site.css:112` (cap), `:243` vs `:270` (nowrap), `src/js/scroll.js:96` (aria).
**Acceptance:** widest line within ~10px of the cap at 1440; all four handnotes unclipped at 390; axe clean on the hero; interior asset either re-referenced or consciously archived.

## [Open] — 2026-08-27 — N2F cp73-74 proof-check MEDIUM/LOW findings (non-blocking, filed per gate)
**What:** (1) `#bigmark` sits 15px right of everything it should align with — client-space rects fed to a fixed element whose containing block is inset by scrollbar-gutter; subtract the ICB offset once or position it inside `.opening`. (2) The footer paints opaque `--paper` over the site-wide texture, a visible boundary; `background:none` fixes it. (3) Index has no KEYBOARD path home — the hidden markslot is out of the tab order and bigmark is an aria-hidden div; keep markslot in flow at opacity 0 or make bigmark a focusable link. (4) LOW: no print rules (tape labels vanish on print); blocked-tape label 1.35:1 readability; utility pages 404 on favicon; six art files eager-loading without width/height attributes.
**Why:** Blind cp73-74 proof-check verdict FAIL on separate HIGHs; these do not block but must not evaporate.
**Estimate:** ~1 hour total, mechanical.
**How to start:** `WEBSITE/BUILD/src/js/scroll.js:113`, `css/site.css:431`, `index.html:26`.
**Acceptance:** mark centred equal on all five pages; texture continuous through the footer; Tab reaches a home link on index; print sane; no favicon 404s.

## [Open] — 2026-08-28 — N2F begin-wave proof-check MEDIUM/LOW findings (non-blocking, filed per gate)
**What:** (1) form data goes nowhere: no name attrs, no action, answers discarded on navigating to payment — carry as params when payment page lands. (2) `/payment` root-absolute href breaks under file:// and subpaths. (3) invisible burger is tabbable on all five pages (opacity:0 but focusable) — visibility:hidden when inline nav shown. (4) calendar grid AT semantics ragged (aria-hidden fillers make uneven rows) — drop aria-hidden, keep aria-disabled. (5) blocked completion label 1.36:1 — darken to ink. (6) past-day numerals 1.86:1, landing month reads blank — raise alpha ~.55. (7) no "question N of 8" for assistive tech — visually-hidden polite counter. (8) cache-bust split cp74 vs cp80 across pages — one token. LOWs: wobble repeats per column (nth-child restarts in display:contents rows), coalescing discards clicks beyond one (17s to reach +12 months), dead radio-era refs in picker.js:87/91, month NAME never renders (only 08/2026 twice), no print styles. SUPERSEDED by cp85: the video-crop/registration finding (the video turn is dead; stop-motion replaces it). RESOLVED as current-ruling: vermilion tape vs cp72's "black box" wording — cp73 restyled all black buttons to red tape, vermilion governs.
**Why:** Blind begin-wave proof-check verdict FAIL on two HIGHs (no-JS resilience); these do not block but are real.
**Estimate:** 2-3 hours across a batch ticket.
**How to start:** `WEBSITE/BUILD/src/pages/begin.html:286,323`, `js/picker.js:87-91,191`, `css/site.css:929`, `css/picker.css:181`.
**Acceptance:** every item verified by re-measurement; the two contrast numbers past floor; one cache token everywhere.

## [Open] — 2026-08-28 — N2F gate re-run MEDIUM/LOW findings (non-blocking, filed per gate)
**What:** (1) the aria-hidden fallback table is a live copy-gate hole not documented in render_exclusions.txt — add the .cal-fallback skip note with date and reason (the ledger of holes must stay complete). (2) LOW: no-JS screen-reader users get zero calendar and an unexplained disabled control — a noscript line naming the JavaScript need. (3) LOW: visible boot flash on slow connections as the fallback table swaps to the live sheet (~400ms window) — acceptable progressive enhancement or inline the boot.
**Why:** Gate re-run verdict FAIL on two new HIGHs; these ride behind them.
**Estimate:** 30 min inside the same fix wave.
**How to start:** `WEBSITE/BUILD/qa/render_exclusions.txt`, `src/pages/begin.html:341`.
**Acceptance:** the exclusions ledger names every live hole; noscript line present; boot seam judged.

## [Open] — 2026-08-29 — N2F TOP-SEVERITY open defects (the CRITICAL/HIGH set, previously only in HANDOFF.md)
**What:** (1) **cp69 typography criticals, oldest open item.** The widow/orphan rule still breaches at 8 of 129 swept widths including real phone widths 430 and 360 (final line is the lone word "you."); `text-wrap:balance` is INERT for every JS-on visitor because the word spans are `display:inline-block`, while `site.css:569` credits it as working (applied `:574`, defeated `:649`). Riding with them: the weak-word list is 21 words (`js/scroll.js:54`) against the canonical 97-word house list in `OFFLIMITS/system/design-v2/offlimits-deck-system.js`, and the doctrine's comma clause (no line ends on the word after a comma) is unimplemented. (2) **Pressing Back destroys the entire booking** — zero localStorage/sessionStorage in begin.js/picker.js/begin.html, so any navigation away wipes every answer plus the chosen date; the cruellest finding of the cold read, hit by anyone fixing a typo before paying. (3) `#f-addr` is `type="text"` where an email is needed and accepts a postal address silently. (4) Long answers scroll out of view while typing; flicking back jumps the page and stacks answers out of order.
**Why:** Surfaced by three gates on 2026-08-26/27/28 and by the cold-read journey review. The three earlier N2F backlog entries are scoped MEDIUM/LOW by their own wording, so these top-severity items had no home outside the project handoff — caught by the blind verify of the 2026-08-29 handoff save.
**Estimate:** half a day for the set.
**How to start:** `WEBSITE/BUILD/src/js/scroll.js:54`, `css/site.css:569`, `js/begin.js` (persistence), `pages/begin.html` (#f-addr).
**Acceptance:** widow rule holds across a full width sweep with the 97-word list and the comma clause; a reload or Back keeps every answer and the date; the address field validates as an email.

## [Open] — 2026-08-30 — N2F cp100 proof-check MEDIUM/LOW findings (non-blocking, filed per gate)
**What:** (1) **The CSS comment lies.** `css/site.css:179` claims the 1.9x relief "stays exactly --paper"; measured over 812,791 non-ink pixels the rendered ground is `(221.6,217.6,198.2)` against `--paper` `(229,225,205)` — 12.5 euclid off, because the texture's mean is 249.5/255 not 255. Every contrast pairing recorded in the cp77 block (`site.css:110-135`) is now stale (body 8.78→8.24, `.cue` 5.75→5.39, hero 10.93→10.26 — all still pass AA; `.cue` dips to 4.23:1 only in the 1st-percentile grain trough). Fix: normalise the texture mean to 255, or move `--paper` to what the composite actually produces (~`#DDD9C6`). (2) **On any dark backdrop every illustration renders solid black** — multiply(x,black)=black; measured 86.7% pure black with an injected black body. Hits Windows High Contrast dark, Dark Reader, user stylesheets; light HCM is fine (Chromium forces a white canvas). Fix: `@media (forced-colors:active){...{mix-blend-mode:normal}}`. (3) **641–860px the hero is ~57% cropped away** — the `<source>` portrait rendition stops at 640 but the tall box continues; measured at 700px both blossom clusters fall outside the frame. PRE-EXISTING (identical in the pre-land backup), and cp100 makes it look *less* broken. Fix: extend the source to `(max-width:900px)`. LOWs: `site.css:186` fetches `paper_relief.webp` with NO cache token — the one asset this checkpoint replaced is the only one unbusted, and `site.css:1162` still carries `?v=cp80`; 5 of 6 pages 404 on favicon; ~5MB dead assets in root (`assets/art2/` 2.4MB, `assets/art/` 2.3MB, `paper_grain.jpg`, `footer_plaster.jpg`) all reachable over HTTP; `site.css:1084` `#vow .zone img{mask-image:none}` is now dead code and the file's only surviving mask declaration; no image carries width/height or lazy loading; low-frequency page-tone blotching is ~10x the old ground (7.2 levels vs 0.75) — cosmetic but a real change of character.
**Why:** Blind Opus proof-check on the cp100 landing returned FAIL on three separate HIGHs; these ride behind them and must not evaporate. The MEDIUM-1 comment claim is a Lesson-26 failure embedded in a durable artefact — a future reader would trust it.
**Estimate:** ~2 hours for the set, all mechanical except the --paper decision which is an operator call.
**How to start:** `WEBSITE/BUILD/src/css/site.css:179` (the false claim), `:186` (missing token), `:110-135` (stale contrast table), `index.html:74` (the 640 breakpoint).
**Acceptance:** the comment states the measured value or the texture is normalised; contrast table recomputed against the real ground; forced-colors carve-out present; hero source extended and re-measured at 700px.

## [Open] — 2026-08-30 — N2F: review coverage gaps the cp100 proof-check could NOT close
**What:** The blind review named these itself: never rendered at devicePixelRatio>=2 (the `@media (min-resolution:2dppx)` texture branch was only simulated by forcing the size at dpr 1 — actual retina resampling untested); never rendered a genuine dark forced-colors theme (Playwright's emulation gives a WHITE canvas, so the dark-theme conclusion is reasoned, not observed); never produced a print PDF (three attempts hung the screenshot backend, one 30-minute stall) so the print finding is reasoned not rendered; Chromium only — no Safari, no Firefox, and the whole design now rests on `mix-blend-mode` + `scrollbar-gutter` + `svh`, which WebKit handles differently; `begin.html` tested only in its initial state, so if any picker step leaves the page shorter than the viewport the ground-band HIGH applies there too; no keyboard/tab-order/screen-reader pass; widths 390–2560 only, not 320; no throttled-network timing and compression not modelled; no rendered before/after pixel diff (the backup is not served, so every before/after claim comes from reading the diff and injecting rules in-browser); only `art1_mobile` was compared crop-for-crop against its predecessor, so a silently different re-derivation of e.g. art4 would not have been caught.
**Why:** Absence of a finding in an uncovered area is not evidence of absence. Recorded so the next gate knows where it is blind rather than inheriting false confidence.
**Estimate:** a Safari/Firefox + retina + print pass is ~1 hour on real devices.
**How to start:** open the six pages on an actual iPhone (Safari, dpr 3) and an actual print preview; step `begin.html` through all 8 picker steps checking document height against viewport at each.
**Acceptance:** each gap either closed with a measurement or consciously accepted on the record.

## [Open] — 2026-08-31 — N2F cp100 re-gate LOW notes (non-blocking, filed per gate)
**What:** (1) On short pages the footer still stops well above the viewport bottom — testimonials at 1024x1366 leaves 224px of empty ground beneath it. The cp100 fix TEXTURES that region so it is no longer a flat slab, but it does not pull the footer down; the layout is unchanged from before cp100. Whether the footer should stick to the bottom on short pages is an unasked design question. (2) Real-device mobile toolbar behaviour is still unobserved: headless has no browser chrome so `lvh == vh` in every test run, and the "no new scroll on phones" conclusion rests on content exceeding 100lvh by 227px+ at 390/428 widths — true by a wide margin, but inferred rather than seen. (3) The re-gate spot-checked only 2 of 8 illustrations' blend, and nothing below 390px or above 1440px width.
**Why:** Gate returned PASS_WITH_NOTES; these are the notes. None block, but (2) is the one that would embarrass us if wrong, and it needs a real phone, not another agent.
**Estimate:** 15 minutes on an actual iPhone.
**How to start:** open all six pages on a real phone, scroll to the bottom of testimonials and payment with the toolbars both shown and retracted, and check for a bare band.
**Acceptance:** the toolbar-retracted case observed on a real device, or consciously accepted on the record.

## [Open] — 2026-08-31 — N2F film gate MEDIUM/LOW findings (non-blocking, filed per gate)
**What:** (1) **Hero scrub cost.** Instrumented: 304 `getImageData` calls / 1267ms of main-thread time across the ~4.4s hero play (≈35fps, not 60). Each `paint()` allocates two fresh 1920x1080 ImageData (16.6MB) → ~2.5GB churn in 4.4s; measured JS heap 241MB. Gated to >=641px, which still catches tablets and low-power laptops. Fix: reuse one ImageData buffer instead of allocating per frame, and/or drop the hero to a lower canvas resolution than its source. (2) **Transform baked once.** `film.js:106` reads `getComputedStyle(img).transform` at `loadedmetadata` only. `.bouquet img{transform:rotate(-22deg)}` applies at min-width:641px ONLY, so resizing a window across 641px leaves the canvas rotated at 390 (measured `matrix(0.927,-0.375,...)` after resize). Fresh loads are correct; only a live resize is wrong. Fix: re-read the transform on resize. LOWs: canvas is appended inside a `<picture>` element (`film.js:98`), which is non-conforming markup; scroll/resize/`seeked` listeners are never removed (`film.js:116-118`, 6 scroll listeners accumulate); the current host (Python SimpleHTTP) answers `Range:` with 200 not 206, so film.js's own stated hard requirement is unmet — it works today only because Chrome buffers whole files, and the blob fallback masks it.
**Why:** Blind Opus gate on the film work returned FAIL on two separate HIGHs; these ride behind them and must not evaporate. The Range point matters at deploy time, not now.
**Estimate:** ~1 hour for the set.
**How to start:** `WEBSITE/BUILD/src/js/film.js:106` (transform), `:116-118` (listeners), the `paint()` function (buffer reuse).
**Acceptance:** hero play measured at <400ms total main-thread time and heap under 100MB; resizing across 641px leaves the bouquet unrotated below it; listeners removed on teardown.

## [Open] — 2026-08-31 — N2F film gate: coverage the reviewer could NOT close
**What:** Chromium only — no Safari, no Firefox, and the whole film system rests on `mix-blend-mode` + canvas + `svh`, which WebKit handles differently. No real-device performance (the 241MB heap / 35fps figures are desktop Chromium under instrumentation). No audio check. Only index.html and pages/packages.html were opened — begin, testimonials, payment and confirmation were not.
**Why:** absence of a finding in an uncovered area is not evidence of absence.
**Estimate:** 30 min on a real iPhone plus a Safari desktop pass.
**How to start:** open index.html and packages.html on a real iPhone (Safari) and watch the hero play; check the scenes scrub.
**Acceptance:** each gap either closed with a measurement or consciously accepted on the record.

## [Open] — 2026-09-02 — Google Cloud spend: 2 decisions still open after the `CLOUD VBHV3N` trace
**What:** A Google charge (card reference `CLOUD VBHV3N`) was traced to billing account **SUNNY**
`01691F-377789-CD02C5`. Of 18 projects only 4 can charge. Two live cost sources were found.
**(1) DONE, no decision needed** — Cloud Run service `flightclub33-v3-demo` (project
`gen-lang-client-0822890649`, us-west1) had `minScale=1`, holding a machine open 24/7 since
2026-06-08. Switched to 0 on 2026-09-02 with operator approval. Reversible switch built at
`scripts/cloudrun-power.sh` (`status` / `on` / `off`); local state + log in `run/cloudrun-state/`
(gitignored, so that folder is NOT backed up — the script is the durable record).
**(2) OPEN — claude-mem is on the Gemini PAID tier.** Its API key was SHA-256 fingerprint-matched to
key `19dbc963-914c-4aeb-95b1-e5180e13cb89` in project `gen-lang-client-0616289156` ("CLAUDE MEM"),
which has billing attached. 12,975 requests in the 30 days to 2026-09-02, and rising
(weekly 1,520 → 2,984 → 3,965 → 4,290). The saved config note claimed "$0/mo"; that is disproven and
the note has been corrected.
**GROUNDING (added same day, after the Step-0 prior-art grep — supersedes the first draft of this
entry):** the paid tier was NOT drift. Decision Log 2026-05-06 `[Sunil · operational]` records the
deliberate flip to paid to clear a 921-observation backlog stuck behind a 20-requests/day free-tier
cap, on an expected cost of **~£1–3/mo**. And reverting to free is DISQUALIFIED, not merely degraded:
Decision Log 2026-08-11/12 records that Google's free tier **trains on submitted data with no opt-out**
and is "Client-IP disqualified"; the OpenRouter `:free` route was rejected on the same privacy ground
on 2026-05-06. claude-mem observations contain raw session content including client work.
**So the live question is volume, not tier: has usage outgrown the £1–3/mo the 2026-05-06 decision
assumed?** Measured split for the week Google counted 4,290 requests — PostToolUse observations
3,747 (~87%), Stop summaries 154 (~3.6%), rest session-init/context/retries. Disabling PostToolUse
alone (the "Layer 2" designed 2026-05-05 and never fired) removes ~87% of spend while keeping
per-turn summaries, SessionStart auto-recall and the paid tier's no-training guarantee.
**(3) OPEN — no budget alert exists** on the SUNNY account, which is why this surfaced as a card
charge rather than a warning.
**Why:** Cost-control doctrine is free-first with an approval gate on any spend. This spend was
never approved because nobody knew it existed. Item (2) grows with Claude Code usage, so it gets
worse on its own. Item (3) is what turns the next occurrence into a notification instead of a bill.
**Estimate:** (2) is a 10-minute decision plus ~5 minutes to apply. (3) is ~10 minutes in the console.
**How to start:** Read `project_google_cloud_bill_trace_2026_09_02.md`. Get the real numbers first at
`https://console.cloud.google.com/billing/01691F-377789-CD02C5/reports` — group by project, then by
service — so the claude-mem decision is made against an actual figure rather than an estimate.
**Acceptance:** the claude-mem billing question ruled on either way and applied; a budget with an
email alert live on the SUNNY account; the next month's charge matches expectation.

**UPDATE 2026-09-02 — items (1) and (2) CLOSED, item (3) still open.**
Console figures (GBP): card charge `CLOUD VBHV3N` = **£20.15** on 1 Sep = August invoice + ~20% VAT.
August total £16.79 — **Gemini/CLAUDE MEM £13.07**, Cloud Run/FLIGHTCLUB33 £3.72. June £14.46,
July £37.40. ai-agent-fleet and BIDFILL-PROD: nil.
Against the 2026-05-06 assumption of ~£1–3/mo, actual is 4–13x over, so volume reduction was applied:
`CLAUDE_MEM_SKIP_TOOLS` in `~/.claude-mem/settings.json` extended 23 → 59 entries, excluding browser
mechanics and media-job polling; Bash/Edit/Write/Agent/generate calls deliberately kept. Worker
restarted and the change **verified live** against its own endpoint (returns `tool_excluded` for the
new names). Paid tier RETAINED — free tier trains on client data.
**STILL OPEN — (3) no budget alert on the SUNNY account.** Also open: re-measure on/after 2026-09-16
against the recorded baseline (12,975 req/30d; 3,813 chargeable observations in the final week;
expected ~42% cut) and, if weekly requests remain above ~3,000, escalate to disabling the PostToolUse
hook. Full method + reproduce commands in `project_google_cloud_bill_trace_2026_09_02.md`.

## [Open] — 2026-09-02 — Review residuals from the 2026-09-02 cost/hook proof-check (non-blocking) + identify the settings.json writer

**What:** Four items surfaced during the 2026-09-02 adversarial review of the code-review-graph install-hooks doctrine fix, filed here as non-blocking. **(1) MEDIUM** — project `.claude/settings.json` hook matcher had dropped `Bash` (contradicts COMMANDER.md Step 0.D "Edit|Write|Bash"); the file was RESTORED to HEAD on 2026-09-02. If the `--repo` path and longer timeout from the rejected rewrite are wanted, re-apply deliberately with an absolute binary path, no `>/dev/null 2>&1 || true` silencing, Bash retained, stderr kept. **(2) MEDIUM** — the rejected rewrite also set a 30-second synchronous hook timeout on every Edit/Write; decide a sane value if it's re-applied. **(3) LOW** — `scripts/cloudrun-power.sh`: the `CLOUDRUN_POWER_STATE_DIR` env override can redirect its backups/log to any path, and there is no locking, so two concurrent runs race. **(4) HIGH-1 residual — RESOLVED 2026-09-02.** The `.claude/settings.json` writer was Sunil's own concurrent Claude Code session (UUID `a41b368c`), which committed the hardened hook as `02910ee` (author verified; its message references the 091c3d4 investigation). Not adversarial — it fixed the review's HIGH-3 (absolute binary path + visible error log). Only residual: matcher still drops `Bash` (see the 2026-09-02 handoff, Open Thread 2). Tripwire `run/settings-tripwire.txt` predates `02910ee` so it no longer matches HEAD — expected.

**Why:** Items (1)-(3) are correctness/safety gaps worth fixing but none are blocking today. Item (4) is the one that matters: an unidentified process rewrote and staged a security-relevant file (the project hooks config) twice with no attributable actor, and until the writer is named, any future settings.json fix could be silently reverted or duplicated by the same mechanism.

**Estimate:** ~1 hour.

**How to start:** (1) Grep the installed `code_review_graph` Python package for EVERY code path that writes a file named settings.json — not just `install_hooks` — search for `settings.json`, `migrate`, `ensure`, `upgrade`, `hooks` in `site-packages/code_review_graph/`. (2) Check `~/.claude/settings.json`'s PostToolUse chain (`trust-gate-post.sh`, `codex-rate-limit-catcher.py`) and `watchdog/hooks/session-end.sh` for any `git add`/`git stage`. (3) If still unknown, run `sudo fs_usage -w -f filesys | grep 'claude-hq/.claude/settings.json'` during a session, or compare the tripwire sha256 after each session.

**Acceptance:** the writer is named with a file:function citation, or the tripwire shows no further change across 5 sessions.
**Addendum (same day) — 3 LOW notes from the blind verifier's PASS_WITH_NOTES on fix commit 091c3d4:**
(5) `cloudrun-power.sh` `cmd_off`/`cmd_on`: if the update succeeds but the read-back `current_min` fails, the script says "did not take" — it should say "could not confirm", since the change may have landed (exit 1 and no-log are still the safe choices; only the wording over-claims). (6) `cmd_status` exits 0 even when every service reads `unknown`; any caller gating on its exit code cannot detect a total blackout. (7) pre-existing: backup filename has minute granularity, so two `off` runs in one minute overwrite the first backup. Also `nick` is still a global in `cmd_list`/`cmd_status` (only `lookup` was ticketed).

## [Open] — 2026-09-02 — crg hook: two accepted LOW residuals from proof-check PASS

**What:** (1) PostToolUse matcher is now `Edit|Write|MultiEdit` — file edits made via Bash (heredocs, sed, git pull) no longer refresh the code-review-graph until the next Edit/Write; round-1 reviewer suggested a SessionStart catch-up (`update --base origin/main`) to close the git-pull gap. (2) SessionStart `status` entry lacks `--repo` — started outside claude-hq it resolves whatever cwd graph it finds; add `--repo` for symmetry.
**Why:** Both accepted knowingly at the 2026-09-02 landing of the corrected hooks (proof-check PASS, real-surface proven 0.58s in env -i). Low frequency, low harm, but permanent-staleness shaped (git pull past HEAD~1 never gets picked up).
**Estimate:** 15 min including one proof-check re-run.
**How to start:** edit `.claude/settings.json` SessionStart entry: add `--repo /Users/sunil_rajput/claude-hq` and optionally a second SessionStart hook `update --base origin/main --skip-flows` (absolute binary path, stderr to ~/.claude/logs/crg-hook.err, timeout 60).
**Acceptance:** after a `git pull` advancing HEAD by 2+ commits, next session start refreshes the graph (status Last-updated advances) with no manual build.

## [Open] — 2026-09-04 — Hermes pilot S3 proof-check residuals (8 MEDIUM / 6 LOW)
**What:** From `run/pilot-tree/skills/hq-hermes/reviews/proof-check-s3-2026-09-04.md` (gate CLOSED on 1 CRITICAL / 3 HIGH, fixed by T8b). MEDIUM: (1) `ollama-bench.py` PASS on zero samples → `samples_taken`/`sampler_error` + ERROR status; (2) engine override fence checks the directory only — require a regular non-symlink file; (3) `approvals.deny` fails open on exception + fnmatch misses absolute/compound commands; (4) `title_generation`/`background_review` readers fail open → T12 positive control; (5) `config-keys.py` type/value-blind (`"false"` string is truthy for `secrets.command.enabled`; `hooks: []` list) → audit `key=type(value)`; (6) `render-config.sh groq` writes a tracked file and never installs → T10 renders to `$HH/config.yaml` with an explicit model; (7) memory gate never measured the 65536 operating point → one load-only `ollama ps` after a 1-token request; (8) mounts: workdir NOT mounted (`docker_mount_cwd_to_workspace` False), three implicit ro mounts, root in container, `docker_persist_across_processes` True, and **`HERMES_WRITE_SAFE_ROOT` unset → no in-process file fence** → T12 sets it + explicit workdir mount + `docker_persist_across_processes: false`; PLAN §1.2 wording. LOW: temp-home cleanup in `test_fence.py`; `.block` temp outside the trap; `chmod || true`; `hermes-secrets.sh` masks keychain faults and omits `-a`; `rss_info_only` self-inflated; PATH-resolved `docker`/`curl` in the engine script.
**Acceptance:** each MEDIUM either closed in T9–T12 (cite the ticket) or accepted in the risk register with a reason; LOWs closed opportunistically.

## [Open] — 2026-09-04 — Hermes pilot S3 proof-check RE-RUN residuals (2 MEDIUM / 3 LOW)
**What:** From `run/pilot-tree/skills/hq-hermes/reviews/proof-check-s3-rerun-2026-09-04.md`. M-a renderer `TEMPLATE=`/`HERMES_HOME` env inputs uncontained + thin self-check → closed in T8c; M-b upstream `check_config_version()` says "up to date" for a corrupt file → T12 pre-flight parses the file itself; L-a trailing-slash `-L` gap → T8c; L-b hardlink under `$SK` (informational); L-c LKG-ordering test → T8c.
**Acceptance:** T8c closes M-a, L-a, L-c (cite the commit); M-b covered by the T12 pre-flight; L-b accepted in the risk register.
