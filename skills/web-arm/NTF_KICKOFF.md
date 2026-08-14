# NEVER TOO FAR — SESSION KICKOFF
## The web arm's first mission · written 2026-08-14 at the close of the activation session
## Facts below were disk-verified at write time; the boot sequence RE-verifies — on conflict, DISK WINS.

---

## BOOT SEQUENCE — execute in order, BEFORE any design work

1. **`/effort max`** (HQ mandate, always first).
2. **Read `~/claude-hq/skills/web-arm/HANDOFF.md` in full** — the canonical state of the arm
   (tracker + rulings + dead ends). Run its **RECONCILE block** verbatim; report any drift and
   trust the disk over the doc.
3. **Read `~/claude-hq/skills/web-arm/LIBRARY.md`** — the routing law for ALL design work:
   find the job's row, pull ONLY the named lead + support tools, stop. No rummaging. The §0
   inheritances and §10 held/dropped list bind.
4. **Verify the six MCP handshakes** — first session since registration: superdesign ·
   lightpanda · shadcn · magicui · aceternityui · figma should now CONNECT. Method: check
   whether each server's tools are callable in-session (ToolSearch/listing) — do NOT try
   `claude mcp list`; that subcommand doesn't exist in this build (HANDOFF dead-end). If a
   server is config-present but tools-absent, report it as AMBIGUOUS (possibly deferred
   loading), log a fix-forward item in the HANDOFF tracker, and continue — not a blocker.
5. **Check the OFFLIMITS drive is mounted** (`/Volumes/Elements/My_Stuff/OFFLIMITS`). If not,
   ask the operator to mount it — do not create substitute folders elsewhere.
6. **Report boot status in plain English** (per-step results, ~10 lines max), then **STOP AND
   AWAIT the operator's design/build instructions.** The brief comes from another source, via
   the operator. Until it arrives: no designing, no scaffolding, no cloning, no npm installs,
   no site extraction. Reading the mission context below and the inspiration images is permitted.

## THE MISSION (context — NOT the brief; the operator's forthcoming instructions govern)

- **Client:** CIRRANEU (Alex Soliman). **Project:** re-craft the existing Never Too Far website.
- **⭐ REQUIRED READING — the brand's governing documents (landed 14 Aug 2026, AFTER the arm
  was built; they supersede any older "no locks" claim):**
  `/Volumes/Elements/My_Stuff/OFFLIMITS/_CLIENTS/CIRRANEU/PROJECTS/NEVER_2_FAR/PREMISE/`
  - `NEVER_2_FAR_Founding_Premise_v1.md` — positioning, brand mandate, the Drift Check
  - `NEVER_2_FAR_Creative_Direction_v1_The_Postcard_Home.md` — **LOCKED 14 Aug 2026**; names
    the website as the brand's first expression. Its own rule binds: *"If an execution
    contradicts either document, the execution drifts, not the documents."*
- **Reference material — 30 images**, organised into the direction's two pillars, at
  `…/NEVER_2_FAR/INSPIRATION/`: `POSTCARD/` (11) · `WATER_COLOUR/` (18) ·
  `_WATERCOLOUR_POSTCARD.png` (the composite synthesis board).
- **Quality bar (operator's own words):** "looks like it's like a team of five and you spent
  20k to build out the website."
- The operator will still supply build instructions separately; those + the PREMISE documents
  are the authority. Everything in this file is setup, not scope.

## STANDING RULINGS (operator, 2026-08-12→14 — settled; do not re-litigate)

1. **Front-end focus.** The arm designs and builds the front end. Light back-end hooks only
   (LIBRARY §9); external partners own databases, payments, full back-end builds.
2. **Costs/hosting/technicalities PARKED** until the operator raises them — EXCEPT use-time
   cost gates, which ALWAYS fire before spend: scroll-world ≈ $27/6-scene chain; Higgsfield
   credits (engine caps apply); screenshot-to-code needs an LLM API key. Surface, get the go, log.
3. **Brand locks EXIST in non-canonical form** — the PREMISE pair above (Founding Premise +
   LOCKED Creative Direction) are the governing brand documents, authored 14 Aug. What does
   NOT yet exist are the OFFLIMITS-canonical artifacts (PERSONA_BRIEF, BRAND_SYSTEM,
   VOICE_GUIDE, 03_PLAYBOOKS — verified absent by filename). The operator's soft+bidirectional
   groundwork ruling now means: the web build EXTENDS the locked direction (and may feed the
   future canonical BRAND_SYSTEM) — it does NOT author a direction from scratch.
4. **Quarantine law:** never restore any `*.quarantined` file/dir under `~/claude-hq/repos/web-arm/`;
   any git restore/checkout there re-arms them (the RECONCILE block detects it — re-sweep).
   Any NEW clone gets the root-file + config-dir sweep before anything reads it (live-fire
   precedent, 2026-08-14).
5. **New tools beyond the armed set** route through the Trust Gate per
   `ACTIVATION_PLAN.md` G-mechanics. The armed set is large — check LIBRARY first.

## KICKOFF DECISIONS — OPEN, surface when the brief arrives (not before)

1. **Where the NTF project code lives** — inside the OFFLIMITS client folder (external drive;
   git + node_modules on it is a real consideration) vs its own repo. Never ruled — carried as
   review finding H5 in `project_offlimits_web_arm_build_2026_08_12.md` (memory). Operator decides.
2. **ditto.site mode** for extracting the current live site — hosted API (signup) vs self-host
   (Postgres+S3) vs its MCP. LIBRARY §2 names it the re-craft primary.
3. **Which staged Lane-7 deps the scaffold pulls** — pinned per-project, never `npm -g`:
   shadcn init, daisyui, motion, gsap, axe-core, Lighthouse, Playwright visual-regression.
   skiper40 requires **visible attribution** on the free tier — a client-site question.
4. **Pipeline registration** — instantiate NTF via OFFLIMITS `/pipeline new` conventions
   (client `00_PIPELINE.md`) now or after the brief. Note: web work has no pipeline stage yet;
   that placement (fork after Stage 3) was discussed 2026-08-12 but never landed in PIPELINE.md.

## PHASE GATES (standing order, every pivotal phase)

`/ctdd-precheck` before any recommendation · `/adversarial-review` + `/proof-check` at phase
boundaries (CRITICAL/HIGH block) · `/handoff save` at checkpoints — **HANDOFF.md is the sole
state doc; keep its tracker current as work lands, statuses only with disk evidence** ·
plain-English reporting; `/laymans` on request · `/hq-foreman` for multi-step orchestration
(explicit `model:` per dispatch; Opus execution ceiling).

## POINTERS (read, never copy)

- State: `~/claude-hq/skills/web-arm/HANDOFF.md` · Routing: `LIBRARY.md` ·
  Build record: `ACTIVATION_PLAN.md` · Scans: `g1-scan-results.txt` · Pins: `.provenance`
- Armoury (visual): https://claude.ai/code/artifact/1e550843-2a26-4f28-9082-db8b92164964
- Memory: `project_offlimits_web_arm_build_2026_08_12.md` (auto-loads via MEMORY.md index)
- OFFLIMITS side: `/Volumes/Elements/My_Stuff/OFFLIMITS/PIPELINE.md` (v1.8) ·
  `_CLIENTS/CIRRANEU/` · deck system at `/Volumes/Elements/My_Stuff/OFFLIMITS/OFFLIMITS/system/`
  (nested dir — the house design-system precedent: tokens, client-skin pattern, instantiation protocol)

---

## THE PASTE-PROMPT (operator: paste this into the new session)

> Never Too Far kickoff. Read `~/claude-hq/skills/web-arm/NTF_KICKOFF.md` and execute its
> BOOT SEQUENCE exactly: /effort max → resume from the web-arm HANDOFF and run its RECONCILE
> block → load LIBRARY.md routing → verify the six MCP handshakes → confirm the OFFLIMITS
> drive is mounted (if not, ask me to mount it — never create substitute folders) → read the
> two PREMISE documents (the locked brand direction) → report boot status in plain English,
> then STOP and await my design/build instructions. Do not start any design or build work
> until I provide the brief.
