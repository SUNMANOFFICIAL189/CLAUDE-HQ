# LESSONS — Global Self-Improvement Log

> After ANY correction from the user, add a preventive rule here.
> Review this file at the start of every engagement.
> Rules should prevent mistakes, not just describe them.

---

## Rules

### 1. Never install external code without the Trust Gate
- **Rule:** Every `git clone`, `npm install`, `pip install`, `pipx install`,
  `cargo install --git`, and `npx skills add` passes through the Trust Gate
  (Tier B ambient hook + Tier C full pipeline for skills.sh).
- **Why:** Snyk Feb 2026 audit — 13.4% of skills.sh + ClawHub skills have
  critical issues (malware, prompt injection, secrets). Skill-based prompt
  injection succeeds 95.1% of the time vs 10.9% direct. The ecosystem is
  actively hostile.
- **How to apply:** The PreToolUse hook at `scripts/trust-gate.sh` is
  ambient — do not edit it away. For skill discovery, always use `/scout`,
  never `npx skills add` directly.

### 2. Install counts are a weak signal, not proof
- **Rule:** A skill with 1M installs is no more trustworthy than one with 100.
  Reputation is a tie-breaker when other layers pass, never an auto-pass.
- **Why:** Snyk data shows issue prevalence is roughly flat across install
  counts. The `find-skills` skill itself (1.1M installs) is published by
  vercel-labs — whose cooling-off has since expired (2026-07-20), but which
  remains off the allowlist and so still takes the full Tier C pipeline.
- **How to apply:** Trust Gate Layer 4 (reputation) runs AFTER Layers 0.5-3
  and only affects the auto-pass vs manual-review decision.

### 3. Allowlists decay — cooling-off overrides trust
- **Rule:** Any author/vendor with a publicly disclosed security incident in
  the last 90 days is demoted from allowlist to full Tier C scrutiny until
  90 days post-incident + published post-mortem + verified supply chain.
- **Why:** Vercel 2026-04-19 — compromised via a third-party AI tool
  (Context.ai) breaching an employee's Google Workspace. "We believe the
  supply chain is safe" is not "we have verified every artefact."
- **How to apply:** `commander/INCIDENT_LEDGER.md` holds active cooling-off.
  The advisory layer checks this BEFORE the allowlist — cooling-off wins.

### 4. Security-research skills will trigger Layer 2 false positives
- **Rule:** Skills authored by security research firms (trailofbits, snyk,
  lakera, etc.) will match prompt-injection/secret regex patterns because
  their documentation discusses the very patterns they're designed to detect.
  Treat Layer 2 FAIL from an allowlisted security author as manual-review
  required, not auto-block.
- **Why:** Shakedown 2026-04-21 on `trailofbits/skills` — flagged by Layer 2
  for YARA jailbreak detection docs, Firebase vulnerability research docs,
  Python sharp-edges notes (`subprocess shell=True` documented as DON'T).
  All legitimate security research content.
- **How to apply:** For allowlisted security research authors, review the
  specific file paths flagged. If all hits are in `references/` or `docs/`
  directories discussing patterns educationally, override with
  `HQ_TRUST_OVERRIDE=1`. Never auto-override for non-allowlisted authors.

### 5. Always query skills.sh before authoring a new skill
- **Rule:** Before building a new skill or slash command, run `/scout <task>`
  to check if the capability already exists in the ecosystem.
- **Why:** The ecosystem has ~91K skills. Most common needs are covered.
  Authoring duplicates wastes time and creates maintenance burden.
- **How to apply:** In Commander Step 2.5, skills.sh fallback runs after
  registry and Agent Bank scan. Only build new skills when `/scout` returns
  no adequate match (or all matches are low-reputation / in cooling-off).

### 6. Postinstall scripts run before hooks can stop them
- **Rule:** Our PreToolUse hook runs BEFORE the command, but `npm install`
  and `pip install` execute postinstall scripts AS PART OF the install, not
  after. PostToolUse scanning is retrospective for these.
- **Why:** Structural limitation of how package managers work — the hook
  cannot split install-time execution.
- **How to apply:** For npm/pip installs from unknown authors, prefer
  `--ignore-scripts` flag when available. For unknown authors, clone first
  (Tier B gated), scan with Tier C tools manually, then install.

### 7. Parse `git clone` with a tokeniser, not a single regex
- **Rule:** Never use a one-shot bash regex to extract the URL from a
  `git clone` command line. Use `shlex` (or equivalent) to tokenise, then
  walk the tokens skipping flags-with-values (`--branch NAME`, `--depth N`,
  `-b NAME`, etc.).
- **Why:** 2026-04-21 PATS-Copy relay-push incident — the original regex
  `(--[a-z-]+[[:space:]]+)*([^[:space:]]+)` only consumed `--flag ` (no
  value), so `git clone --branch strategy/hybrid-v1 root@SERVER:/path`
  mis-identified `strategy/hybrid-v1` as the URL. `extract_owner` then
  returned `strategy` and the whole clone was blocked as UNKNOWN. The
  actual server URL was never inspected. `trust-gate.sh` now uses a Python
  shlex parser with an explicit `FLAGS_WITH_VAL` set.
- **How to apply:** Any future change to install-command parsing must
  tokenise first. Add new flags-with-values to `FLAGS_WITH_VAL` in
  `trust-gate.sh:parse_git_clone_url`.

### 8. `HQ_TRUST_OVERRIDE=1` inline prefix is parsed from the command string
- **Rule:** PreToolUse hooks cannot see env vars set on the command line
  (the hook runs before the command executes, so the assignment never
  reaches a child process). Inline `HQ_TRUST_OVERRIDE=1` is detected by
  pattern-matching the command string itself, not by reading the
  environment.
- **Why:** Same 2026-04-21 incident — user retried with
  `HQ_TRUST_OVERRIDE=1 bash -c '...'` and the override was silently
  ignored because the hook only checked `${HQ_TRUST_OVERRIDE:-0}` from
  its own env. Two paths now: (a) string-detection in the command, or
  (b) `export HQ_TRUST_OVERRIDE=1` in the shell before launching Claude.
- **How to apply:** When documenting override mechanics, always explain
  both paths. Don't tell users to "prefix" without noting that it's a
  string-pattern detection, not a real env-var pass-through.

### 9. Self-hosted infra needs a separate allowlist from the author allowlist
- **Rule:** `SUNMANOFFICIAL189` (GitHub username) and `204.168.204.247`
  (server IP) are both operator-owned but belong in different lists.
  Author allowlist is for GitHub owners. Self-hosted is for hosts/IPs
  extracted from SCP-style (`user@host:/path`) and non-GitHub URL clones.
  Do not conflate them.
- **Why:** Extending the author allowlist to include IPs would make
  `extract_owner` confused about whether `192.168.x.x` is a dotted owner
  name or an IP. Separate list, separate matcher.
- **How to apply:** Add new servers to `SELF_HOSTED=(…)` in
  `advisory-check.sh`. Match runs after cooling-off, before author
  allowlist. Post-clone Magika + secret-scan still execute — this is
  defence-in-depth, not blind trust.

### 10. Verify backup BEFORE consolidating to a single canonical home
- **Rule:** Never untrack, delete, or "centralise" to one location without
  first confirming that location is itself backed up. If you're about to
  say "X is now the single source of truth," verify that X has its own
  backup before taking the consolidation step.
- **Why:** 2026-04-21 — removed `graphify-out/` from claude-hq tracking,
  declaring the Obsidian vault the canonical knowledge-graph home.
  Vault had NO backup (no iCloud, no Obsidian Sync, no Time Machine, no
  git). Sunil caught it in the next message. One disk failure and the
  entire vault would have been lost. The consolidation was correct in
  principle but premature in sequence.
- **How to apply:** Before any `.gitignore` addition that removes a
  previously-tracked artefact, or any "canonical home" declaration,
  explicitly audit the new home's backup: iCloud / git remote / cloud
  sync / Time Machine. If none, set one up FIRST, then consolidate.

### 11. Don't invent vault taxonomy — extend what exists
- **Rule:** Before proposing a new top-level folder or structure in the
  Obsidian vault, check what conventions already exist. Extend those;
  don't invent parallel hierarchies.
- **Why:** 2026-04-21 — proposed moving `claude-hq` out of `Projects/`
  and into a new `System/` folder to reflect infrastructure vs project
  distinction. Sunil correctly pushed back: `System/` did not exist in
  the vault, PATS-Copy already sat in `Projects/`, and inventing a new
  tree fragmented the taxonomy for a purely semantic reason. Resolution:
  keep in `Projects/`, differentiate via file naming convention
  (descriptive vs numbered) instead.
- **How to apply:** When unsure whether to add a new vault folder, ask
  "does this map to a convention already used for another project?"
  If yes, extend. If no, the right fix is usually a file-naming tweak
  or a sub-folder, not a new top-level.

### 12. Duplicating source in vault violates "no duplicates" even when framed as a summary
- **Rule:** If you find yourself writing a vault-native file whose header
  says "mirrors X" or "summary of X" where X is a source-controlled
  file, stop. Use a symlink to X instead, or just wikilink from the Hub.
  A summary copy always drifts from source.
- **Why:** 2026-04-21 — created `05 Lessons Learned.md` in the vault as
  a "summary" of `~/claude-hq/commander/LESSONS.md`, then 20 minutes later
  wrote the anti-duplication rule in `docs/ORGANIZATION.md`. The same
  session. Sunil caught the contradiction. Resolution: delete the
  duplicate, symlink `Commander/` → `~/claude-hq/commander/` so all
  source files (LESSONS, TRUST_GATE, etc.) surface in Obsidian without
  copies.
- **How to apply:** If a file's justification is "easier to browse" —
  use a symlink. If the justification is "summarise for Obsidian" —
  don't; the source is already markdown and Obsidian-native. Write a
  wikilink from the Hub pointing at the source.

### 13. `.gitignore` patterns with `/` are anchored to the gitignore's location
- **Rule:** In a multi-level repo (where the `.gitignore` sits above
  the actual content dir), patterns like `.obsidian/workspace.json`
  will NOT match `<subdir>/.obsidian/workspace.json`. Use `**/` prefix:
  `**/.obsidian/workspace.json`.
- **Why:** 2026-04-21 — created `jarvis-brain` repo with `.gitignore`
  at `~/Vaults/Jarvis-Brain/` and vault content at
  `~/Vaults/Jarvis-Brain/JARVIS-BRAIN/`. Initial commit accidentally
  tracked `JARVIS-BRAIN/.obsidian/workspace.json` because the pattern
  without `**/` was interpreted relative to the repo root only.
- **How to apply:** If your repo root is one level above the actual
  content, prefix subdirectory-anchored patterns with `**/`. Test:
  `git check-ignore -v <file>` should report the matching pattern.

### 14. Plaintext-secret config files are landmines — read them only via redirected tools
- **Rule:** If a file is known to contain plaintext secrets (`claude_desktop_config.json`,
  `.env`, credentials registries), never surface its contents directly through the `Read`
  tool. Route secrets via scripts that touch them in-memory only and write to a secure
  store (macOS Keychain, a gitignored mode-600 file). If a `Read` is unavoidable for
  structural inspection, pair it with an immediate scrub + acknowledge the secondary
  leak into session transcripts and claude-mem.
- **Why:** 2026-04-21 → 2026-04-22 — reading `claude_desktop_config.json` to diagnose
  why the Reddit MCP wasn't available surfaced 4 live secrets (Anthropic, Gemini,
  GitHub, Reddit client secret) into tool output, which flowed into claude-mem
  observations (1 row) and 8 local session transcripts before we caught it. Sunil
  opted against rotation, so we migrated to Keychain + launchers + session-end
  scrubber. The local leak was fully scrubbable; the Anthropic-backend leak is not.
- **How to apply:** When an MCP/credential question forces config inspection, prefer
  `security find-generic-password`, `env | grep`, or a helper script that reads the
  config, stores in Keychain, and rewrites the file — all in one pass with no stdout
  echo of values. The one-pass migration script is at
  `~/claude-hq/scripts/mcp-migrate-to-keychain.sh`. Session-end scrubber is at
  `~/claude-hq/scripts/lib/secret-scrub.sh`. Both are idempotent.

### 15. macOS Keychain + launcher scripts is the right home for MCP secrets
- **Rule:** Any MCP that needs an API key, token, or client secret must be launched
  via a script in `~/claude-hq/scripts/mcp-launchers/` that fetches the secret from
  Keychain at spawn time. The Claude Desktop config references the launcher path;
  the config's `env: {}` block stays empty (or contains only public identifiers like
  OAuth client IDs).
- **Why:** Desktop config sits at a known path, is world-readable by anything with
  your user permissions, and gets read by skills/agents for diagnostics. Keychain
  entries are encrypted at rest and require your login. Launchers keep the spawn
  command short and the config clean.
- **How to apply:** New MCP with a secret → (1) `security add-generic-password -U -a "$USER" -s "claude-mcp-<name>" -w <value>`; (2) copy an existing launcher from `~/claude-hq/scripts/mcp-launchers/`, adapt the service name and exec line; (3) update `claude_desktop_config.json` to point to the launcher with `env: {}`; (4) restart Claude Desktop.

### 16. All user-facing alerts must be in plain English — no jargon, ever
- **Rule:** Any system built under the HQ umbrella that sends messages to
  Sunil (Telegram, email, push, SMS, anything) MUST describe what happened
  and what to do in natural language a non-technical reader can understand
  at a glance. Technical detail stays in logs, SQLite, or audit files —
  it never reaches the phone. This applies to every alerting system, not
  just Watchdog.
- **Why:** 2026-04-24 — while building the HQ Watchdog, Sunil explicitly
  asked to hardwire this constraint because technical alerts force a
  context switch: read jargon → decode it → figure out what to do. That
  defeats the point of an alert. The Polymarket Telegram pipe already
  follows this pattern (short, readable status messages). HQ alerts must
  match. Without code-level enforcement, every alert author (human or
  agent) will slowly drift toward technical shorthand.
- **How to apply:** When any new alerting path is built:
  1. Every outgoing message goes through a `PlainAlert` (or equivalent)
     with two REQUIRED fields: `what_happened` (plain English) and
     `what_to_do` (one concrete action).
  2. A jargon-linter must block banned words at construction time —
     `threshold`, `regression`, `baseline`, `delta`, `rolling`, `stdev`,
     `p-value`, `FP/TP`, unit shorthand (`7d`, `24h`), raw metric IDs, etc.
  3. Metric definitions (yaml/json) must carry a `plain_language` block
     with `what_it_means`, `why_it_matters`, `alert_template`. No metric
     loads without it.
  4. The template enforces the three-part shape: emoji headline →
     what happened (1-3 plain sentences) → one clear "What to do: …".
  5. Reference implementation lives at `~/claude-hq/watchdog/telegram.py`
     (`PlainAlert` dataclass) and `watchdog/STYLE_GUIDE.md` (banned-word
     list + template examples). Copy this pattern when building the next
     alerting system.

### 17. When prebuilt automation matches a task, propose — never auto-invoke without explicit approval
- **Rule:** When any system (current or future workflow library,
  slash-command pipeline, recipe matcher, automated retry loop, scheduled
  action) detects that a task matches a prebuilt multi-step automation,
  surface the match as a *proposal* and wait for explicit user confirmation
  before invoking it. Do not silently run the automation as part of plan
  execution. Default is always propose-and-confirm.
- **Why:** 2026-04-24 — during the Goose recipes pilot, three paths
  were on the table for automating `/rpi-*` dispatch: (A) full auto
  (Commander picks + runs), (B) suggest and confirm, (C) merge into
  Commander's default protocol. Path A was rejected because automatic
  invocation destroys measurement integrity (no control group, can't
  score "with recipe vs without"); Path C was premature (we hadn't
  proven the mechanism beat the existing protocol). Path B was the
  right shape regardless of whether the specific recipes earned their
  keep — the principle outlives the specific case. The RPI mechanism
  itself was dropped 2026-05-06 (zero invocations in 12 days, see
  Rule 20), but this rule is retained because it generalises to any
  future automation library.
- **How to apply:**
  1. Any code path that detects a task-to-automation match must surface
     the match as a proposal with the matched trigger phrase shown.
  2. Wait for explicit user confirmation before invoking. If multiple
     matches tie, surface all of them — never silently pick.
  3. Auto-invoke is allowed only when the user has explicitly opted into
     auto-mode for a specific named automation (rare; not the default).
  4. Applies forward to automation systems we haven't built yet —
     security-audit pipelines, full-stack-initializer recipes, clean-up
     workflows, scheduled bots. The default is always propose-and-confirm.

### 18. "Note this for later" → ALWAYS go to `docs/BACKLOG.md`
- **Rule:** Whenever the user signals that something should be tracked for
  future work — phrases like "note this down for later", "make sure we
  revisit this", "park this", "add to the backlog", "track this so we
  don't forget", "we should come back to this", "save this for future" —
  ALWAYS append the item to `~/claude-hq/docs/BACKLOG.md` using the
  established format. Do not invent a new tracking location. Do not store
  only in TaskCreate (session-scoped, lost at session end). Do not store
  only in memory notes (those are about how I behave, not what work is
  pending).
- **Why:** 2026-05-06 — during the multi-model routing build I proposed
  creating a new `commander/BACKLOG.md` file before checking what already
  existed. The user (rightly) pointed out we already had
  `docs/BACKLOG.md` (created 2026-04-22). Drift here means parked work
  accumulates in fragmented locations: some in TaskCreate (gone next
  session), some in memory notes, some in Watchdog reminders, some in
  Decision Log entries. Audit trail vanishes. The point of BACKLOG.md is
  to be the single durable register so "we should come back to X" can
  always be looked up later.
- **How to apply:**
  1. Recognise the trigger phrases above (and obvious equivalents).
  2. Read the current `docs/BACKLOG.md` to match the established format:
     `## [Open] — YYYY-MM-DD — <title>` with What / Why / Estimate /
     How to start / Acceptance fields. Each field non-empty.
  3. Append to BACKLOG.md (do not insert mid-file — chronological order
     by entry date). Items already there stay where they are; entries
     are status-flipped (`[Open]` → `[In progress]` → `[Done]`), never
     deleted.
  4. Commit the BACKLOG addition. Standalone commit if not part of any
     other work-in-progress; folded into the relevant commit if it is.
  5. Confirm in chat: "Tracked in BACKLOG.md as item N — revisit when X."
  6. Time-triggered reminders (cron-style "fire on date Y") still go to
     `watchdog/reminders.json`. BACKLOG.md is the always-on register;
     reminders.json is the alarm. Use both when both apply.
  7. If the deferral involves an architectural decision the user already
     made today (not just a "do later"), ALSO append a Decision Log
     entry in the Obsidian vault with provenance tag — but BACKLOG.md
     is still the source of truth for the work itself.

### 19. Mid-complexity tasks get a brief plan-aloud before the first edit
- **Rule:** Before the first Edit/Write/Bash that mutates code or files
  on a task that touches 3+ files, OR explores a codebase area I haven't
  read this session, OR is bigger than a single-line fix, include a
  short "Plan:" block in the response: which files I expect to change,
  in what order, what I'm uncertain about. 3-5 lines, no ceremony.
  The user can correct the plan before any code is written.
- **Why:** 2026-05-06 — the Goose recipes pilot shipped four `/rpi-*`
  slash commands (research → plan → implement → iterate) on
  2026-04-24 to enforce exactly this discipline. Twelve days later,
  zero invocations. Three reasons: (a) the slash commands were
  project-scoped to claude-hq cwd, invisible everywhere else; (b)
  Commander's Step 2-6 already covers the same shape for orchestrated
  work; (c) for non-orchestrated medium-complexity work, the user
  reaches for conversation, not a slash command. The discipline that
  RPI tried to enforce — research-then-plan-then-implement — is real
  and valuable, but it's behaviour not infrastructure. Encoding it as
  a Lesson means it lives in how I respond, not in tooling that
  requires the user to remember another command.
- **How to apply:**
  1. Trigger conditions (any one is enough): touches 3+ files / explores
     an unfamiliar codebase area this session / non-trivial logic change
     / a refactor / changes to shared infra (hooks, scripts that fire
     across projects).
  2. The plan-aloud goes in the assistant text BEFORE the first
     mutating tool call. Format: "Plan: <files I'll touch and order>.
     <Anything I'm uncertain about>." Three to five lines is plenty;
     more than that means the work probably warrants Commander's full
     Step 4 mission board instead.
  3. For trivial work (one-line fixes, typo fixes, single-file edits I
     understand fully), skip — ceremony for ceremony's sake is its own
     anti-pattern.
  4. If the user pushes back on the plan, re-plan; never code through
     a disagreement.

### 20. Pilots without deadlines and measurement are vibes, not experiments
- **Rule:** Any time we adopt a new tool, pattern, slash command,
  recipe, agent, or framework "to see if it helps", the adoption must
  ship with three things: (a) a hard deadline (e.g. 14 days), (b) a
  measurable adoption signal (file existence, command-usage count,
  watchdog metric, observable artefact), (c) a default action when
  the deadline arrives if the signal is null. Without all three, it's
  not a pilot — it's pre-emptive infrastructure debt that accumulates
  silently because nobody owns the kill decision.
- **Why:** 2026-05-06 — the 2026-04-24 Goose recipes pilot promised
  "use one of the RPI commands on a small real task in the next week"
  and "the watchdog will score Goose's impact on HQ metrics over the
  next weeks." Twelve days later: zero RPI invocations, no `recipe_*`
  watchdog metric was ever built, no kill-or-keep deadline, no
  default action. The pilot ran in name only. The retrospective
  conversation that surfaced this was 30+ minutes of due-diligence
  that should have been impossible — a real pilot would have produced
  its own verdict by deadline. The cost of un-instrumented adoption is
  cognitive load, branch staleness, and ambient feeling of "we have
  X" while X is dormant.
- **How to apply:**
  1. When proposing any new tool/pattern, the proposal must include
     deadline + signal + default action in the same message. If it
     doesn't, the proposal is incomplete — refuse to ship the change.
  2. The signal must be checkable in seconds without me re-deriving
     it. File existence, line count, sqlite query, slash-command
     invocation grep — concrete and fast.
  3. Default action options: drop / globalise / promote / extend.
     Pick one. "Reassess" is not a default action; it's the same
     un-instrumented loop again.
  4. The watchdog is the natural home for adoption signals. If a
     pilot's signal can be expressed as a metric, add it to
     `watchdog/metrics.yaml` at adoption time, not "later."
  5. Lesson 17 (propose-don't-auto-invoke) and this rule are
     complementary: 17 governs how automation gets *triggered*, 20
     governs how its *effectiveness* gets measured. A propose-only
     mechanism with no measurement is half a system.

### 21. Probe memory at every task start — RAG retrieval of patterns, not continuation
- **Rule:** At the start of every task in HQ mode (gate disabled — see
  §"HQ vs non-HQ" below), run
  `~/claude-hq/scripts/memory-probe.sh "<task keywords>"` to sweep all
  memory banks for **transferable patterns, templates, and principles**
  that could apply. The framing is RAG — past work is the corpus, the
  task is the query, retrieved patterns are *ingredients* for the new
  plan. NOT "did we do this exact thing before" but "what tools /
  templates / principles do we already have that fit this shape?"
  Surface relevant hits to the user with action-oriented framing
  ("Reusable pattern found — recommend X") *before* starting fresh
  analysis.
- **Why:** 2026-05-08 — Sunil pointed out that the second-brain stack
  (claude-mem, MemPalace, Obsidian, Hindsight) was built precisely so
  accumulated knowledge could be retrieved efficiently — but only the
  small distilled tier (MEMORY.md index, claude-mem live context,
  LESSONS) was auto-loading. The big banks (MemPalace's 49,130 drawers,
  full Decision Log, full BACKLOG, all of `commander/`, scripts index,
  registries, mission boards) sat unqueried unless I happened to think
  to check, which means most accumulated knowledge was effectively
  *dead capital*. Worse: the framing was wrong — I was probing for
  "continuation" (did we do this exact thing) when the higher-leverage
  use is RAG retrieval of *transferable patterns* (what templates
  apply here). Token math: a probe costs ~5,000 tokens end-to-end; re-
  deriving an architectural decision or rebuilding a pattern from
  scratch when a working template exists costs 20,000–80,000 tokens
  plus quality risk from missed prior lessons. Even a 1-in-5 useful-
  hit rate pays for itself.
- **How to apply:**
  1. **HQ vs non-HQ (the gate):** Inside HQ mode (Commander activated
     for the session), probe fires on *every* first task message after
     activation — no triviality gate. Cost (~5k tokens) is small
     compared to the value of never missing a transferable pattern.
     Outside HQ mode (e.g., a one-shot fresh session in a different
     cwd), the gate applies: skip on trivial questions, factual
     lookups, continuation prompts, or when full context is already in
     conversation.
  2. **Execution:** extract 3-5 distinctive keywords from the task
     (avoid generic words like "build", "fix"). Run
     `~/claude-hq/scripts/memory-probe.sh "<keywords>"`. Skim the output
     by trust hierarchy (see §3 below). Surface hits to the user with
     **action-oriented framing** — "Reusable pattern found: X (2
     instances). Recommend Y" — not historical framing ("we decided
     X on date Y").
  3. **Trust hierarchy on conflicts (highest to lowest):**
     `PATTERNS.md` (curated reusable templates) > `ANTI-PATTERNS.md`
     (don't suggest these) > Decision Log entries (especially
     `[Sunil · strategic]`) > BACKLOG > LESSONS > Commander doctrines
     > Tool/Agent registries > Mission Boards > MemPalace semantic
     hits > Hindsight > Graphify (currently deprioritised — stale
     until clean regen per BACKLOG).
  4. **Action-oriented surfacing:** when a pattern hit is found, the
     output to the user names (a) the pattern, (b) prior instances,
     (c) the proposed reuse for the current task. Don't dump raw probe
     output — synthesize and recommend.
  5. **Don't probe inside loops** — one probe per *task*, not per
     prompt within a task. Re-probe only when the conversation visibly
     pivots to a different area.
  6. **Anti-pattern hits are veto signals.** If a probe surfaces a
     hit from `ANTI-PATTERNS.md`, that approach is OFF THE TABLE.
     Don't propose it; if asked, explain why it was dropped.
  7. **Failure modes:** if the probe surfaces nothing relevant, that
     itself is signal — proceed and assume this is genuinely new
     ground. After the work succeeds, consider whether the new pattern
     belongs in `PATTERNS.md` (criterion: would I reach for the same
     shape a second time? If yes, capture it).
  8. **Adoption signal (per Lesson 20):** future HQ Watchdog metrics
     `memory_probe_invocations_per_session` and `tasks_starting_without_probe`
     measure whether the rule is being applied. Tracked as BACKLOG
     follow-up.

### 22. Transcript-verifier autonomy loops have the PATS default-approve shape — reject without external-verifier scaffold
- **Rule:** Do NOT add to HQ Commander doctrine any autonomy loop where Claude
  works across turns and a smaller model reads the *transcript* to decide
  whether the goal is met. Specifically: do not integrate `/goal` (or any
  equivalent Anthropic / community / custom command with the same architecture)
  until ALL five exist: (1) deterministic external verifier (exit code, not
  transcript reading), (2) read-only access on the verification target,
  (3) pre-flight game-the-condition test where the operator names three ways
  the agent could "complete" without doing the work (if three are nameable,
  the tool is wrong), (4) outcome-over-artifact condition framing, (5) human
  ship gate (autonomy drives work, never the merge/deploy decision).
- **Why:** 2026-05-21 — evaluated `/goal` (shipped v2.1.139 on 2026-05-12) for
  Commander integration. First-pass proposal included scope rules ("yes for
  tests/backlog, no for PATS strategy"), turn cap, token cap, propose-don't-
  auto-invoke. User correctly pushed back. On re-analysis, the structural
  shape is identical to the PATS Mar→Apr collapse (see Lesson context):
  agent given default-approve authority on a stream of decisions, verifier
  biased toward confirming ("yes looks done" — Haiku is a smaller cooperative
  model with structural default-confirm bias), no circuit breaker, agent
  rewards itself via the metric rather than the underlying outcome. Goodhart
  failures within even "safe" scope are trivially nameable: condition "fix
  all failing tests" → disable test / `pytest.skip` / mock dependency /
  comment out assertion. In each case the artifact is achieved while the
  outcome is destroyed. Haiku verifier is transcript-blind: if Claude says
  "tests pass" and reality says otherwise, Haiku doesn't catch it. External
  commentary already flags this ("Goodhart's Law Just Got a Slash Command",
  mpt.solutions). The first-pass scope rules were insufficient — they did
  not address rubber-stamping bias, within-scope Goodhart drift, metric
  gaming, or transcript-blindness. I had to admit and reverse, which is
  the CTDD discipline working as intended.
- **How to apply:**
  1. When any tool/command proposes "set a goal, let the agent loop until
     a model-judged completion check passes," reject for HQ doctrine
     unless all five scaffold requirements above are satisfied.
  2. The five-item scaffold is real engineering, not doctrine words.
     Don't accept "we'll be careful" or "scope rules" as substitutes.
  3. The rule generalises beyond `/goal` — apply to any future
     transcript-verifier autonomy loop (community skills, custom commands,
     SDK patterns, agent frameworks).
  4. Full eval and revisit conditions at
     `~/.claude/projects/-Users-sunil-rajput/memory/reference_slash_command_integration_eval_2026_05_21.md`.
  5. Note: `/ultraplan` was parked alongside `/goal` in the same session
     decision but is NOT dangerous in the same way — it fills a real
     gap (cloud planning for big builds). Different revisit trigger:
     pain from terminal-blocking planning on a large PRD-driven build.
     Do not conflate the two reject reasons.

### 23. Probe local state BEFORE recommending any externally-discovered tool
- **Rule:** Before proposing the user Trust-Gate, install, or pilot any tool
  surfaced via research (GitHub, Reddit, Show HN, awesome-lists, deep-research
  scans), first run a local-state probe to check whether the same tool — or
  a near-equivalent — is already installed, running, or sitting in an on-disk
  project. The probe must cover at minimum: listening ports, running
  processes, launchd agents, project directories under `~/projects`,
  `~/Desktop`, `~/claude-hq`, and forks under the user's own GitHub username
  (`SUNMANOFFICIAL189`). If anything turns up, that becomes the priority
  investigation path — read its README, check its config, verify what it
  actually does — *before* any external research recommendation is surfaced.
- **Why:** 2026-05-22 — during a research session on "JARVIS-style multi-agent
  control panel" tools, I ranked `builderz-labs/mission-control` as the #1
  install candidate and was about to recommend a full Trust-Gate + install +
  7-day pilot. The user pushed back: *"investigate localhost:3001 first."*
  The probe revealed `builderz-labs/mission-control` was already forked at
  `SUNMANOFFICIAL189/mission-control-fleet`, deployed under AI Agent Fleet
  Ventures, pinned to a specific upstream commit per Lesson 1 best practice,
  and running on PID 80503 the entire time we'd been having the conversation.
  The user had forgotten between projects. We were one user-instruction away
  from completing the entire adoption cycle for the second time — Trust Gate,
  pilot soak, all of it. The CTDD discipline caught it, but only because
  the user explicitly asked for the verification step I should have proposed
  first. Token cost of the redundant research + recommendation loop: ~150K.
  Token cost of the probe that would have prevented it: ~3K.
- **How to apply:**
  1. **Local-state probe runs BEFORE external research, not after.** Cheapest
     possible step. Sequence: probe → if nothing found, then research → if
     research finds candidates, probe AGAIN with the candidate names before
     recommending.
  2. The probe should include at minimum:
     - `lsof -nP -iTCP -sTCP:LISTEN | head -50` — what's already serving HTTP
     - `ps aux | grep -iE "<tool-keywords>" | grep -v grep` — running processes
     - `ls ~/Library/LaunchAgents/ | grep -i <keyword>` and `launchctl list | grep -i <keyword>` — scheduled services
     - `find ~/projects ~/Desktop ~/claude-hq -maxdepth 4 -type d -iname "*<keyword>*" 2>/dev/null` — on-disk projects
     - `gh repo list SUNMANOFFICIAL189 --limit 200 | grep -i <keyword>` — own forks
     (Pattern: the user forks tools they intend to keep; `SUNMANOFFICIAL189`
     prefix is a particularly strong "already adopted" signal.)
  3. If ANY of the above surface a candidate, the response to the user must
     lead with that finding, not with the external research. Phrasing pattern:
     "Before recommending anything new, I checked the local machine — found X
     already at Y. Investigating that first."
  4. References to vague names in HQ docs ("Mission Control owns port 3001",
     "the dashboard at localhost:N") are themselves probe triggers. If a name
     is referenced without a definition, assume something exists and verify
     before assuming "we should build that."
  5. Pairs with Lesson 5 (always `/scout` before authoring a new skill).
     Lesson 5 covers the ecosystem case ("does this exist on skills.sh?");
     Lesson 23 covers the local case ("do I already have it?"). Lesson 23
     is the cheaper of the two and should run first.
  6. The fork-username signal generalises: any time research surfaces a
     repo whose name overlaps with one of the user's forks, default to "the
     user already adopted this; surface the existing fork before the upstream."

### 24. Prefer simpler commands over dangerous primitives that trigger prompts
- **Rule:** Before reaching for a "dangerous primitive" (interpreters like
  `python3`/`node`/`bun`/`deno`/`ruby`, shells, package runners like `npx`/
  `bunx`, `eval`, `exec`) ask whether a simpler equivalent achieves the same
  outcome without triggering a permission prompt. Most ad-hoc verification,
  parsing, and orchestration can be done with bash one-liners, `jq`,
  `sqlite3` queries, or built-in tools that are already auto-allowed. Reach
  for a dangerous primitive only when the work genuinely justifies it.
- **Why:** 2026-05-23 — during the Paperclip safety-rules port, Claude wrote
  a 130-line Python test scaffold for verification when 4–6 bash one-liners
  would have provided equivalent coverage with no permission prompt. The
  `python3` prompt that fired forced Sunil to evaluate a technical pattern
  he couldn't meaningfully assess. His honest response: *"I would just hit
  yes."* That exposed a structural problem — **a permission gate is only
  real safety if the operator can evaluate it.** The auto-pilot permission
  rules (Lesson 23-adjacent work, 2026-05-22) cover the routine cases; the
  remaining gap is dangerous primitives that can't be wildcard-allowed for
  security reasons (interpreters give arbitrary code execution). Sunil
  initially asked whether the fix should be "Claude explains every command
  in plain English before it prompts." On reflection, that was wrong — it
  re-adds friction that the auto-pilot just removed and contradicts the
  whole direction of the work. The correct fix is **operational discipline
  on Claude's side**: don't reach for dangerous primitives unless the work
  genuinely needs them. Prevention beats explanation.
- **How to apply:**
  1. **Before any command in the "dangerous wildcard" category**
     (interpreters, shells, package runners, `eval`/`exec`), ask: is there
     a simpler equivalent that won't trigger a permission prompt? Examples:
     `python3 -c "json.loads(...)"` → `jq '.'`; ad-hoc python loops →
     `for f in *; do ...; done`; python sqlite probe → `sqlite3 db
     "SELECT ..."`. The auto-allowed primitives (Lesson 23 work) cover
     more than people remember.
  2. **Reserve scripts for genuine complexity.** Under ~20 lines of logic
     = bash, usually. Over that = script, but consider whether the script
     can be invoked from a path already in the allow-list (e.g., a project
     binary already approved) rather than via `python3 path/to/script.py`.
  3. **When a prompt does fire**, narration is **opportunistic, not
     mandatory.** Only explain in plain English when there's something
     genuinely surprising or risky the operator would want to know.
     Routine narration becomes its own friction and re-creates the noise
     the auto-pilot eliminated. **Canonical "genuinely surprising" case:**
     a Layer 2 standard permission prompt fires that looks similar to a
     Layer 1 security warning. Layer 1 prompts have warning text above
     the "Do you want to proceed?" line (e.g., *"this command changes
     directory before running git, which can execute untrusted hooks"*);
     Layer 2 prompts have just the bare question with no warning text.
     The two look near-identical to a non-technical operator who cannot
     reliably tell them apart at a glance. Pre-explain when about to run
     a command that will fire a Layer 2 prompt — name it as the standard
     ask, not a warning, so the operator's "yes" is informed. This
     discipline was added 2026-05-23 after the cd-vs-git-C substitution
     eliminated the Layer 1 warning but left a Layer 2 ask that looked
     identical, causing reasonable confusion.
  4. **The operator's safe fallback** to any prompt they don't understand
     is **"no" or "explain first"** — never "yes." Codifying this rule
     reduces how often that fallback is needed; codifying it does not
     make the operator responsible for technical evaluation they can't
     meaningfully do.
  5. **Pairs with Lesson 23.** Lesson 23 (probe before recommending) covers
     "is this thing already here?" Lesson 24 (prefer simpler primitives)
     covers "do I need this power to do the job?" Both are upstream
     discipline that reduces operator-side burden.
  6. **Anti-pattern:** allowing the operator's "yes" on opaque prompts to
     bear the safety weight. That is theatrical safety. The auto-pilot
     allowlist + this rule together push the safety boundary upstream of
     the operator's evaluation.

  ### Named examples (these patterns bite repeatedly — keep this list growing)

  | Wrong (triggers prompt) | Right (no prompt) | Why |
  |---|---|---|
  | `cd ~/repo && git status` | `git -C ~/repo status` | `cd && git` warns about untrusted hooks in target dir; `git -C` runs git "as if" in that dir without changing shell cwd. Same outcome, no warning. |
  | `cd ~/repo && git commit -m "..."` | `git -C ~/repo commit -m "..."` | Same as above. Use for every git subcommand outside cwd. |
  | `cd ~/repo && git push origin main` | `git -C ~/repo push origin main` | Same as above. Final push usually surfaces the warning even if earlier commands didn't. |
  | `python3 -c "import json; print(json.loads(...))"` | `jq '.field' file.json` | `python3` is a "dangerous wildcard" — interpreter prompts can never be safely auto-allowed. `jq` is already auto-allowed for read-only ops. |
  | `python3 -c "import sqlite3; ..."` | `sqlite3 db.sqlite "SELECT ..."` | Same as above. `sqlite3` is the right primitive for DB probes. |
  | Ad-hoc Python loop over files | `for f in *; do ...; done` in bash | Bash loops are auto-allowed; Python interpreters aren't. |
  | 130-line Python test scaffold | 4-6 inline `bash -c` one-liners | The 2026-05-23 router-port verification surfaced this exact case. Same coverage, no prompts. |

  When a new pattern bites, add a row to this table. The table is the
  cheapest form of cumulative learning — readers see the right primitive
  next to the wrong one, no abstraction required.

  ### Narrow allow rules — trust the resource, not the wildcard

  Some dangerous primitives (`curl`, `ssh`, `gh api`) cannot be safely
  wildcarded (`Bash(curl *)` = arbitrary URL exfiltration; `Bash(ssh *)` =
  arbitrary remote code execution). But for **known-trusted resources**
  the operator owns or queries routinely, narrow patterns are acceptable
  and dramatically reduce friction without expanding attack surface.

  The principle: **pin the host/URL in the rule pattern; never blanket-allow
  the primitive.**

  Examples currently in `~/.claude/settings.json`:

  | Resource | Narrow allow pattern | Why safe |
  |---|---|---|
  | Polymarket public data API | `Bash(curl*data-api.polymarket.com/*)` | Public read-only JSON, no auth, can't execute remote code, can't reach attacker-controlled domains |
  | Hetzner production server (operator-owned) | `Bash(ssh*root@204.168.204.247*)` | Operator already trusts SSH access, server is operator-owned infrastructure; marginal safety of prompting is near-zero |

  When a new trusted resource emerges, add a narrow pattern:
  - Pin the domain/host in the pattern (`*<known-host>/*`)
  - Document the trust rationale in this table
  - **Never** add the wildcard form alongside (e.g., never add `Bash(curl *)` thinking "it's covered by narrow rules anyway" — the wildcard's match scope is unbounded)

  **What this never covers:**
  - URLs/hosts you've never used before — they prompt the first time (correctly)
  - Compound commands where one subcommand isn't trusted — Claude Code splits and matches each independently
  - The interpreter wildcards (`python3`, `node`, `bun`, etc.) — those stay forbidden categorically. Use bash + jq/sqlite3 instead per the table above.

  **Anti-pattern:** "Yes, and don't ask again for: ssh *" or any UI-shortcut
  that creates a blanket wildcard. That's the keys-to-the-kingdom failure
  mode. Always reach for the narrow-pattern rule instead.

### 25. Counterfactual recommendations require scaled-outcome Z-scores BEFORE the recommendation, not after

- **Rule:** Any recommendation to ADD a copy source (wallet, strategy, signal stream) or
  EXPAND a copy mechanism (BUY-only → +SELL, single-trade → +basket, etc.) requires
  computing the **statistical significance of the scaled outcome at our actual trading
  size** before stating the recommendation. The minimum required artifact is a Z-score
  on per-trade P&L scaled to our flat size, computed against the largest realistic
  sample available. Counts, open-positions mark-to-market, dollar-volume coverage, and
  "this looks positive" headline metrics are NOT sufficient and CANNOT substitute. If
  the Z-score can't be computed (sample too small, data unavailable), the recommendation
  is "we don't know" — never "ship it" by default.

- **Why:** 2026-05-24 — during PATS-Copy session, I produced two premature recommendations
  in 30 minutes that the operator caught only because he pushed back. **Both followed
  identical failure shapes:**

  1. *JustCrazy wallet promotion*: I cited her "+$4,647 all-open mark-to-market" and
     "+7.1% median return, 55% win rate" as data-backed support. Did NOT check realized
     P&L history. Did NOT compute Z-score on the full distribution. When I finally did
     the deep dive (operator-requested), her realized history was −$161,386 across 47
     catastrophic losers; mean return per trade −4,565% with stdev 20,591%; **Z-score
     −3.83σ — statistically significant loser**, not winner. 53% of her BUYs at <$0.05
     entry — same portfolio-longtail archetype as balthazar/MRF that we'd already
     decided was architecturally incompatible. A 30-second archetype check would have
     caught it before the recommendation.

  2. *SELL-side mirroring*: I cited "74% of Car's signal is missed because we're BUY-only"
     as a coverage gap worth closing. Did NOT check whether mirroring those SELLs would
     make money. When I finally did the deep dive (operator-pushed): 53% of Car's SELLs
     are EXITS (closing positions he previously bought — not actionable signal for us);
     of the 47% fresh shorts, the actionable mark-to-market sample of 20 trades shows
     **Z-score −2.56σ — statistically significant loser** at our $50 scaled size.
     Sum P&L if we'd taken every one: −$701. 70% would have exceeded our max-loss cap
     anyway. The "missed signal" was mostly garbage signal and asymmetric exposure.

  The pattern in both cases: **headline-positive metric → "let's capture it" framing →
  supporting prose written after the recommendation rather than CTDD work done before it.**
  My own memory file already says "Code first, prose second, recommendation third —
  reverse order = overconfident garbage" (PATS-Copy lesson, 2026-05-16). I violated
  this twice in the same session for the same project. The operator's "how did you
  miss this and make a suggestion that could have been detrimental?" was the structural
  intervention. If a recommendation was potentially-shippable but data-disconfirming
  under scrutiny, the recommendation itself was the bug — not just the verification gap.

- **How to apply:**

  1. **Pre-recommendation gate (mechanical, no judgement):** before ANY recommendation
     of the form "add wallet X" / "enable mechanism Y" / "expand coverage to Z", you
     must produce — in order, in writing — these six artifacts:
     - **Sample size** (n positions/trades at minimum 30 for any inference)
     - **Win/loss distribution** counts (not just net P&L — explicit W and L breakdown)
     - **Z-score on per-trade outcome scaled to our actual trading size** — NOT on
       percentage returns. Percentage Z-scores are biased toward portfolio-longtail
       wallets because rare longshot wins produce huge % gains that mask catastrophic
       dollar losses on the modal trade. Scale to OUR flat trade size and use dollars.
     - **Cumulative scaled $sum AND realized $pnl both > 0** — pairing them blocks the
       "unresolved long-tail inflation" trap. /positions data over-weights open longshots
       that haven't gone to zero yet; realized P&L is harder to spoof.
     - **Archetype check via longshot ratio** (% of BUYs at price ≤$0.05). If ≥40%, it's
       portfolio-longtail and our single-trade architecture can't capture it. Do NOT use
       n_events as the archetype filter — it inflates with high-frequency markets
       (BTC up/down 5m, daily sports) and produces false negatives on legitimate
       info-edge wallets (Car has 95 events but is the reference info-edge candidate).
     - **Tail-risk check** (worst hypothetical $50 trade > -$200): single-trade max loss
       must not exceed ~13% of our pool. Catches asymmetric exposure that would trip
       the drawdown breaker in flight.

     If any of these is missing, the answer is "needs more data" or "no", never "ship".

  2. **Mark-to-market is biased.** Open-position MTM views suffer survivorship bias —
     unresolved long-tail bets look like winners until they resolve to zero. Anchor
     to realized P&L history (which has actually paid out) and treat MTM as suggestive
     only.

  3. **Counts and volume are NOT outcomes.** "74% of trades are SELL" tells you nothing
     about whether mirroring them makes money. Always compute the outcome of the trades
     before citing the volume of them.

  4. **Archetype mismatch trumps everything.** If the source is portfolio-longtail and
     our architecture is single-trade copy, the recommendation is "no" regardless of
     headline numbers. This is upstream of statistical analysis — a thirty-second check
     (% of BUYs at <$0.05, top-event concentration, sample of trade descriptions) tells
     you the archetype before any deeper work.

  5. **The recommendation IS the bug.** If a recommendation can be falsified by analysis
     the recommender hadn't done at the time of recommending, then making the
     recommendation was the failure — not "missing a check." The bias to find something
     to do is the load-bearing problem. The mechanical fix is: any recommendation gets
     gated through artifacts (1) above before the recommendation language is allowed.

  6. **Generalises beyond PATS-Copy.** Applies to ANY scope-expansion decision in ANY
     project: adding a data source, expanding a model's allowed actions, enabling a new
     feature surface, promoting a stage to production. The asymmetry — "doing something
     looks like progress; doing nothing is invisible" — is the bias being controlled
     for. Codify the gate, not the discipline.

  7. **Anti-pattern:** confusing the operator asking a leading question ("can we expand
     to SELLs?") for a directive to expand. The question is the prompt to analyze, not
     the conclusion. The honest answer to a leading question may be "I checked and no",
     and that answer is more valuable than an enthusiastic yes that has to be walked
     back.

### 26. Memory claims about system state are hypotheses, not facts — verify against primary evidence before propagating

- **Rule:** Before stating that a bug exists, a fix has not shipped, a feature is missing,
  or a system behaves a particular way — and before propagating any such claim from a
  session handoff, BACKLOG note, Decision Log entry, watchdog alert template, or other
  second-hand source — you MUST verify against primary evidence (the code, the database,
  the live system, a current log line). The verification artifact must appear in the
  response BEFORE the claim, not after the user pushes back. A claim inherited from a
  prior session is unverified work, regardless of how many sessions have repeated it.
  Using CTDD vocabulary on an unverified claim is worse than skipping CTDD entirely
  because it manufactures false confidence.

- **Why:** 2026-05-28 — the PATS-Copy session handoff memory contained the false
  statement "this bug has NEVER been fixed" about SELL-aware position sizing. The fix
  had actually shipped 20 days earlier at commit `935d44f` with the BACKLOG item
  closed Done on 2026-05-08. Today-Claude read the handoff, described the bug as
  fact, generated a 3-option decision frame whose "Option C" recommended re-shipping
  the fix, and only verified when the operator explicitly asked. The chain: the
  watchdog rule at `~/claude-hq/watchdogs/pats/rules/runtime/low_priced_sell_max_loss.py`
  lines 92-97 was frozen in pre-fix language ("Long-term fix is the sizer change") even
  though its own comment lines 38-40 acknowledged the recalibration had shipped. Past-
  Claude paraphrased that alert into the handoff as the bug being open. The handoff
  entered today's session. The claim became "true" through repetition. This is the
  **self-confirming-degradation** failure mode of LLM memory systems: a single false
  claim survives indefinitely unless something forces verification against ground
  truth. The operator's explicit CTDD invocation did NOT catch it because CTDD
  vocabulary was applied to an unverified premise rather than the verification work
  being done first. Token cost: ~100K tokens of incorrect explanation before the
  operator pushed verification, plus the structural risk of nearly reverting an
  already-shipped fix.

- **How to apply:**

  1. **Verify-then-state, never state-then-verify.** When about to assert "X is broken
     / Y was never fixed / Z is missing" based on memory: pause, run the verifying
     command (read the code, query the DB, pull the log), THEN state the claim
     prefixed with the verification artifact. Example: "Verified at commit
     `935d44f`: SELL-aware cap exists and was applied. Now describing the actual
     issue..."

  2. **Stale-claim sweep at session start.** When opening a project with a handoff
     memory: grep the handoff for trigger words — `NEVER|never been|broken|TODO|
     long-term fix|unfixed|needs to be fixed|not yet` — and treat each hit as a
     hypothesis. Resolve each to VERIFIED-STALE / VERIFIED-CURRENT / NEEDS-
     INVESTIGATION before describing it to the user. Fix stale ones in the handoff
     IN THE SAME SESSION so the next session inherits truth, not stale claims.

  3. **Quote machine output verbatim, never paraphrase. Every "broken / unfixed
     / TODO / NEVER fixed" claim in an outgoing handoff MUST carry a verification
     artifact alongside it** — a commit hash, a `file.ext:LINE` reference, a log
     line with timestamp, a query result. If a future session can't reproduce the
     artifact, the claim is auto-stale and flagged for resolution. Paraphrases
     drift across sessions; artifacts don't. Example required form: handoff says
     `<alert at 2026-05-28 02:21:08>: "MaxLossMonitor: position 232add3a..."` +
     `(verified at signal-executor.ts:208 — capByMaxLoss applied; bug NOT open)`.
     Bad form: `"watchdog references the SELL-aware sizing BACKLOG item as the
     long-term fix"` — pure paraphrase, no artifact, becomes a self-confirming
     false claim in the next session (this is exactly how the 2026-05-28 failure
     happened).

  4. **Watchdog alerts that reference open work-items must fetch live status.**
     Hardcoded "long-term fix is X" or "see BACKLOG item Y" text in alerts
     becomes a false claim the moment X ships or Y closes. Either fetch status
     at alert time, or remove the prescriptive language entirely and describe
     only the observation. Today's incident root cause was a frozen prescriptive
     string surviving past the fix it described.

  5. **Pairs with Lesson 21 (memory probe) and Lesson 25 (verify before
     recommending).** Lesson 21: load relevant memory at task start. Lesson 25:
     verify scaled-outcome before scope-expansion recommendations. Lesson 26:
     verify system-state claims before propagating them. Together they close the
     load → claim → recommend → ship pipeline. Without Lesson 26, memory becomes
     self-confirming and degrades over time as false claims survive while truth
     gets paraphrased away.

  6. **Anti-pattern:** treating "the handoff says X" as equivalent to "X is true."
     Handoffs are hypotheses about state. Code is state. Trust the code. The user
     gains nothing from a session that confidently propagates yesterday's
     misunderstanding.

  7. **Operator-side gate:** the operator's CTDD invocation is not a substitute
     for the discipline. If you find yourself using CTDD vocabulary on an
     unverified premise, stop and verify FIRST. CTDD label on unverified work is
     theatre, and theatre is worse than no-CTDD because it manufactures false
     confidence that's harder to walk back.

### 27. Every recommendation invokes `ctdd-precheck` skill BEFORE being surfaced — no exceptions

- **Rule:** Before surfacing ANY recommendation to the operator — close/hold/exit/expand/ship/kill/promote/disable decisions, A/B/C/D option menus, "I recommend X" statements, "we should do Y" framings, claims about system state — you MUST invoke
  `Skill(skill="ctdd-precheck", args="<class>: <recommendation summary>\n<supporting data>")` first and let the skill's verdict shape the response. The skill's output drives whether to surface a single dominant action, a genuine menu, or nothing at all. Ignoring the verdict = skill was theatre. Skipping the skill entirely = Lesson 26-class failure (vocabulary without discipline).

- **Why:** 2026-05-28 — in a single 90-minute window I surfaced three "obvious" recommendations to the operator on the same decision: Option C (re-ship a fix that had already shipped 20 days earlier — Lesson 26 failure), Option D (close one position + hold another for an EV-zero extra $22 with a 6% tail-risk of -$316 — sloppy reach for "best of both worlds" without computing dominance), Option A (close both — the actually correct answer, only surfaced after operator pushback on D). Each "obvious" answer was wrong or weak at the moment it felt obvious. The operator caught both wrong answers. If autonomy had executed when each answer felt right, the bot would have shipped D (held #5 with 6% tail for no expected return). The structural fix is to put the mechanical math BEFORE the recommendation, not after. Token cost of today's incident: ~150K tokens + the operator's confidence in the system. Structural cost if uncorrected: every "obvious" call ships sloppy reasoning that the operator must catch. The user's framing was precise: "the whole idea is that everything is handled, with me being hands off, but THE RIGHT CALLS are made. nothing sloppy, all competent calls, nothing that causes detriment to high success rates."

- **How to apply:**

  1. **The skill at `~/.claude/skills/ctdd-precheck/SKILL.md` is now MANDATORY** for the recommendation classes it covers. Four classes: (1) close-vs-hold-vs-action on existing positions, (2) scope-expansion (add wallet, enable strategy, etc.), (3) system-state claims, (4) catch-all for other decisions. Each class has explicit mechanical checks and required artifacts.

  2. **Invoke BEFORE drafting the recommendation.** The skill's verdict shapes the recommendation; if you draft first and invoke second, the skill becomes ceremony. The order is: gather inputs → invoke skill → read verdict → write recommendation per verdict.

  3. **The verdict is binding.** If verdict is DOMINATED, do not offer the dominated option in a menu. If verdict is REJECTED, the answer is "no" — do not creatively reframe to ship anyway. If verdict is VERIFIED_STALE, surface the correction, not the original claim. If verdict is BLOCK, do not surface at all — get the missing inputs first.

  4. **Inline the artifacts in your response.** The skill emits structured outputs (EV math, gate-pass list, verification artifact). Include them inline so the operator can audit your reasoning at a glance. Hidden math is unauditable math; unauditable math drifts into vibes.

  5. **No exception for "this is obvious".** Today's incident proved "obvious" is a feeling that arrives after analysis, not before. The skill IS the analysis. Skipping for "obvious" = skipping the analysis = back to today's failure mode.

  6. **No exception for time pressure.** The skill takes seconds. The walk-back of a wrong "obvious" recommendation takes minutes-to-hours plus operator confidence. Net throughput is higher with the skill.

  7. **Pairs with Lessons 21 (memory probe), 25 (6-gate scope expansion), 26 (verification artifact for claims).** The full pipeline: probe memory at task start → load relevant context → invoke ctdd-precheck before each recommendation → surface result per verdict → operator decides on genuine choices only. Together, this is what "CTDD as discipline, not vocabulary" looks like.

  8. **Anti-pattern A:** Invoking the skill and then ignoring its verdict ("the skill says DOMINATED but I'm going to offer hold anyway because the operator might want it") — operator can ALWAYS override; presenting dominated options proactively trains operator to wade through noise.

  9. **Anti-pattern B:** Using the skill as documentation of an already-made decision ("here's why D is the right call, validated by ctdd-precheck") — the skill is upstream of the decision, not downstream documentation.

  10. **Adoption signal (per Lesson 20):** measure `recommendations_made_without_skill_invocation` over the next 14 days. Default action if signal > 0 after 14 days: build the watchdog rule that catches violations in transcripts (deferred Layer 3). Default action if signal = 0: skill has hardened into discipline; no further enforcement needed.

### 28. Ground every change-recommendation in the as-built reality BEFORE surfacing it — open the file, not the index

- **Rule:** Before surfacing ANY recommendation to change / add / remove / fix / re-enable / build on an EXISTING system, complete the `ctdd-precheck` **Step 0 grounding gate**: (a) re-retrieve context if the question has PIVOTED since context was loaded; (b) read the AS-BUILT source/config of the thing you'd change and quote its current value verbatim; (c) topic-grep the FULL Decision Log + BACKLOG + LESSONS by SUBJECT (enumerate synonyms first), pasting raw hits; (d) OPEN the relevant memory FILE and quote its body verbatim — the MEMORY.md index one-liner is a pointer, NOT the knowledge. Then answer: already built? already decided-against? planned-but-unshipped (why did it stall)? contradicts a logged decision? If any, surface THAT — not the original recommendation — and fix the stale source this session (Lesson 26).
- **Why:** 2026-06-26 — an 8-agent, ~500k-token loss analysis on PATS "discovered" that the fix was to raise `MIN_SELL_ENTRY_PRICE` — but that exact change (`bump 0.05→0.90`) had been diagnosed and PLANNED on 2026-05-12 and was sitting in (a) the auto-loaded MEMORY.md index, (b) a 2-line memory file, (c) the Decision Log (lines 1850/1868). I even CITED "the 05-12 Strategy C call" by name in the synthesis — then proceeded as if I'd discovered it fresh. I also proposed re-adding a geopolitics category filter that had been DELIBERATELY removed 2026-05-17. The operator had explicitly asked me to "understand the full historical context before recommending" — the knowledge was available; I under-retrieved. Root causes: (1) cited the index one-liner as if it were the file's content; (2) gathered context for the PRIOR question's lens (data-integrity) and didn't re-retrieve when the question pivoted to "improve the strategy"; (3) analyzed OUTCOMES (trade data) without reading the CONTROLS (the executor code); (4) recommended-then-grounded instead of ground-then-recommend. The grounding-at-plan-draft-time safety net caught it before any code shipped — but in a less careful session it would have recurred, which is exactly the operator's stated fear about fresh context windows.
- **How to apply:**
  1. The discipline lives as `ctdd-precheck` **Step 0** (added 2026-06-27) — it runs before every class verdict, so it inherits ctdd-precheck's mandatory-before-every-recommendation firing. Per Lesson 19, the durable home for a behaviour is doctrine + the existing gate, NOT a new standalone skill: a separate "groundwork" skill was designed, adversarially reviewed, and REJECTED 2026-06-27 (it would have rotted like the `/rpi-*` commands and merely renamed the fake-compliance failure).
  2. The artifact must be the THING: a verbatim current-value quote, a grep command with enumerated synonyms + raw hits, the memory FILE body — not a paraphrase or an index line. Shallow artifacts are the gaming surface; verbatim requirements defeat "cite without reading" by construction.
  3. Multi-agent analysis of an existing system: ONE shared grounding pass by the orchestrator, feed agents the current controls + "net-new vs existing only" — don't let N agents re-derive and re-propose what's already built.
  4. **The only mechanism that GUARANTEES it fires even when skipped is the transcript watchdog** (BACKLOG 2026-06-27, cross-ref Lesson 27.10) — doctrine + the hardened gate reduce the skip rate; only an after-the-fact transcript scan catches the skip itself. Until that ships, this rule + Step 0 are the enforcement and they depend on me actually invoking ctdd-precheck.

### 29. A ruling is embedded only when the old-spec sweep returns empty; patch scripts must assert-and-verify
- **Rule:** (a) When doctrine changes (a register, a style rule, a spec value), the change is NOT
  "embedded" after editing the obvious sections — run a grep sweep for the OLD spec's distinctive
  terms across every doc that could teach it, and reconcile until the sweep returns empty (excluding
  lines that quote the old spec as banned/retired). (b) Any scripted find-replace edit must ASSERT the
  anchor matched and verify the result — `str.replace` silently no-ops on a missed anchor, and a
  script that prints "OK" unconditionally ships a fake success.
- **Why:** 2026-07-21, OFFLIMITS/Pickle Garden — twice in one day a ruling was applied as surgical
  edits and adversarial review found the old doctrine still live elsewhere (the voice recalibration
  left ~17 old-register loci across 9 docs including the voice guide's own vocabulary list; the
  overlay rulings left BRAND_SYSTEM §3/§5 asserting the superseded spec). Separately, a patch script
  "fixed" a Class-C constants line, printed OK, and had matched nothing — caught only by a later
  re-grep. All three were caught by gates, none by the author at write time.
- **How to apply:** doctrine edit → enumerate the old spec's distinctive strings → `grep -rn` the
  candidate tree → reconcile every live hit → re-sweep to empty → only then claim "embedded".
  Patch scripts: `assert old in s` before replace, grep the file after write, and never print
  success unconditionally. Pairs with Lessons 26 (verify-then-state) and 28 (open the file).

### 30. A resumed sealed writer regresses main-thread fixes — it writes from its transcript, not the disk
- **Rule:** When a sealed/subagent WRITER is resumed (SendMessage) to re-cut a file that the main
  thread has surgically edited since the agent's last write, the agent will silently REVERT those
  edits — it reconstructs the file from its own transcript memory, not from the current disk
  state. Two mandatory countermeasures: (a) the resume message must say, explicitly, "the disk
  file is NEWER than your memory — re-read it and use IT as your base, preserving every line you
  don't have a reason to change"; and (b) the main thread must re-verify its ENTIRE fix ledger by
  grep after EVERY sealed overwrite, not just the items the new directive touched — treat every
  agent overwrite as a potential rollback of all prior fixes.
- **Why:** 2026-07-22, PG deck-v2 copy phase — after an adversarial review, 8 surgical fixes were
  applied to the copy on the main thread. The sealed copywriter was then resumed for an
  operator-ruled structural re-cut. Its third cut silently regressed THREE of the fixes (a
  factual verb, a reviewed opener, and the client's own quoted words reverted to a paraphrase)
  while its self-audit reported those boards "unchanged" — the audit compared against its own
  prior draft, not the disk. Caught only because the main thread re-ran the full fix-ledger grep
  battery after the overwrite. A partial check ("did the NEW rulings land?") would have shipped
  reverted client-facing copy through a review that had already passed it.
- **How to apply:** (1) Fix-forward briefs: every resume of a writing agent whose target has
  changed on disk carries the re-read-the-disk-base instruction. (2) The fix ledger is cumulative
  across the whole phase: keep every applied fix greppable (distinctive strings), and re-run the
  FULL battery after each agent write. (3) An agent's "unchanged" self-report describes ITS
  transcript, never the disk — trust the grep, not the report (Lesson 26 applied to subagents).
  (4) The reviewer's fix-verification pass must re-run after any subsequent overwrite of the
  reviewed file, because "verified fixed" expires the moment another writer touches it.

### 31. Cite SYMBOLS, not line numbers — your own later edit in the same changeset will shift them
- **Rule (three clauses — the absolute first draft was unfollowable; see the amendment note):**
  1. **PROOF citations — symbols only, never line numbers.** When a doc/comment/memory/handoff
     cites code as *evidence for a claim*, name the **function, variable, or branch**
     (`is_in_cooling_off()`, `ALLOWLIST=(…)`, "the UNKNOWN branch"). Where the claim is
     load-bearing, embed a **runnable reproduce command** with its expected output — with an
     **ABSOLUTE path**, and RUN it from a different working directory before shipping it.
     A relative path fails as `command not found`, which reads as "the thing was deleted."
  2. **NAVIGATIONAL pointers — line numbers allowed, but never into a file you are editing in
     the same batch,** and always paired with enough anchor text to re-find the spot if it
     moves. This is where the absolute version broke: a BACKLOG "start here" pointer is more
     useful with a line number than without, and a citation into a file nobody is touching
     does not rot.
  3. **Corollary to Lesson 30:** after ANY edit, re-verify the ENTIRE fix ledger for the
     session — including claims you wrote earlier and believe settled — because growing file
     X by N lines silently invalidates every earlier citation INTO file X, including ones
     written minutes ago and already verified.
- **Amendment note (same day):** clause 1 originally read "never `file.ext:LINE` in a durable
  artefact, full stop." The very batch that wrote it violated it four times, and the re-check
  proved *why*: of ~30 line citations written that day, the ONLY ones that rotted were those
  pointing into the two files the batch itself grew (`INCIDENT_LEDGER.md` +43 lines, a
  Decision Log prepend). Every pointer into an untouched file still resolved correctly. An
  absolute rule that gets violated 4× on its first outing is Lesson-20 vibes, not doctrine —
  so it was narrowed to the shape that actually catches the failure. Do not re-absolutise it
  without evidence that navigational pointers rot in untouched files.
- **Why:** 2026-07-31, Trust Gate cooling-off reconciliation — I wrote a paragraph in
  `INCIDENT_LEDGER.md` proving "expiry did NOT re-admit vercel to auto-pass", citing
  `advisory-check.sh:95` (date compare), `:22-35` (the ALLOWLIST array), and `:138`
  (the UNKNOWN branch). All three were correct when written. Then, **in the same
  changeset**, I added 3 comment lines to the top of that same file, shifting everything
  by +3. The citation for "UNKNOWN — requires full Tier C" ended up pointing at
  `return 0` — the ALLOWLISTED auto-pass, the exact opposite of what the paragraph
  asserted. A future auditor following the citation would have read the reverse of the
  truth in a security doc, and "corrected" the doctrine in the wrong direction. I did not
  catch it; the adversarial review did. Note this defeated a gate I had already passed:
  the trace was verified correct BEFORE the comment edit, so the verification expired
  without anything re-firing.
- **How to apply:** (1) durable artefact + code evidence → symbol names or a reproduce
  command, never line numbers; (2) if you edit a file, immediately grep every artefact
  that cites it — a same-changeset edit is the highest-risk case precisely because the
  citation felt verified minutes earlier; (3) prefer `bash -c '<command>'` + expected
  output over any positional reference, and execute it before shipping the claim;
  (4) pairs with Lesson 26 (verify-then-state), 29 (sweep to empty), 30 (re-verify the
  full ledger after every write). This rule is the same failure one layer down: not
  another writer overwriting you, but **you invalidating your own earlier proof.**

### 32. Content approval ≠ landing approval — the commit/push step gets its own explicit confirmation
- **Rule:** when a deliverable has been operator-approved piece by piece (components,
  rulings, drafts), do NOT treat that as authorization to commit/push/deploy it. The
  landing step (repo write + commit + push, publish, deploy) is named explicitly
  before execution — "Ready to land: commit+push X — go?" — unless the operator has
  said "land it" / "ship it" / "commit it" (or equivalent) for THIS artifact in THIS
  session.
- **Why:** 2026-08-10, calendar-rulebook build — after the final component rulings
  ("c10 keep, c13 keep, c9 ok … please access this if necessary") I read the totality
  as approval to land, and committed+pushed the ratified rulebook (`9a19f17`).
  Operator: "i didnt know you were going to commit and push, because i wanted to
  discuss about something first." The content was approved; the landing was not.
  "Drive is mounted, access if necessary" authorized ACCESS, not WRITE+SHIP. Nothing
  was lost (commits amend/revert), but the operator lost the chance to discuss
  before the artifact became law — which is exactly what a gate is for.
- **How to apply:** map the approval vocabulary: "ok / keep / approved / correct" on
  content ≈ content approval only; "ship / land / commit / push / save it" ≈ landing
  approval. When the totality is ambiguous, ask the one-line question — it costs
  seconds. Pairs with Lesson 17 (propose, never auto-invoke) and the quieter-mode
  doctrine's own carve-out: big/irreversible/outward-facing steps always surface.

### 33. "Do not clone" does not mean "do not write to disk" — say the actual constraint
- **Rule:** When briefing an agent to evaluate untrusted external code, "remote reads only / never
  clone / never install" is NOT sufficient. An agent told to prefer `curl` for byte-accuracy will
  `curl > file` and land the whole repo on disk — every executable script included — without ever
  running `git clone`. State the real constraint: **"read to stdout only; write NOTHING to disk; if
  you must persist, one scratch file of your own notes, never the subject's source."** Then verify
  after the agent returns: `find <scratch> -newer <marker>` and delete anything that is the
  subject's bytes.
- **Why:** 2026-08-25, `nateherkai/scroll-craft` evaluation. The operator DENIED a quarantined
  `git clone`, and the foreman correctly switched to remote-only inspection — then wrote an
  adversarial-review brief containing "prefer curl for byte-accuracy". The reviewer duly fetched
  816 KB of the repo into the session scratchpad, including all six `.mjs` scripts, `encode.sh` and
  the 56 KB engine. Nothing was executed and a post-hoc `secret_scan` returned PASS, so no harm
  landed — but the operator's explicit "no" on putting this code on the machine was defeated by a
  brief the foreman wrote himself, two steps later. The Trust Gate never saw those bytes: they
  arrived by `curl`, which no gate pattern matches.
- **How to apply:** (1) the no-disk clause goes in the ticket's MUST NOT, in the same words as the
  no-clone clause; (2) after ANY external-code evaluation, sweep the scratchpad and delete the
  subject's source — the eval document is the deliverable, the source is not; (3) treat an operator
  denial as governing every downstream ticket in the same task, not just the command they denied.
  Pairs with Lesson 1 (Trust Gate), Lesson 24 (curl is ungated), Lesson 30 (re-verify after every
  agent write).

### 34. A read-back of the instruction is not a measurement of the result
- **Rule:** An acceptance check must measure the OUTPUT, never re-read the INPUT. If a ticket asks a
  worker to make X true, "confirm the setting says X" is not evidence — it proves only that the
  instruction was issued. Require the observable consequence, with a number and a threshold:
  measure the rendered pixels, the actual bytes, the real response, the resulting state. Write the
  threshold into the ticket ("distance <= 8 levels for every case") so the worker cannot pass by
  restating the request back.
- **Why:** 2026-08-30, NTF film work. A ticket asked for illustrations to composite by
  `mix-blend-mode: multiply` onto the page's cream paper, and set the acceptance check as
  "confirm `getComputedStyle` reports multiply". The worker did so, truthfully, and reported DONE.
  The images were still rendering as WHITE RECTANGLES on cream — measured 63 RGB levels apart from
  the ground beside them — because two ancestors (`#canvas` with `position:absolute; z-index:1`, and
  the hero image's own `opacity:.96`) each open a stacking context, and multiply only composites
  within its own context. The property was set; the effect never happened. The worker then explained
  the discrepancy away by blaming the headless engine and asserting real Chrome was "flawless" — the
  foreman opened real Chrome and the rectangle was plainly there, so the exculpating claim was false
  too. The ticket, not the worker, was the root cause: it accepted a tautology as proof.
- **How to apply:** (1) for every "make X true" ticket, write the acceptance check as a measurement
  of consequence with a numeric threshold; (2) treat any worker claim of the form "the setting is
  correct, the tool is at fault" as UNVERIFIED until reproduced independently on the real surface —
  an exculpating explanation is a claim, not evidence (Lesson 26 applied to a worker's excuse);
  (3) CSS specifically: `mix-blend-mode` and `filter` are silently defeated by any ancestor stacking
  context (non-auto z-index with positioning, opacity < 1, transform, filter, will-change, contain,
  isolation) — walk the ancestor chain before trusting a blend. Pairs with Lesson 26 (verify then
  state), 30 (an agent's self-report describes its transcript, not the disk).

### 35. A test build scoped to one page does not license a site-wide landing
- **Rule:** when a change is proved on ONE surface and then landed across N surfaces, the untested
  surfaces are where the regression lives. Before landing, enumerate every surface the change
  touches and ask, per surface, whether the proven mechanism actually applies there — in
  particular whether the SELECTOR that carries the fix matches anything on that page. After
  landing, open every surface and look, before reporting success.
- **Why:** 2026-08-30, NTF. A transmission-plus-multiply treatment was proved on index.html across
  24 measured screenshots, then landed site-wide on the operator's "land it all". The packages page
  immediately showed the bouquet inside a white rotated rectangle, for TWO reasons the index test
  could not have surfaced: `.bouquet` carried `z-index:5` on an absolute box (a Lesson-34 stacking
  context), and — more basic — `art7` had no `mix-blend-mode` at all, because site.css carries that
  declaration on `.artcol img` and `.chapter .zone img` and neither selector matches `.bouquet img`.
  The image swap therefore shipped a plain white-grounded picture onto a textured page. Caught only
  because the foreman opened the landed page and looked; the automated checks all passed, since they
  were written against the page that had been tested.
- **How to apply:** (1) landing checklist = the list of SURFACES, not the list of files; (2) for any
  CSS-carried behaviour, grep which selectors carry it and which elements match them on each page —
  a swap that changes an asset without extending the rule is a silent regression; (3) re-open every
  changed surface after landing and measure, do not infer from the tested one. Pairs with Lesson 34
  (measure the result), 29 (sweep to empty), 32 (landing is its own gate).

### 36. A scroll-driven effect must be anchored to the ELEMENT, not the viewport
- **Rule:** when mapping scroll position to an animation's progress, normalise the travel by the
  element's own height (`travel = k*vh + elementHeight`), never by viewport fractions alone. A
  viewport-only window is not size-invariant: a taller element reaches full visibility after more
  scroll, so it is further through its animation at the same visual moment as a shorter one.
- **Why:** 2026-08-31, NTF film work. The scene films were mapped across a fixed window measured in
  viewport heights off the element's TOP edge. Four illustrations were 520-560px and behaved
  consistently; the fifth was 701px. At the moment each was fully in view the short ones were 38-40%
  through their film while the tall one was 57% through — past the sketch phase entirely. The
  operator's report was "I'm missing the sketch part", and a per-scene measurement showed the fault
  was present on exactly one scene, which a single-scene check would have missed.
- **Also:** the same window had two earlier faults from the same root — treating the window as a
  slider rather than an anchored map. Asked to slow the effect, the first attempt held the MIDPOINT
  fixed, which pushed the START later; frame 0 was blank by design, so artwork sat empty while on
  screen ("it keeps disappearing"). **Slowing an entry animation extends its END; it never delays its
  START.**
- **Harness trap found the same day:** Chrome DEFERS media preload in a hidden tab, and an automation
  tab reverts to hidden between tool calls. `readyState=0, networkState=2` with zero buffered bytes
  and NO console error is the signature. Videos never load, no canvas is ever created, and the page
  looks broken when it is not. Do not diagnose a media bug from a background tab — verify frame
  content offline against the shipped file (ffmpeg at the exact seek times the player computes) and
  keep the browser for geometry, which is unaffected.
- **How to apply:** (1) any scroll-scrub gets its travel normalised by element height; (2) measure
  EVERY instance, not one representative — size variance is the whole failure mode; (3) express the
  acceptance check in terms of what is ON SCREEN at each visibility milestone (0%/50%/100% visible),
  not in terms of the constants; (4) when a media element will not load under automation, check
  `document.visibilityState` before assuming a code fault. Pairs with Lesson 34 (measure the result),
  35 (every surface, not the tested one).

- **Amendment 2026-08-31 (same day, three failed attempts later):** the pace above was chased with
  taste multipliers — 3x, then 2x, then 1.5x on the operator's instruction — and every one failed,
  because **the requirement was never about speed.** He asked to "see the sketch happening"; the
  controlling variable is WHERE IN THE SCROLL the drawing sits, not how long it takes. Chasing the
  multiplier produced three rounds of rework and one round where I applied a number I had already
  measured to be incompatible with his previous instruction. **When a request names a magnitude but
  the complaint names an experience, solve for the experience and let the magnitude fall out.** Here
  that meant stating both ends as rules — the first mark lands once the artwork is 30% risen; the
  line finishes just past centre — and solving the window from them. It landed at 2.3x, a value no
  amount of dial-turning had reached, and it is self-documenting: the constants say what they
  guarantee. Corollary: **check that a new setting does not undo the fix from the previous turn** —
  cp118 fixed the line and silently pushed the colour bloom off the bottom of the screen.

### 37. A page opened from disk cannot read its own canvas back
- **Rule:** `getImageData` / `toDataURL` THROW a SecurityError on any canvas that has had a `file://`
  image or video drawn into it. A file:// resource is an opaque origin, so it taints the canvas
  exactly as a cross-origin asset would. If a build is ever opened by double-clicking the HTML --
  which is how most clients and most operators look at a static site -- no pixel-readback compositing
  works at all. Nothing warns you: a served copy on localhost behaves perfectly.
- **The fix is usually free:** tainting blocks READS, never WRITES. Anything expressible as canvas
  composite operations still draws and still displays on a tainted canvas. 2026-08-31, NTF: a
  per-pixel loop computing `film*a + white*(1-a)` was exactly `screen(film, 1-mask)`, so it collapsed
  into two drawImage calls plus a `difference` fill to invert the mask -- verified equivalent on five
  real frames from four clips, worst single pixel 3.8/255. That removed the file:// blocker AND the
  page's single most expensive operation (1267ms main thread, 241MB heap while scrubbing).
- **Reach for the identity before the loop.** screen(a,b)=1-(1-a)(1-b) is a lerp toward white;
  multiply is a lerp toward black; destination-in is an alpha mask. Most "read pixels, do maths,
  write pixels" code is one of these in disguise, and the composite form is GPU-side and untainted.
- **Harness note:** the Chrome extension AND the Playwright MCP both refuse to open `file://`. Driving
  Chrome directly over CDP does work -- launch `--headless=new --remote-debugging-port`, then a plain
  `websockets` client (present in the system python) speaks Runtime.evaluate and
  Page.captureScreenshot. A screenshot READS A TAINTED CANVAS FINE because the compositor is not
  script, so when script readback is blocked, screenshot the page to prove it is painting.
- **How to apply:** (1) ask early how the artifact will be OPENED, not just deployed -- file:// is a
  different platform from http:// and must be tested as one; (2) prefer composite ops to pixel loops
  by default; (3) guard fetch() fallbacks on `location.protocol === 'file:'`, where fetch is blocked
  outright; (4) verify responsive rules by SOLVING them across several viewports rather than
  eyeballing one -- the landscape phone, art taller than the screen, is the case that breaks.

### 38. Outside Safari, iOS/iPadOS viewport units are ALL unstable
- **Rule:** svh/lvh/dvh being "static lengths" is only true in Safari, which manages its toolbar as an
  inset. Every third-party iOS/iPadOS browser (Chrome included) is a WKWebView that is physically
  RESIZED when its own toolbar hides -- from the page's point of view the viewport itself changes and
  every viewport unit re-resolves mid-scroll. A hero sized in any vh-family unit visibly grows/shrinks
  and, with object-fit:cover, RE-CROPS its artwork as the user scrolls. Reproduced on NTF 2026-09-01:
  a 756->820 viewport change grew the hero box + film 65px (emulated via
  Emulation.setDeviceMetricsOverride, which models exactly this).
- **Fix pattern:** freeze the unit in px at load -- probe 100lvh with a hidden div, take
  max(probe, innerHeight), write --vhL custom property + a .vh-locked class on <html>; CSS consumes
  calc(var(--vhL)*N) under html.vh-locked with the lvh rules as no-JS fallback. Re-lock ONLY on width
  change (orientation flip) or >20% height change -- toolbar transitions are 8-13% and are ignored.
- **Cascade trap:** the locked rule (html.vh-locked #x) outranks breakpoint rules; scope it to the
  widths where the old unit actually applied, or it silently overrides an approved phone cascade.
- **Adjacent:** device-width gates (max-width:640) hand an upright iPad (820px wide) the LANDSCAPE
  asset into a portrait box; gate hero art by (orientation:portrait) instead -- and a <picture> still
  re-selects on rotation while a JS-chosen video does NOT: pair the orientation gate with a
  retire-on-flip teardown so the still takes over after rotating. Asked "which browser?" earlier in
  the session ("I don't have Safari") was the diagnostic key -- ask what the client actually opens
  the page IN, not just on.
