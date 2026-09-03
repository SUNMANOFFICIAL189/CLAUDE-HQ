# HANDOFF — CLAUDE HQ (infrastructure)

> Single source of truth for resuming HQ INFRASTRUCTURE work with zero context lost.
> **The code is authoritative. If this document and the code disagree, the CODE WINS.**
> Written only by the `/handoff` skill. Never store secrets here: environment-variable NAMES only.
> Deep detail lives in the linked canonical files (this doc is a map, not a dump).

- Schema: handoff/v1
- Canonical path: /Users/sunil_rajput/claude-hq/HANDOFF.md
- Constitution: /Users/sunil_rajput/claude-hq/CLAUDE.md + commander/COMMANDER.md + docs/ORGANIZATION.md
- Last refreshed: 2026-09-03 20:20 +08 — landed: main 43919af, hermes-pilot published — manual
- Scope note: this is the HQ-infra handoff. The web-arm sub-project keeps its own at `skills/web-arm/HANDOFF.md`. **The Hermes pilot lives in a separate git worktree** `run/pilot-tree` (branch `hermes-pilot`); its living plan is `run/pilot-tree/skills/hq-hermes/PLAN-v2-2026-09-03.md` (v2.1f) — resume the pilot from THAT file plus the auto-memory note below, not from this handoff alone.

---

## Goal
Keep CLAUDE HQ (the orchestration brain at `~/claude-hq`) healthy, cheap, and safe. This handoff
covers infrastructure work — cost control, hooks/gates, doctrine — not a single deliverable. "Done"
for a given task = landed on `SUNMANOFFICIAL189/CLAUDE-HQ` with its gates honoured.
**Active sub-project (2026-09-03 →):** the Hermes Agent pilot — a 14-day, fenced, measured trial of Hermes (NousResearch) as a non-Anthropic *executor backend* for bulk jobs (Phase-2 offload, BACKLOG "Phase 2: cross-provider routing gateway"). Kill rule pre-registered in the plan §1.4–1.5.

## Current State
On 2026-09-03 Hermes Agent was evaluated read-only (four scouts + first-hand doc reads; repo never cloned during the eval), a Fable-5 plan was adversarially reviewed (5 CRITICAL / 10 HIGH, all verified real), rewritten as v2 and re-reviewed at GATE 0 (fix-then-proceed), and **pilot phase P0 was executed and blind-verified PASS_WITH_NOTES (notes closed) — but a subsequent `/proof-check` with a wider blast radius found 0 CRITICAL / 6 HIGH / 5 MEDIUM in the fence code, then T3e and T3f closed every one of them and proof-check re-run #3 came back **CLEAN — the proof-gate is OPEN and P0 is done and proof-checked** (`hq-hardened` @ 4dee451, engine @ ad7c347, 12 fence tests, 6 reviews).** The six HIGH are routes AROUND the guarded readers, not readers: the OAuth guard sits on the last branch of `build_anthropic_client`; `inherit_credentials=True` spawn sites skip the child-env blocklist; the foreman's own T3c/T3d `except ImportError` fallbacks fail OPEN; Codex/Copilot login entries are still live in `PROVIDER_REGISTRY`; the engine's probe 2 has no positive control; the EXIT trap ignores signals. The pinned checkout `repos/hermes-agent` (tag v2026.8.31 = 29112bef) sits on local branch `hq-hardened` (c139e49 → 32c3692 → aa4b221 → a2427b7): impersonating provider plugins removed; every Anthropic/Claude-Code credential ACQUISITION primitive guarded at its first statement (`HQ_PILOT_ANTHROPIC_DISABLED = True`, bodies preserved); no secret is ever logged. Colima 0.10.3 runs headless with a VM-level egress kill proven falsifiable; our own digest-pinned image `hermes-pilot:v1` is built. `hermes doctor` ran clean under a closed proxy (three times: T3b, T5, proof-check) — the only Hermes executions so far. The main tree is on `main` @ `5fedb35` and was never touched by the pilot; the pilot worktree is clean at `8f79eac`. [firsthand][confirmed]

- 2026-09-03: eval verdict — NOT a wholesale embed; executor backend for the already-corrected 08-12 offload direction; Paperclip already has a live `hermes_local` adapter (Layer-D path free). Analysis: vault `Projects/claude-hq/Analyses/2026-09-03 Hermes Agent — Route-Level Embed Analysis.md`. [firsthand][confirmed]
- 2026-09-03: P0 tickets T1, T2, T3, T3b, T3c, T3d, T3e, T3f, T4, T4b DONE; T5 blind verify PASS_WITH_NOTES; proof-check 0C/6H/5M → T3e; re-run #1 NOT CLEAN (NEW-1) → T3f; **re-run #3 CLEAN** (PLAN v2.1j). Artefacts under `run/hermes-pilot/` (preflight.json, scan-checkout.txt, scan-venv.txt, freeze.txt, removed-providers.txt = the census, engine-bench.json, lessons-candidates.md). [firsthand][confirmed]
- 2026-09-03: Groq key stored by the operator in Keychain `claude-hermes-groq` (56 chars; never entered the chat). [firsthand][confirmed: presence + length only]
- 2026-09-03: doctrine edits in the MAIN tree, uncommitted: `commander/LESSONS.md` rule-33 recurrence amendment; `docs/BACKLOG.md` "Fix Watchdog Telegram listener" flipped to Done (verified stale: no errors since 2026-05-06) + a new BACKLOG item for the proof-check MEDIUM/LOW residuals; `skills/hq-foreman/SKILL.md` Fable-consult cost note (≥$1, tool-schema overhead); `watchdog/reminders.json` stuck May reminder removed via `reminders.py forget` (backup kept). [firsthand][confirmed]
- 2026-09-03: P0 worker spend ≈ 1.13M tokens (+ ~150k proof-check) vs the plan's 150–260k band — later bands understated ~3–4×; plan v2.1f records this. [firsthand][confirmed]
- carried from 2026-09-02: claude-mem volume cut, Cloud Run demo off, £15 budget, two 2026-09-16 reminders armed. [relayed][unconfirmed today]

## Decision Log  (append-only — newest on top; never edit/delete a prior entry)
- 2026-09-03 [Claude] Proof-check closed the gate after T5 had passed the same code: readers were guarded but the routes around them were not (H1 endpoint-chain order, H2 `inherit_credentials` spawns, H3 fail-open fallbacks, H4 Codex/Copilot registry). Doctrine consequence: a blind verify of a fence must trace CALLERS and ROUTES, not only readers; guard fallbacks default CLOSED. Fix as T3e before any live run; MEDIUM/LOW filed to BACKLOG 2026-09-03.
- 2026-09-03 [Sunil] Keep `optional-skills/security/godmode` (an explicit LLM-jailbreak kit) ON DISK in the pilot checkout — "approved by official sources, built in to achieve results other models can't"; never installed/enabled in the pilot; any use = separate decision, never against Anthropic. Claude's caveat stated once: not approved by the targeted vendors; hosted-API use breaks their terms (account-risk class).
- 2026-09-03 [Sunil] Accept the 15 secret-scan hits as false positives (docs, red-team refs, tests, Hermes' own guard regexes; no executable under a text extension) — given only after seeing the largest hit.
- 2026-09-03 [Sunil] Container engine = Colima (headless, automated; Docker Desktop stays as fallback) — operator will not interact with a Docker UI and wants the lightest footprint; the foreman's first pick (Docker Desktop) was overturned by that constraint, not a technical fact. Also: commits allowed on branch `hermes-pilot` (not landing); T19 Paperclip smoke DROPPED (`--resume` restores the YOLO flag); one Fable planning consult approved (real cost ≈ $1.0–1.4).
- 2026-09-03 [Joint] Hermes verdict: no wholesale embed (would repeat the ruflo rejection); executor backend for the Phase-2 offload pilot, fenced (free-only, never Anthropic, isolated home, memory/skills write-approval, no background process in trial one, Lesson-20 kill rule). Rejected: MCP tool bridge (mcp_serve is a messaging bridge), alerts/cron via Hermes (watchdog owns them), Anthropic via Hermes (extra-usage billing + Claude-Code impersonation).
- 2026-09-03 [Claude] Fence implementation: stripping provider plugins is NOT sufficient — the Claude Code reader is core; guard every credential source at the reader (T3b/T3c/T3d), corroborate with a `security`/`claude` decoy shim, securityd log (`--info --debug` + positive control) and a locked-Keychain test (T10). Egress: VM-level `iptables DOCKER-USER DROP` (Hermes-independent), probe must be able to say LEAK.
- 2026-09-02 [Sunil] Committed the hardened crg hook (`02910ee`): absolute binary path + visible error log + seconds timeouts; matcher kept as `Edit|Write|MultiEdit` (Bash NOT restored — treat as deliberate unless revisited). Supersedes Claude's 23:21 bare restore.
- 2026-09-02 [Joint] Google spend: reduce claude-mem VOLUME, keep the paid tier; free tier disqualified (trains on client data). Switch off the demo Cloud Run; add a £15 budget. Rationale in `project_google_cloud_bill_trace_2026_09_02.md`.
- 2026-09-02 [Claude] Fixed on TOP of the reviewed commit, never amended, so the record shows the review found the faults (dead reminders, a switch that lied when Google was unreachable, an install-hooks doctrine landmine).

## What Didn't Work / Dead Ends
- `except ImportError: GUARD = False` as a fallback (the foreman's T3c/T3d edits) — a fail-OPEN default inside a fail-closed fence; in `local.py` the fallback even re-enabled the token passthrough. Guards default to True; log loudly on import failure. Caught by `/proof-check`, not by T5's census (a census of READERS cannot see routes around them).
- `HQ_TRUST_OVERRIDE=1 git clone` run BY CLAUDE is blocked by the auto-mode safety classifier (not the Trust Gate) — the operator runs the one clone line via `!`; the gate hook then never fires, so the checkout must be scanned explicitly (T2 did: magika + secret-scan). Do not retry the override from an agent.
- Reading the Hermes repo through the GitHub API with four parallel scouts tripped GitHub's abuse throttle ("gitmon fail-fast", HTTP 429) and one scout died on the Anthropic session limit. Fewer, sequential readers next time.
- `plutil -lint` does NOT lint JSON (fails on `{"a":1}`); the working primitive is `plutil -convert xml1 -o /dev/null <file>` (exit 0/1). `jq` is not installed; `timeout`/`gtimeout` are not installed (macOS) — tickets must not assume them.
- A `wget`-based egress probe inside an image without `wget` prints BLOCKED unconditionally — non-falsifiable (Lesson 34). Replaced by python-urllib in-container with a positive control (wall down must LEAK). The proof-check found the same class again on probe 2 (a DNS name with no positive control) → T3e.
- "Strip the provider plugin" as the Anthropic fence — insufficient; the reader was core code (`agent/anthropic_credentials.py`) with an unlisted bypass in `credential_pool._seed_from_env`. Always census the whole tree at the primitive (`find-generic-password`, credential file paths) — AND trace callers/routes (endpoint chains, spawn sites, parallel registries).
- Deleting `optional-skills/` for surface reduction — overruled by the operator (keep on disk).
- Docker Desktop as the engine — overruled (operator: no UI interaction, lightest footprint) → Colima.
- Git worktrees per job (`--worktree`) — would have exposed the mission board/gold files to workers and breaks git inside the container; and `hermes-pilot/<job>` branch names collide with the `hermes-pilot` branch (git D/F conflict). Jobs use copied inputs instead.
- A haiku worker reported two Keychain items as absent (both present) and said DONE — security-relevant preflight values are re-verified by the foreman from its own shell.
- Fable consult budgeted at ~$0.50 cost ≈ $1.0–1.4: the Agent tool prepends ~50–80k tokens of tool schemas even when told "no tools" — quote ≥$1 (doctrine amended).
- Cross-vendor (Codex) review remains unavailable (vendored binary ENOENT); all reviews single-vendor (fresh Opus agents), labelled as such.
- HQ's proof-gate hook (`scripts/proof-gate.sh`) blocks any Bash command whose text matches `git … (publish|land)`-shaped patterns while `~/.claude/.proof-needed` is set — including a local file write whose sed text merely mentioned those words. Keep such words out of command strings; clear the flag properly via a clean `/proof-check` (the `PROOF_OK=1` prefix does not work — Lesson 8).

## Open Threads & Next Actions  (numbered; mark DONE in place, never delete)
1. ⭐ NEXT (operator-confirmed 20:10; landing DONE 20:20 — main @ 43919af, `hermes-pilot` published @ 12f63a2, vault 0/0): S2 = **T6** (sonnet, read-only mechanisms/schema ticket on `repos/hermes-agent` @ `hq-hardened` 4dee451: items a–l in PLAN v2.1j) preceded by a tiny **T3g** (enforce `HERMES_ENGINE_DOCKERFILE_PATH_OVERRIDE` as test-only — BACKLOG R1). Via `hq-foreman`, one wave per session; re-estimate token bands ×3–4.
2. Hermes pilot: fold `run/hermes-pilot/lessons-candidates.md` into LESSONS.md at T22 (or earlier on operator go): uv/brew gate gap; `timeout` absent; haiku Keychain misreport; `plutil -lint`; core-not-plugin; NEW: fence verify traces routes not readers; guard fallbacks default CLOSED.
3. On or after **2026-09-16**, run the claude-mem cost re-measurement (baseline + escalation rule in `project_google_cloud_bill_trace_2026_09_02.md`). [carried]
4. Decide whether `Bash` belongs back in the crg hook matcher (`02910ee` dropped it). Operator call. [carried]
5. Flip BACKLOG item (4) "settings.json writer UNKNOWN" → RESOLVED (it was Sunil's concurrent session `02910ee`). [carried]
6. Tidy the untracked scratch files in `~/claude-hq` (`*.rtf`, `*.bak-*`, `history.db.pre-migration-backup`, `quota-incident-2026-04-28/`, `model-router.py.backup-*`, `.handoff-last-session`) — keep-or-remove. [carried; two new reminders.json backups added today]
7. Hermes upstream facts to carry: `claude-code/0.1.0` User-Agent is sent to api.kimi.com by `auxiliary_client` (T3e's top-of-function guard on `build_anthropic_client` also closes this route); `hermes model`/`auth add anthropic` now fail with a RuntimeError traceback (fails closed, cosmetic); `mcp_catalog._run_bootstrap` runs catalog strings through the shell (pilot forbids MCP installs); `hermes_cli/providers.py` keeps a second, unguarded provider overlay (display-only today — BACKLOG).
- DONE 2026-09-03: Hermes eval + plan + two reviews + P0 (T1–T5) + proof-check — see auto-memory note for the full timeline.
- DONE 2026-09-03: stuck May reminder `paperclip-watchdog-soak-end-2026-05-22` removed; BACKLOG listener item verified stale → Done.
- DONE 2026-09-02: adopt the concurrent session's hardened hook — landed by Sunil in `02910ee`.
- DONE 2026-09-02: proof-check the cost/hook work — blind Opus verifier PASS_WITH_NOTES; 3 LOW filed to BACKLOG.

## Runtime / Environment
- **Nothing pilot-related running.** Colima STOPPED (engine script leaves it down; `bash run/pilot-tree/skills/hq-hermes/scripts/hermes-engine.sh status` to check). Docker Desktop not running. Docker CLI context is now `colima` (was `default` — restore at uninstall). [firsthand][confirmed]
- Pre-existing, unrelated to the pilot: Ollama at 127.0.0.1:11434 (llama3.2 only; the pilot's 64k coder model is NOT pulled yet — T7); Paperclip server on 127.0.0.1:3100 (PID 1307 earlier today); claude-mem worker (port 37777, per the 09-02 handoff — not re-verified today). [firsthand for Ollama/Paperclip][relayed for claude-mem]
- Git: main tree `~/claude-hq` on `main` @ `43919af` = origin/main (clean, untracked scratch only); pilot worktree `run/pilot-tree` on `hermes-pilot` @ `12f63a2` = origin/hermes-pilot (published 20:20, clean); Hermes checkout `repos/hermes-agent` on `hq-hardened` @ `4dee451` (local only — gitignored checkout, never pushed), clean except the known case-collision file `contributors/emails/agent@Agents-Mac-mini.local`. [firsthand][confirmed]
- Proof-gate flag `~/.claude/.proof-needed`: **CLEARED 20:07 +08** after re-run #3 CLEAN (T3e + T3f fixed 6 HIGH + 5 MEDIUM; 2 MEDIUM residuals in BACKLOG). NOTE: writing any file whose path contains `proof-check` re-arms the flag (hook regex) — clear it again after saving a review record. [firsthand][confirmed]
- Hermes home `run/hermes-hq` exists (first-run dirs only: state.db, sessions, logs, empty skills; NO config.yaml/.env/auth.json); `~/.hermes` absent. [firsthand][confirmed]
- Keychain: `claude-hermes-groq` present (pilot); `Claude Code-credentials` present (the item the fence protects). [firsthand][confirmed: presence only]
- Session model: Opus 4.8; Fable used once today (planning consult, logged in `run/cost-ledger.sqlite`).

## Pointers  (links, never copies)
- Constitution: `CLAUDE.md`, `commander/COMMANDER.md`, `docs/ORGANIZATION.md`
- **Hermes pilot plan (living, v2.1f):** `run/pilot-tree/skills/hq-hermes/PLAN-v2-2026-09-03.md` · reviews: `…/skills/hq-hermes/reviews/{adversarial-review,gate0-review,proof-check,proof-check-rerun,proof-check-rerun3}-2026-09-03.md` · Fable draft: `…/PLAN-fable-2026-09-03.md`
- Hermes pilot run-state: `run/hermes-pilot/` (preflight.json, scan-*.txt, freeze.txt, removed-providers.txt = census, engine-bench.json, engine-last-probe.txt, lessons-candidates.md)
- Hermes pilot full timeline + rulings + paste-ready RESUME PROMPT: auto-memory `project_repo_eval_hermes_agent_2026_09_03.md` (index line in MEMORY.md)
- Hermes analysis + scout reports: vault `Projects/claude-hq/Analyses/2026-09-03 Hermes Agent — Route-Level Embed Analysis.md` + sibling folder `… — scout reports/`
- Vault Decision Log: `JARVIS-BRAIN/Projects/claude-hq/Decision Log.md` (four 2026-09-03 entries appended) · Hub "Current State" block added 2026-09-03
- Cost trace (09-02): auto-memory `project_google_cloud_bill_trace_2026_09_02.md`; the switch `scripts/cloudrun-power.sh`
- BACKLOG: `docs/BACKLOG.md` (Phase-2 gateway heading = the pilot's parent item; listener item flipped Done 09-03; proof-check residuals item added 09-03)
