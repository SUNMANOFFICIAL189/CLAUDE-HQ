# WEB ARM — GENERIC ACTIVATION (any website project, any client)
## The project-agnostic boot. For Never Too Far specifically, use NTF_KICKOFF.md instead.

## BOOT SEQUENCE — in order, before any design work
1. **`/effort max`** (HQ mandate, always first).
2. **Read `~/claude-hq/skills/web-arm/HANDOFF.md` in full** — the arm's canonical state.
   Run its **RECONCILE block** verbatim; on any mismatch, trust the disk and report the drift.
3. **Read `~/claude-hq/skills/web-arm/LIBRARY.md`** — the routing law: for every design/build
   job, find the row, pull ONLY the named lead + support tools, stop. §0 inheritances and
   §10 held/dropped bind. No rummaging.
4. **Verify the MCP roster connects** (superdesign · lightpanda · shadcn · magicui ·
   aceternityui · figma): tools callable in-session. Do NOT try `claude mcp list` (dead end
   in this build). Config-present-but-tools-absent = AMBIGUOUS → log fix-forward, continue.
5. **If the project is OFFLIMITS-side:** confirm `/Volumes/Elements/My_Stuff/OFFLIMITS` is
   mounted (never create substitute folders); check `_CLIENTS/<client>/` for existing brand
   material — **by content, not just by canonical filename** (the NTF lesson: locks can exist
   under non-standard names; sweep PREMISE/, PROJECTS/, root docs before declaring a blank sheet).
6. **Report boot status in plain English, then await the operator's brief.** No designing,
   scaffolding, cloning, or installs before the brief.

## STANDING LAW (every project — do not re-litigate)
- **Front-end focus**; light back-end hooks (LIBRARY §9); partners own heavy back-end.
- **Use-time cost gates always fire** before spend: scroll-world ≈$27/chain · Higgsfield
  credits · screenshot-to-code LLM key. Surface → operator go → log.
- **Quarantine law**: never restore `*.quarantined` under `repos/web-arm/`; sweep every NEW
  clone (root instruction files + agent-config dirs) before anything reads it.
- **New tools** beyond the armed set → Trust Gate per `ACTIVATION_PLAN.md` G-mechanics.
- **Client dress, house machinery**: the client's brand governs every visual decision; the
  arm never imposes a house look (deck-system principle, LIBRARY §0 inheritances where the
  OFFLIMITS locks exist).
- **Per-project decisions to surface at kickoff**: where the project code lives (per-project
  ruling — see H5 in `project_offlimits_web_arm_build_2026_08_12.md`) · which staged Lane-7
  deps the scaffold pulls (pinned per-project, never `npm -g`) · pipeline registration.
- **Phase gates**: `/ctdd-precheck` before recommendations · `/adversarial-review` +
  `/proof-check` at phase boundaries · `/handoff save` at checkpoints (tracker current,
  statuses only with disk evidence) · `/hq-foreman` for multi-step orchestration.

## OPERATOR TRIGGER PHRASES (any of these = run this file)
"activate the web arm" · "web arm" + a project/site ask · "design/build a website for <x>" ·
"new website project"

## THE PASTE-PROMPT (generic — fill the last line per project)
> Activate the OFFLIMITS web arm. Read `~/claude-hq/skills/web-arm/ACTIVATE.md` and execute
> its BOOT SEQUENCE exactly: /effort max → resume from the web-arm HANDOFF and run its
> RECONCILE block → load LIBRARY.md routing → verify the MCP roster → check for existing
> brand material by content, not just filename → report boot status in plain English, then
> STOP and await my brief. Do not start any design or build work until I provide it.
> Project: <client / project name>. Brief source: <me / a document I'll point you to>.
