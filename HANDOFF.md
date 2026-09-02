# HANDOFF — CLAUDE HQ (infrastructure)

> Single source of truth for resuming HQ INFRASTRUCTURE work with zero context lost.
> **The code is authoritative. If this document and the code disagree, the CODE WINS.**
> Written only by the `/handoff` skill. Never store secrets here: environment-variable NAMES only.
> Deep detail lives in the linked canonical files (this doc is a map, not a dump).

- Schema: handoff/v1
- Canonical path: /Users/sunil_rajput/claude-hq/HANDOFF.md
- Constitution: /Users/sunil_rajput/claude-hq/CLAUDE.md + commander/COMMANDER.md + docs/ORGANIZATION.md
- Last refreshed: 2026-09-02 23:45 — Google-bill trace + hook-review wave — manual
- Scope note: this is the HQ-infra handoff. The web-arm sub-project keeps its own at `skills/web-arm/HANDOFF.md` (resume it by working from that directory).

---

## Goal
Keep CLAUDE HQ (the orchestration brain at `~/claude-hq`) healthy, cheap, and safe. This handoff
covers infrastructure work — cost control, hooks/gates, doctrine — not a single deliverable. "Done"
for a given task = pushed to `SUNMANOFFICIAL189/CLAUDE-HQ` with its gates honoured.

## Current State
On 2026-09-02 an unexplained Google charge (card ref `CLOUD VBHV3N`, £20.15) was traced to the SUNNY
billing account and two live cost sources were reduced; a proof-check of that work found five real
faults which were fixed and verified; and an "unknown writer" of the HQ hook config turned out to be
a second concurrent session (Sunil's) hardening the hook, now committed. HEAD = origin/main =
`02910ee`; tracked tree clean (8 untracked scratch/backup files parked, not tracked). [firsthand][confirmed]

- 2026-09-02: `flightclub33-v3-demo` Cloud Run min-instances 1→0 (was billing 24/7 since 08 Jun); reversible switch at `scripts/cloudrun-power.sh`. [firsthand][confirmed]
- 2026-09-02: claude-mem kept on the Gemini PAID tier (free tier trains on client data) but call volume cut — `CLAUDE_MEM_SKIP_TOOLS` 23→59 entries, ~42% of chargeable observations removed; verified live against the worker. [firsthand][confirmed]
- 2026-09-02: budget "SUNNY monthly guard" £15/mo created (alerts 75% / 100% / 90%-forecast). [firsthand][confirmed]
- 2026-09-02: commits `4668b11` (cost work) → `091c3d4` (proof-check fixes) → `2b6e008` (LOW notes) → `02910ee` (Sunil's hardened hook), all on origin/main. [firsthand][confirmed]
- 2026-09-02: two reminders for 2026-09-16 armed and VALID (telegram + email); `reminders.validate()` returns None for both. [firsthand][confirmed]

## Decision Log  (append-only — newest on top; never edit/delete a prior entry)
- 2026-09-02 [Sunil] Committed the hardened crg hook (`02910ee`): absolute binary path + visible error log + seconds timeouts; matcher kept as `Edit|Write|MultiEdit` (Bash NOT restored — treat as deliberate unless revisited). Supersedes Claude's 23:21 bare restore.
- 2026-09-02 [Joint] Google spend: reduce claude-mem VOLUME, keep the paid tier; free tier disqualified (trains on client data). Switch off the demo Cloud Run; add a £15 budget. Rationale in `project_google_cloud_bill_trace_2026_09_02.md`.
- 2026-09-02 [Claude] Fixed on TOP of the reviewed commit, never amended, so the record shows the review found the faults (dead reminders, a switch that lied when Google was unreachable, an install-hooks doctrine landmine).

## What Didn't Work / Dead Ends
- The push-gate override `PROOF_OK=1` as a command PREFIX does NOT work — the gate hook runs before the command, so it never sees the var (Lesson 8). Clear the flag via a clean `/proof-check`, or `export` it before launching Claude.
- Testing the switch's `on` path against real Google is blocked by the Claude Code safety classifier (cost-incurring). Proven instead against a stub `gcloud`. To exercise for real, the operator runs it: `! ~/claude-hq/scripts/cloudrun-power.sh on flightclub-demo`.
- Cross-vendor (Codex) review is unavailable — vendored binary ENOENT (`/opt/homebrew/.../codex ENOENT`). Reviews this session were single-vendor (fresh Opus agent).
- Reverting the concurrent-session hook edit a second time would have been WRONG (two-writers clobber, Lesson 30) — it was a benign, safer edit by Sunil's own session, not a threat.

## Open Threads & Next Actions  (numbered; mark DONE in place, never delete)
1. ⭐ NEXT (operator-confirmed): on or after **2026-09-16**, run the claude-mem cost re-measurement. Command + baseline (12,975 req/30d; 3,813 chargeable obs in the final week; expected ~42% cut) are in `project_google_cloud_bill_trace_2026_09_02.md` (§"BASELINE for judging"). If weekly requests are still above ~3,000, escalate to disabling the PostToolUse observation hook (~87% cut, but fragile across plugin updates). If below, stop.
2. Decide whether `Bash` belongs back in the crg hook matcher — `02910ee` dropped it (COMMANDER.md Step 0.D says Edit|Write|Bash). Heavy file mutation happens via Bash, so the graph may go stale on shell edits. Operator call.
3. Flip BACKLOG item (4) "settings.json writer UNKNOWN" → RESOLVED: it was Sunil's concurrent session (`02910ee`, author verified). Do this on the next `/sync`.
4. Tidy the 8 untracked scratch files in `~/claude-hq` (`*.rtf`, `*.bak-*`, `history.db.pre-migration-backup`, `quota-incident-2026-04-28/`, `model-router.py.backup-*`) — decide keep-or-remove.
- DONE 2026-09-02: adopt the concurrent session's hardened hook — landed by Sunil in `02910ee`.
- DONE 2026-09-02: proof-check the cost/hook work — blind Opus verifier PASS_WITH_NOTES; 3 LOW filed to BACKLOG.

## Runtime / Environment
- claude-mem worker RUNNING (PID was 15299; bun, port 37777) with the reduced skip-list live. Restart if needed: `~/.bun/bin/bun ~/.claude/plugins/cache/thedotmack/claude-mem/10.5.6/scripts/worker-service.cjs restart`.
- Two reminders armed in `watchdog/reminders.json` firing 2026-09-16 (telegram 09:00, email 09:05).
- Budget alert live on billing account `01691F-377789-CD02C5`.
- Uncommitted work: NONE tracked (tree clean at `02910ee`). Untracked scratch: 8 files (see thread 4).
- Session model was switched to Fable 5.1 for two verification passes; return to Opus 5 for routine work.
- A tripwire fingerprint of `.claude/settings.json` sits at `run/settings-tripwire.txt` (gitignored) — its baseline predates `02910ee`, so it will not match HEAD; that's expected now the writer is known.

## Pointers  (links, never copies)
- Constitution: `CLAUDE.md`, `commander/COMMANDER.md`, `docs/ORGANIZATION.md`
- Cost trace (the full record + reproduce commands): auto-memory `project_google_cloud_bill_trace_2026_09_02.md`
- claude-mem billing note: auto-memory `reference_claude_mem_cost_effective_config.md` (its "$0/mo" claim is corrected there)
- The switch: `scripts/cloudrun-power.sh` + `run/cloudrun-state/README.md`
- BACKLOG: `docs/BACKLOG.md` (2026-09-02 entries: cost decisions, review residuals, writer-ID)
- Vault Decision Log: `JARVIS-BRAIN/Projects/claude-hq/Decision Log.md` (2026-09-02 entry appended)
- Mission board for this wave: `run/mission-board-2026-09-02-review-fixes.md`
