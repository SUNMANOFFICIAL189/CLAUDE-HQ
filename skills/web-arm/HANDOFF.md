# HANDOFF — OFFLIMITS Web Design Arm (activation build)

> Single source of truth for resuming this project with zero context lost.
> **The code is authoritative. If this document and the code disagree, the CODE WINS.**
> Written only by the `/handoff` skill. Never store secrets here: environment-variable NAMES only.
> Deep detail lives in the linked canonical files (this doc is a map, not a dump).

- Schema: handoff/v1
- Canonical path: /Users/sunil_rajput/claude-hq/skills/web-arm/HANDOFF.md
- Constitution: /Users/sunil_rajput/claude-hq/CLAUDE.md (HQ mechanics) + ./ACTIVATION_PLAN.md (this build's charter — gate mechanics G1–G5, classes, phases)
- Last refreshed: 2026-08-14 17:20 — mid-wave checkpoint after Classes 1–3 — manual

---

## Goal
Arm the OFFLIMITS **web design arm**: activate/install the operator's 41-item toolkit (7 lanes),
verify it, and build the job-indexed **TOOLS LIBRARY** routing layer — so websites can be built by
prompting/vibe-coding with agents pulling exactly the right tool per job. Front-end focus; partners
own heavy back-end. **Nothing on Never Too Far (the first client site) starts until the arm is armed.**

## Current State
Mid-execution of the approved activation plan, Classes 1–3 complete and live. The plan survived a
FAIL adversarial review (3 CRIT + 7 HIGH — all gate-integrity), a full rewrite with executable gate
mechanics, and a delta re-verify (PASS_WITH_NOTES, 3 fix-introduced defects also fixed). The rollback
checkpoint exists. All four source collections were refreshed from upstream (operator ruling 2) and
every activated item passed its first-ever content scan. The 16 skills + frontend-design went live
in-session without restart; the 4 agent personas registered as live agent types — **confirming the
user-scope `~/.claude/agents/` assumption (review finding H6) by direct observation** [firsthand][confirmed].
- 2026-08-14: Checkpoint set; 4 upstreams refreshed; 20/20 G1 scans PASS; 16 skills vendored+linked;
  4 agents installed (context-manager handshake stripped, 0 residuals); superdesign+lightpanda
  registered user-scope; frontend-design vendored from official marketplace [firsthand][confirmed]
- 2026-08-14: vercel find-skills DEFERRED to BACKLOG by operator ruling [firsthand][confirmed]
- 2026-08-14: This `claude` CLI build has NO `mcp add` / `plugin` subcommands — direct config edits
  used instead; MCP servers connect on next session start [firsthand][confirmed]
- 2026-08-14 **LIVE-FIRE INJECTION EVENT:** the harness auto-loaded the cloner template's root
  `CLAUDE.md`+`AGENTS.md` into session context — the exact surface the plan flagged, at a path the
  quarantine missed (root files, not `.claude/`). Content benign, treated as data. Hole closed:
  root-sweep quarantined 12 instruction files across 6 of 10 clones + the 3 Lane 4 sources
  [firsthand][confirmed]. **Standing rule: every future clone gets the root-file sweep too.**

## ⚙ THE ACTIVATION TRACKER (the no-drift system)
**Rules: a status is a CLAIM; disk is TRUTH. Flip a status only with the evidence column filled.
On any resume, run the RECONCILE block below BEFORE trusting this table. Never mark DONE from memory.**

### Lane 1 — disk activations · **DONE 21/21**
| Item | Status | Evidence |
|---|---|---|
| 14 mega skills (design-orchestration, scroll-experience, tailwind-patterns, core-components, react-ui-patterns, interactive-portfolio, 3d-web-experience, web-design-guidelines, web-performance-optimization, seo-audit, seo-fundamentals, schema-markup, programmatic-seo, geo-fundamentals) | DONE | symlinks in `~/.claude/skills/` → `web-arm/`; scans in `./g1-scan-results.txt`; live in session listing |
| artifacts-builder (awesome copy; mega twin DROPPED per ruling 6) | DONE | same |
| humanizer | DONE | same |
| frontend-design (official — **Lane 3**, folded into this table) | DONE | symlink; G1 scan PASS **logged** in g1-scan-results.txt (appended after verifier F2); live in listing |
| 4 agents: ui-designer · frontend-developer · ux-researcher · accessibility-tester | DONE | `~/.claude/agents/*.md`; live as agent types (observed 2026-08-14); handshake stripped — BOTH forms (hyphen + space + JSON blocks), re-verified 0 residuals after verifier F1 caught 2 survivors |
| Source pins | DONE | `./.provenance` (mega@77a348f81 · awesome@be2a406 · humanizer@523374d) |

### Lane 2 — re-wires · **DONE 2/2 (connect-check pending restart)**
| Item | Status | Evidence |
|---|---|---|
| superdesign MCP → user scope | REGISTERED | `~/.claude.json` mcpServers.superdesign → node + repos/superdesign-mcp/dist/index.js |
| lightpanda MCP | REGISTERED | mcpServers.lightpanda → /usr/local/bin/lightpanda mcp |
| Handshake test both | PENDING | requires next session start (registrations load at launch) |

### Lane 5 — gated skill packages · **10/12 WIRED · 2 BLOCKED awaiting operator ruling**
| Item | Status | Evidence / notes |
|---|---|---|
| shadcn skill | DONE | scanned+wired; source `repos/web-arm/shadcn-ui @ d4fc45b1fbab` |
| gsap ×5: core · timeline · scrolltrigger · react · performance (ruling 5) | DONE | scanned+wired; `gsap-skills @ aed9cfd32777` |
| emil ×3: pick-ui-library · review-animations · animate | DONE | scanned+wired; `emil-skills @ 78761e1b57f9`. FOUR siblings remain unwired (animation-vocabulary · apple-design · ask-sonner · prototype — all pre-scanned PASS in coverage closure). registry.json singular→plural fix LANDED @6400bc3 |
| emil ×2: improve-animations · find-animation-opportunities | DONE — **operator override 2026-08-14** | Gate HARD FAIL = verified FP (skills' own anti-injection rule quotes the attack phrase, SKILL.md:25/:21; June impeccable precedent). Operator: "override the two, and continue." Override note appended to scan log. Wired. |
| scroll-world | DONE | scanned+wired from oso95 exactly; `scroll-world @ 71cc36d3bb15`; use-time cost ~$27/chain — rail-3 gate per use |
| ~~find-skills (vercel-labs)~~ | DEFERRED | operator ruling → HQ BACKLOG 2026-08-14 entry |

### Lane 6 — reference clones · **DONE 10/10 (2026-08-14)**
All cloned via logged G4 overrides into `~/claude-hq/repos/web-arm/`, SHA-pinned in `./.provenance`,
G1-scanned (log: `./g1-scan-results.txt`). 8 clean. 2 flagged → reviewed with evidence:
| Flag | Ruling |
|---|---|
| cult-ui — "new system prompt" in `prompt-library.json` | FALSE POSITIVE — a shadcn-registry component named prompt-library; UI copy, not injection. Cleared for reference. |
| screenshot-to-code — `curl \| python3` in `scripts/cursor-cloud-install.sh:7` | Benign-standard (official Poetry installer) but the pattern is real → **script NEVER-EXECUTE**; app runs only at NTF with deliberate installs. Cleared for reference reading. |
ai-website-cloner-template: **12 agent-config dirs quarantined** (`.claude` → `.claude.quarantined`
etc.) — permanent; the harness never auto-loads another repo's instructions. Instatic = clone+scan
only, routed to the parked CMS conversation.

### Lane 4 — new MCP servers · **4 REGISTERED (incl. figma via keychain) · 1 DROPPED · 1 HELD — final 2026-08-14**
| Server | Status | Detail |
|---|---|---|
| shadcn (official) | REGISTERED | `npx -y shadcn@4.18.0 mcp` — stdio; source = the scanned shadcn-ui clone |
| Magic UI (official org) | REGISTERED | `npx -y @magicuidesign/mcp@2.0.0` — source cloned+scanned PASS (`magicui-mcp @` .provenance) |
| Aceternity UI | REGISTERED, low-trust note | `npx -y aceternityui-mcp@1.0.2` — UNOFFICIAL 3rd-party wrapper, single maintainer, stale since 2025-07; source cloned+scanned PASS. Weakest provenance in the stack — replace if an official server appears |
| Figma-Context-MCP | **REGISTERED** (superseding the earlier HELD) | Via Keychain launcher `scripts/mcp-launchers/figma-mcp.sh`, pinned 0.13.2 + `--stdio`; keychain entry `claude-mcp-figma-api-key` CONFIRMED present 2026-08-14. Connects next session start |
| 21st.dev Magic | **DROPPED — operator ruling 2026-08-14** | Replaced by Magic UI + shadcn (both already live) + heroui reference shelf. (Was held on account+cost facts; operator chose replacement over subscription. M5 contradiction resolved — this row now matches LIBRARY §10.) |
| google-fonts-mcp | **HELD — does not exist** | No npm package found (only a PyPI namesake + GitHub near-misses). House `_TYPE/` library covers fonts; `Microck/font-mcp` unpublished. Route stays held per plan |
MCP note: registrations load at session start — handshake checks next session. New MCPs pinned;
their sources scanned (registered npm artifact ≠ repo bytes — honest approximation, noted).
Community shadcn wrappers DROPPED (ruling 3).

### Lane 7 — staged for NTF scaffold (no project exists yet) · **STAGED**
skiper40 (attribution question at use) · daisyui · motion · animejs · gsap runtimes · axe-core ·
Lighthouse · Playwright visual-regression — pinned per-project deps, NEVER `npm -g` (known gate hole).

### Phase 4 — verify · **WIDE PROOF-CHECK DONE (2026-08-14): PASS_WITH_NOTES → all findings fixed**
H1 (gsap-skills root files — Lane-5 sources were outside the sweep) + M1 (14 agent-config DIRS incl.
shadcn-ui/.claude with pre-granted Bash permissions) + M3 (dangling symlink) → ALL quarantined;
residual check EMPTY. M4 (stale RECONCILE expectations) + M5 (21st.dev contradiction) → corrected.
M2 → quarantine is working-tree-only; re-arm check added to RECONCILE. 8 unwired Lane-5 skill dirs
pre-scanned PASS (future-activation coverage). Notes carried: L6 (wired gsap/scroll skills reference
unwired siblings/personas — dead-end pointers, cosmetic) · L7 (live emil-design-eng = April copy from
~/.agents, differs from fresh emil-skills pin — re-vendor = OPEN option, not acted) · vendor bug
upstream: gsap-scrolltrigger SKILL.md:236 `Max.max` (faithful to source; agents copying that example
hit a ReferenceError). Verified solid: 29/29 skills parse · 0 collisions · config additions-only ·
18/18 pins match HEADs · scan log complete · 3 deep smoke reads clean.
**Record phase: CLEAR.**
Skills live-listing ✅ (all 29 observed in-session as they wired) · agents registered ✅ · **agent
INVOCATION test ✅ 4/4 (2026-08-14: each returned its persona mandate on a minimal haiku dispatch;
note — frontend-developer answered the name question with its base identity but recited the persona
mandate verbatim, so the persona prompt is loaded and steering)** · MCP handshakes PENDING (next
session start) · skill invocation smoke tests → folded into the wide /proof-check · wide /proof-check
over full wiring PENDING (after Lane 4) · armoury artifact status-flip PENDING.

### Phase 4.5 — **THE TOOLS LIBRARY** · **BUILT v1.0 (2026-08-14)**
`./LIBRARY.md` — job-indexed routing layer, 10 sections (§0 inheritances → §10 held/dropped),
lead-and-support per job, arbitration authority per H7, quarantine law + cost gates embedded.
Amendment rule: append-only with evidence. PENDING: fold any wide-proof-check findings.
Lane 4 updates same day: **21st.dev DROPPED by operator** (replaced by Magic UI + shadcn already live
+ heroui reference shelf — the cited vp0 blog is VP0's own marketing; its other 2 picks were already
ours). **heroui cloned+scanned** (flag = its own curl-installer lines in bundled skills → NEVER-EXECUTE
note; its heroui-react/native/migration skills = future gate candidates). **figma REGISTERED via
Keychain launcher** (`scripts/mcp-launchers/figma-mcp.sh`, mirrors exa pattern, pinned 0.13.2 +
--stdio) — waiting only on the operator's one-time `security add-generic-password` (entry name:
`claude-mcp-figma-api-key`); no keychain entry yet as of writing.

### Phase 5 — record · **LANDED @ `6400bc3` (2026-08-14, operator: "commit it")**
Committed+pushed to CLAUDE-HQ main: skills/web-arm/ (29 skills + handoff + library + plan + scan log
+ provenance) · figma-mcp.sh launcher · registry.json emil pointer fix · BACKLOG vercel entry ·
.claude/handoff-path pin. Both secret gates clean on staged bytes; watchdog files excluded (unrelated
pre-existing). Figma keychain entry CONFIRMED present — server connects next session start.
REMAINING (small): armoury artifact republish (status flips) · memory/vault sync (/save-grade) ·
optional L7 emil-design-eng re-vendor decision.

## RECONCILE block (run on EVERY resume — disk beats this doc; corrected per proof-check M4)
```
ls -la ~/.claude/skills/ | grep -c web-arm                      # expect 29
ls ~/.claude/agents/                                            # expect 4 .md files
python3 -c "import json,os;d=json.load(open(os.path.expanduser('~/.claude.json')));print(sorted(d['mcpServers']))"  # expect aceternityui, figma, lightpanda, magicui, shadcn, superdesign among them
git -C ~/claude-hq tag -l "pre-webarm*"                         # expect pre-webarm-activation-2026-08-14
ls ~/claude-hq/repos/web-arm/ | wc -l                           # expect 18 clones
cat ~/claude-hq/skills/web-arm/.provenance | wc -l              # expect 23 lines (18 repo pins + 5 source/house pins)
find ~/claude-hq/repos/web-arm -maxdepth 2 \( -name CLAUDE.md -o -name AGENTS.md -o -name .claude -o -name .agents \) ! -name "*.quarantined" ! -path "*/node_modules/*"   # expect EMPTY — non-empty = quarantine re-armed by a git op, RE-SWEEP before proceeding
```

## Decision Log  (append-only — newest on top)
- 2026-08-14 [Sunil] Override the two emil gate false-positives (improve-animations,
  find-animation-opportunities) and continue. Basis: verified FP — the flagged text is the skills'
  own anti-injection defense; June impeccable precedent (operator-authorized one-off override,
  author NOT allowlisted). Rejected alternative: leave blocked (8/10 emil skills would still serve).
- 2026-08-14 [Sunil] Handoff + tracker commissioned; library articulation CONFIRMED; "checkpoint and
  proceed" = plan approved. Rulings on the 6 calls: (1) approved incl ~20 G4 overrides (2) check
  upstream updates → done, all 4 refreshed (3) shadcn wrappers dropped (4) emil = web-relevant 5
  (5) gsap = most-relevant 5 (6) twin-drop confirmed. vercel find-skills → separate later task, logged.
- 2026-08-14 [Sunil] Tools LIBRARY commissioned: organised filing → correct tool found → token
  efficiency for prompt-driven site builds. Rejected alternative: none offered — extends plan's H7 fix.
- 2026-08-14 [Claude] Handoff home = `skills/web-arm/` (pinned via locate.sh --set). Rationale: the
  arm's durable git-tracked home; scratchpad = the documented loss risk. Rejected: repo-root
  HANDOFF.md (claude-hq hosts many missions; web-arm scope belongs with its assets).
- 2026-08-14 [Claude] frontend-design via vendored-skill route, not plugin machinery. Rationale: CLI
  lacks plugin subcommand; plugin = one-skill wrapper; house convention. Rejected: manual
  installed_plugins.json surgery (schema risk).
- 2026-08-14 [Joint] Plan gate trail: v0.1 adversarial FAIL (3C+7H) → v0.2 G1–G5 executable gates,
  vendored copies, rollback → delta PASS_WITH_NOTES → 3 fix-introduced defects fixed (override count
  ~20 enumerated; tag-ordering bug; H7 honesty). All reviews fresh-Claude lens (Codex CLI broken).

## What Didn't Work / Dead Ends
- `claude mcp add` / `claude plugin install` — **subcommands don't exist in this CLI build** (fall to
  generic help). Use direct `~/.claude.json` edits (backup first). Do not retry the CLI.
- `skill-install.sh` on nested `skills/<name>/` repo layouts → "could not locate skill". Use G4 clone
  + G1 + manual copy. Do not retry the installer for Lane 5.
- Naive checkpoint `git add -A skills/web-arm && git tag` — short-circuits if dir absent + dirties
  index. Tag unconditionally, no staging (already fixed in plan).
- `image-to-code-skill` (taste family) — capability INVERTED vs assumption: generates its own refs,
  cannot ingest supplied images. screenshot-to-code is the ingest tool. Do not wire i2c for NTF boards.
- Raw symlinks into live clones — upstream `git pull` would mutate live instructions silently.
  Vendored copies only (G2).

## Open Threads & Next Actions
1. ⭐ NEXT: **Phase 4 wide /proof-check** over the full wiring → then **Phase 4.5 LIBRARY.md** →
   Phase 5 record (commits with own go).
2. OPERATOR: (a) 21st.dev RESOLVED — DROPPED, replaced (ruling 2026-08-14). (b) Figma — token
   created; REMAINING: the one-time keychain add (`security add-generic-password -U -a "$USER"
   -s claude-mcp-figma-api-key -w <token>`), then next session start connects it.
3. Next SESSION START: MCP handshake checks (superdesign · lightpanda · shadcn · magicui ·
   aceternityui) — registrations load at launch.
   [DONE 2026-08-14: Lanes 1,2,3,5 (12/12 incl. 2 operator-overridden FPs), 6 (10/10, 2 flags
   reviewed benign), 4 (3 registered pinned / 3 held); agents 4/4 invocation-verified; live-fire
   injection event contained + root-sweep rule added.]
3. Lane 4 — ~6 MCP servers, pinned (G3).
4. Phase 4 full verify (agent invocation test · MCP handshakes next session · smoke tests · wide proof-check).
5. Phase 4.5 — build `LIBRARY.md` from this tracker.
6. Phase 5 — record + /sync commits (own go).
7. (BACKLOG) vercel find-skills as its own task · Codex CLI repair (no cross-vendor review lens) ·
   hook-regex hardening offer.
8. Then: NTF kickoff — brand groundwork first (operator will build; bidirectional with web design).

## Runtime / Environment
- Uncommitted (claude-hq): `skills/web-arm/` entirely UNTRACKED (17 vendored skills + this file +
  ACTIVATION_PLAN.md + scan log + .provenance) — commit only at Phase 5 with go. `docs/BACKLOG.md`
  modified (vercel entry + pre-existing edits). `watchdog/*.json` modified (pre-existing, unrelated).
- `~/.claude.json` EDITED (2 MCP entries); backup: `~/.claude.json.pre-webarm-2026-08-14`.
- Rollback: the undo table in ACTIVATION_PLAN.md + `~/.claude.json.pre-webarm-2026-08-14` are the
  REAL recovery path (the harness mutations live outside git). The tag `pre-webarm-activation-2026-08-14`
  only marks pre-wave repo HEAD — it cannot restore untracked/harness files (verifier F3).
- `~/.claude/agents/` created (4 files). No dev servers, no background jobs running.
- Working session artifacts also copied here (durable): ACTIVATION_PLAN.md, g1-scan-results.txt.

## Pointers  (links, never copies)
- Charter/plan: `./ACTIVATION_PLAN.md` — classes, G1–G5 gate mechanics, rollback, cost table
- Scan evidence: `./g1-scan-results.txt` · pins: `./.provenance`
- Memory: `~/.claude/projects/-Users-sunil-rajput/memory/project_offlimits_web_arm_build_2026_08_12.md`
  (rulings + gate record) + `project_offlimits_web_design_arm_inventory_2026_08_12.md` (the audit)
- Artifacts: Web Arm Armoury https://claude.ai/code/artifact/1e550843-2a26-4f28-9082-db8b92164964 ·
  OFFLIMITS Design Stack https://claude.ai/code/artifact/96011194-8b61-402a-a86f-ab5c56aaf7d6
- BACKLOG: `~/claude-hq/docs/BACKLOG.md` — 2026-08-14 vercel find-skills entry
- OFFLIMITS side: `/Volumes/Elements/My_Stuff/OFFLIMITS/PIPELINE.md` (v1.8) · NTF client folder
  `_CLIENTS/CIRRANEU/PROJECTS/NEVER_2_FAR/` · scope readback (scratchpad, superseded by plan)
