# WEB ARM — ACTIVATION PLAN v0.2
## (revised after adversarial review FAIL — 3 CRIT + 7 HIGH, all findings addressed below)
## STATUS: awaiting operator approval. NOTHING EXECUTES until the go.

**Mission:** turn the operator's 41-item list into a working, gated, wired toolkit. No design work on
Never Too Far until done (tools-first ruling). Front-end focus; hosting/costs parked except where a
listed item carries a cost — itemized honestly in §COST.

---

## ⟨OPERATOR CALLS⟩ — the six decisions this plan needs from you (everything else is routed)

1. **Approve the plan overall** — including the fact that **~20 external clones** require a logged,
   per-repo Trust-Gate override (authors not allowlisted; the ambient gate would block the clones).
   The full G4-routed set: CLASS 6 (cult-ui · kokonutui · bklit-ui · ai-website-cloner-template ·
   Website-downloader · screenshot-to-code · ditto.site · anime · motion · Instatic = 10) + CLASS 5
   source repos (shadcn-ui/ui · vercel-labs/skills · greensock/gsap-skills · oso95/scroll-world ·
   emilkowalski/skills = 5) + CLASS 4 MCP source repos (~5: Aceternity/Magic-UI/21st.dev/
   Figma-Context/google-fonts servers — exact URLs captured from the graded research at gate time
   and recorded in the manifest; note the official shadcn MCP ships inside the shadcn-ui/ui clone
   already counted). Your approval = approval of this enumerated set, each clone logged and G1-scanned
   before anything reads it. Any repo NOT on this list needs a fresh yes.
2. **Stale-vs-fresh:** activate the collection skills from the Jan-2026 clones as-is (default), or
   re-pull fresh first (re-opens scanning per item)?
3. **shadcn wrappers:** recon found shadcn CLI 3.0+ ships an OFFICIAL FREE MCP. Plan drops your two
   community wrappers (shadcn-registry-mcp / shadcn-ui-mcp-server) as redundant trust surface and
   keeps official MCP + first-party skill. **This re-rules two items you listed — confirm.**
4. **emilkowalski siblings:** activate 5 web-relevant now (pick-ui-library, review-animations,
   improve-animations, find-animation-opportunities, animate — default) or all 7 (+apple-design,
   +ask-sonner)?
5. **gsap-skills modules:** 5 of 8 now (core, timeline, scrolltrigger, react, performance — default)
   or all 8 (+plugins, +utils, +frameworks)?
6. **artifacts-builder twins:** your items 6 and 11 are byte-identical (verified — same description
   line; one is a rename of the other). Plan activates ONE (the awesome-claude-skills copy). Confirm.

---

## GATE MECHANICS (new section — closes review findings C1/C2/C3)
The review proved the gate's scripts cannot cover three of the plan's routes as originally written.
The plan no longer *names* a gate — it *specifies the commands*:

**G1 — Pre-activation content scan (CLASS 1, and every clone before first read):**
```
source ~/claude-hq/scripts/lib/magika-core.sh
source ~/claude-hq/scripts/lib/secret-scan.sh
magika_scan <dir> && secret_scan <dir>       # non-zero exit = item BLOCKED, logged, surfaced
```
Runs per skill directory BEFORE it is vendored/linked. The collections have never been content-scanned
(verified: one post-scan hit in 107k log lines) — this is their first real scan.

**G2 — Vendored-copy activation (replaces raw symlinks; closes M6):**
Activated skills are COPIED into `~/claude-hq/skills/web-arm/<name>/` (git-tracked, stable bytes),
then symlinked from `~/.claude/skills/<name>`. A later `git pull` in a collection clone can no longer
silently rewrite live instructions. Refresh = deliberate re-vendor, which re-triggers G1.

**G3 — MCP registration gate (CLASS 4 — no automatic gate exists for `claude mcp add`):**
Per server: clone its source repo (G4 route) → G1 scan → register with an EXACT PINNED version
(`npx -y <pkg>@<X.Y.Z>`, never `@latest`) or run from the scanned local build. Version recorded in
the manifest. No pin available = item held, surfaced.

**G4 — External clones (CLASS 6):** authors not allowlisted → each clone runs as
`HQ_TRUST_OVERRIDE=1 git clone <full-url> <absolute-target-dir>` — the override is logged by the
gate, one per repo, authorized by ⟨CALL 1⟩. Bare-URL + absolute-dir form only (the post-scan's
inference breaks on other forms). G1 scan immediately after, BEFORE any read. Any `.claude/` /
`.cursor/` etc. directory inside a clone is renamed `.claude.quarantined` until its contents pass G1
(ai-website-cloner-template ships one — auto-loaded instruction surface).

**G5 — skills-CLI items (CLASS 5):** `skill-install.sh` cannot resolve `skills/<name>/` nested
layouts (verified). Route = G4 clone + G1 scan + manual copy of the skill dir into the vendored home.
scroll-world: pin = full URL `https://github.com/oso95/scroll-world` + commit SHA captured at gate
time (a same-named fork by another owner exists).

**Known-fragile hook paths (M3, noted not relied on):** `npx --yes skills add`, `skills@latest`,
`bunx`/`pnpm dlx` variants and `npx shadcn add` all bypass the block hook. Doctrine for this wave:
installs happen ONLY via the G-routes above; no CLI installer is trusted to gate itself. (Hook-regex
hardening = BACKLOG offer; the operator previously chose to leave gate holes open.)

---

## ROLLBACK (closes H1 — the harness mutations live OUTSIDE claude-hq's tree)
**Before Phase 2 (the FIRST mutation — vendoring is Phase-2 work, so the checkpoint precedes it):**
```
cp ~/.claude.json ~/.claude.json.pre-webarm-2026-08-14
git -C ~/claude-hq tag pre-webarm-activation-2026-08-14   # unconditional, tags HEAD as-is
```
(Vendored files are NEW paths — undo = delete `skills/web-arm/`; they get committed only at Phase 5
with its own go. No staging at checkpoint time — a dirty index would trip Phase 3's own verify step.)
Undo table: skills → `rm ~/.claude/skills/<name>` (symlink) · agents → `rm ~/.claude/agents/<name>.md`
· MCPs → `claude mcp remove <name>` · plugin → uninstall via marketplace · config → restore the .json
backup. A half-completed wave is recoverable by class.

---

## THE SEVEN CLASSES (counts corrected per H2)

### CLASS 1 — Activate from disk: **17 skills + 4 agents**
*Skills, by source (three sources, not one — L2):*
- **agent-skills-mega (15):** design-orchestration · scroll-experience · tailwind-patterns ·
  web-artifacts-builder~~ *(dropped as twin — ⟨CALL 6⟩)* · core-components · react-ui-patterns ·
  interactive-portfolio · 3d-web-experience · web-design-guidelines · web-performance-optimization ·
  seo-audit · seo-fundamentals · schema-markup · programmatic-seo · geo-fundamentals
  → 14 activate if ⟨CALL 6⟩ confirms the twin-drop
- **awesome-claude-skills (1):** artifacts-builder
- **repos/humanizer (1):** humanizer
*Mechanic:* G1 scan → G2 vendor+link, serial, per-item failure isolation.
*Agents (4):* ui-designer · frontend-developer · ux-researcher · accessibility-tester →
`~/.claude/agents/*.md`. **ASSUMPTION (H6): user-scope agents dir is believed read by Claude Code but
unverified on this machine — Phase 4 invokes each agent once; if the path doesn't load, fallback =
project-level `.claude/agents/` in the NTF scaffold.** At install, strip each persona's mandatory
"context-manager" handshake preamble (that agent doesn't exist here; verified present in the files).

### CLASS 2 — Re-wires (2): superdesign MCP → user scope · lightpanda → `claude mcp add`

### CLASS 3 — Official plugin (1): frontend-design from claude-plugins-official (allowlisted).
Absorbs item 36 (same skill, 3 distribution channels — one route).

### CLASS 4 — New MCPs, all via G3: official shadcn MCP · Aceternity · Magic UI · 21st.dev Magic ·
Figma Dev Mode / Figma-Context ⟨needs Figma account state⟩ · google-fonts-mcp/font-mcp ·
(ditto.site MCP option deferred to NTF kickoff). Community shadcn wrappers dropped per ⟨CALL 3⟩.

### CLASS 5 — Gated skill-dir installs, all via G5: shadcn skill (first-party, `skills/shadcn/` in
shadcn-ui/ui) · find-skills (vercel-labs — **full Tier C: cooling-off expired, NOT re-admitted to
allowlist; ledger criteria (b)/(c) remain unverified, so doctrine's posture is full-scrutiny, which
is the route taken**; its "self-install skills" teaching is overridden by G-route doctrine) ·
gsap-skills modules ⟨CALL 5⟩ · scroll-world (SHA-pinned; **use-time cost ~$27/6-scene chain in
Higgsfield+Monid credits — rail-3 cost gate fires per use**) · emilkowalski/skills siblings ⟨CALL 4⟩
(+ fix the stale `emilkowalski/skill.git` source pointer in registry.json).

### CLASS 6 — External clones, all via G4+G1 into `~/claude-hq/repos/web-arm/`:
cult-ui · kokonutui · bklit-ui (charts MIT; Studio proprietary — components only) ·
ai-website-cloner-template (`.claude/` quarantined per G4) · Website-downloader (mirror/backup only) ·
screenshot-to-code (ingests user images — the image→code gap-filler; RUN deferred: needs LLM API key) ·
ditto.site (live-URL DOM→componentized code — primary NTF-recraft tool; hosting mode at NTF kickoff) ·
anime.js + motion (reference; runtime = CLASS 7) · Instatic (clone+scan only — routed to the PARKED
post-handoff CMS conversation, not the build kit).
*Site-capture trio is complementary, not duplicate: live-DOM extract / image→code / raw mirror.*

### CLASS 7 — Deferred to NTF scaffold: skiper40 (`npx shadcn add` runs inside a project; free tier
requires VISIBLE ATTRIBUTION — client-site question at use time) · daisyui · motion · animejs · gsap
runtimes · axe-core · Lighthouse · Playwright visual-regression — all pinned per-project deps with
manual review (**never `npm -g` — known gate hole**). Token bridge + component theming excluded
(operator: builds, not now).

**Animation ruling (recon):** Motion = house default (cult-ui + kokonutui already depend on it) ·
animejs = low-level/SVG specialist · gsap = the skills' runtime. Layered, not competing.

---

## PHASES
0. ✅ RECON — done (2 scouts; all 18 externals identified; no 404s).
1. DEDUPE + ROUTE — done above; six ⟨CALLS⟩ consolidated at top. Dupes resolved: frontend-design ×3
   channels → 1 · 21st.dev ×2 → 1 · emil = same-repo rename, ONE route (CLASS 5) · artifacts-builder
   twins → 1 ⟨CALL 6⟩ · shadcn skill ≠ shadcn MCP (both, different layers).
2. GATE — G1–G5 as specified. Per-item; failures stop that item only, logged, surfaced in the report.
3. WIRE — rollback checkpoint FIRST, then smallest-change order: CLASS 2 → 3 → 1 → 4 → 5 → 6.
   Serial. After each class: verify step (below) + `git -C ~/claude-hq status` + config-diff vs backup.
4. VERIFY — per-class acceptance (closes "3 smoke tests for 40 changes"):
   - Skills: every activated name present in the live skill listing + 3 representative invocations
     (one mega skill, one emil sibling, the shadcn skill).
   - Agents: **invoke each of the 4 once** (the H6 assumption test).
   - MCPs: handshake per server (tool listing non-empty) + superdesign generate + lightpanda fetch.
   - Plugin: frontend-design listed + trigger check.
   - Clones: G1 scan log exists per repo; quarantine confirmed on template repos.
   Then ONE wide /proof-check adversarial pass over the wiring diff + armoury artifact republished
   with flipped statuses.
5. RECORD — registry.json (+ corrected counts, + emil pointer fix), memory, vault Decision Log,
   BACKLOG residuals (hook-regex hardening offer; trigger-arbitration task). Commits get their own
   explicit go (Lesson 32).

**Trigger arbitration (H7, interim):** ~18 design skills will coexist. Interim rule: frontend-design
(direction) → taste/impeccable (craft/audit) lead; collection skills treated as pull-not-push (invoked
deliberately). **Honesty note: this is a CONVENTION, not an enforced constraint** — skills still match
on their descriptions; nothing mechanical restrains them. Real arbitration (precedence table,
anti-trigger reconciliation) is owned by the stack-spec phase, the next build after activation.

## COST (honest table — M1)
| Item | When | Amount |
|---|---|---|
| Everything in Classes 1–3, 5, 6 | install | £0 |
| CLASS 4 MCP servers | install £0; **per-server pricing NOT yet reconned** (Aceternity/Magic/21st/Figma tiers verified at gate time) | TBC at gate |
| scroll-world | per USE | ~$27/6-scene chain (Higgsfield connected — rail-3 gate per use) |
| screenshot-to-code | per USE | LLM API key usage (Gemini/Anthropic) |
| skiper40 free tier | per USE | visible attribution on client site (or paid tier) |
| shadcn Pro block library | HELD | $19/mo — not in this wave |

## RISKS CARRIED
Jan-2026 staleness (⟨CALL 2⟩) · npm/npx gate holes (routed around, never relied on) · vercel full
Tier C · MCPs = per-launch external code (G3 pinning) · agents-dir assumption (Phase 4 test + fallback)
· ~30-item surface change to every future session (arbitration interim rule + stack-spec next).
