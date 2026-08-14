# THE WEB ARM LIBRARY
## v1.0 — 2026-08-14 · the job-indexed routing layer for the OFFLIMITS web design arm

> **How to use this (agents, read first):** find the JOB you were briefed to do, pull ONLY the tools
> that row names, and stop. Do not rummage, do not load the whole shelf. If no row fits the job,
> say so — a missing row is a library amendment, not a licence to improvise.
> **This file is the trigger-arbitration authority for design work** (activation-plan H7): the LEAD
> tool in a row steers; supports assist; nothing else auto-fires.
> Statuses trace to `./HANDOFF.md` (the tracker) — disk is truth; this is the map.

---

## §0 · The standing inheritances (apply to EVERY job, every client)

| Source (per client, OFFLIMITS repo) | Governs |
|---|---|
| `01_STRATEGY/POV.md` · `PERSONA_BRIEF.md` · `PILLAR_SYSTEM.md` · `COMPETITOR_MAP.md` | what the site says, to whom |
| `BRAND_SYSTEM.md` | tokens: type, colour, marks, grid |
| `VOICE_GUIDE.md` + the voice scorer | every word of copy (site surfaces need a per-client register extension) |
| `03_PLAYBOOKS/PHOTOGRAPHY_RULEBOOK/` | every image |
| `03_PLAYBOOKS/GRAPHIC_SYSTEM.md` | visual classes |
| PIPELINE rails 1–8 | gates, cost, voice, occasions (rail 8 binds imagery briefs) |

Where locks don't exist yet (e.g. a brand+site engagement), the web work may inform them —
bidirectional per operator ruling 2026-08-14. Locks are fuel, not a gate.

## §1 · Direction & taste — "how should this look?"

| Job | LEAD | Support |
|---|---|---|
| Set the visual direction for a brief | **frontend-design** | client BRAND_SYSTEM/POV; `ui-designer` agent for exploration |
| Generate competing UI directions to pick from | **superdesign MCP** (1–5 variations, iterate) | frontend-design as the taste gate on the output |
| Route a fuzzy design brief into an ordered flow | **design-orchestration** | — |
| Choose the component library / stack for a project | **pick-ui-library** | shadcn skill; §5 registry shelf |
| Query design knowledge (palettes, fonts, UX rules) | **ui-ux-pro-max** ⚠ TEST status — verify output on a web target before trusting | — |

## §2 · Build — "make the site"

| Job | LEAD | Support |
|---|---|---|
| Landing / marketing / portfolio page | **taste-skill** (its §13 scope: A/B only) | tailwind-patterns · scroll-experience (cinematic) · interactive-portfolio |
| Re-craft an existing live site (NTF shape) | **taste-redesign** | **ditto-site** (live-URL → componentized code, primary extractor) · website-downloader (raw mirror/backup only) |
| Turn reference images/mockups into code | **screenshot-to-code** (runs at NTF time; needs LLM key; NEVER execute its cursor-cloud-install.sh) | NOT image-to-code-skill (generates its own refs — cannot ingest yours) |
| Multi-page / content site | **core-components** + **tailwind-patterns** | frontend-patterns (ECC) · `frontend-developer` agent |
| App-shell / dashboard (archetype D) | **react-ui-patterns** + frontend-patterns | dataviz (harness) · ui-ux-pro-max · component-system theming = future house build |
| Quick clickable prototype for a client | **artifacts-builder** | web-artifacts-builder was its byte-identical twin — dropped |
| shadcn components: add, compose, debug | **shadcn skill** + **shadcn MCP** (pinned 4.18.0) | components.json discipline per the skill |

## §3 · Motion — "make it move (or know when not to)"

| Job | LEAD | Support |
|---|---|---|
| Should this animate at all? / craft doctrine | **emil-design-eng** | — |
| Build an animation from scratch | **animate** | runtime: **Motion = house default**; gsap-* when GSAP fits; animejs for low-level/SVG |
| Critique / audit / discover motion | **review-animations** (one diff) · **improve-animations** (codebase audit) · **find-animation-opportunities** (discovery) | — |
| Scroll-driven / parallax / pinned sections | **gsap-scrolltrigger** | gsap-core · gsap-timeline · gsap-react · gsap-performance · scroll-experience (narrative craft) |
| Immersive 3D / WebGL | **3d-web-experience** | — |
| Scroll-scrubbed "fly-through world" hero | **scroll-world** ⚠ **COST GATE: ~$27/6-scene chain (Higgsfield+Monid) — rail-3 preflight + operator go per use** | — |

## §4 · Imagery, type & assets

| Job | LEAD | Support |
|---|---|---|
| Generate site imagery/video | **Higgsfield** ⚠ credit-capped (engine cost rails apply) | client PHOTOGRAPHY_RULEBOOK governs every frame |
| Moodboards / reference boards | **image-collator** (house) | taste-brandkit (brand-board images) |
| Type | **`_TYPE/` house library first** (7 working self-hosted families) | google-fonts MCP = HELD (no package exists); manual fallback per FONT_LIBRARY.md |

## §5 · The registry shelf (reference clones — `~/claude-hq/repos/web-arm/`)
Component sources browsed for patterns, pulled into PROJECTS as pinned npm deps — never executed
from the clones. cult-ui (AI-app UI; its flag = FALSE POSITIVE) · kokonutui · bklit-ui (charts, D) ·
**heroui** (21st.dev's replacement per operator 2026-08-14; its bundled heroui-react/native/migration
skills = future gate candidates; its curl-install lines NEVER-EXECUTE) · skiper40 (attribution!) ·
daisyui · motion · anime — Lane 7 staging list in ACTIVATION_PLAN. All SHA-pinned in `./.provenance`.
**Quarantine law: every clone's root instruction files (`*.quarantined`) stay quarantined; sweep any
NEW clone the same way (live-fire event 2026-08-14).**

## §6 · QA — "prove it's good before it ships"

| Job | LEAD | Support |
|---|---|---|
| Design-quality audit | **impeccable** (`/impeccable audit·critique·polish`; detector: exit 2 = findings, stderr) | web-design-guidelines (standards check) |
| Accessibility | **`accessibility-tester` agent** (WCAG) | axe-core = NTF-time devDep |
| Performance | **web-performance-optimization** | Lighthouse = NTF-time devDep |
| See it running / screenshot / interact | **playwright MCP** · **claude-in-chrome** (live dev tab) | `run` (harness) to launch the app |
| Flows / e2e (C & D briefs) | e2e-testing + e2e-runner (ECC) | Playwright visual-regression = NTF-time config |
| Code quality | code-reviewer (ECC agent) | — |

## §7 · Findability & research

| Job | LEAD | Support |
|---|---|---|
| SEO audit / fundamentals / structured data | **seo-audit** · **seo-fundamentals** · **schema-markup** | web-performance-optimization (CWV) |
| Pages at scale / AI-search visibility | **programmatic-seo** · **geo-fundamentals** | — |
| Reference & competitor research | **exa MCP** · reference libraries (Godly, Land-book, Mobbin, Siteinspire…) | **lightpanda MCP** (fast scrape) · `ux-researcher` agent |

## §8 · Copy

Client `VOICE_GUIDE.md` + voice scorer govern; **humanizer** as the de-AI pass on site copy.
Site surfaces (buttons, errors, microcopy) need a per-client register extension — house gap, flagged.

## §9 · Back-end hooks — "tap only if required" (operator ruling: partners own the heavy end)

api-design · backend-patterns · security-scan/security-reviewer (anything capturing user data) —
all live via ECC. database-*/docker/deployment = PARK. Higgsfield site-deploy = PARK (cost unknown).

## §10 · Held / deferred / dropped (do not silently resurrect)

| Item | State |
|---|---|
| 21st.dev Magic MCP | **DROPPED by operator 2026-08-14** — replaced by Magic UI + shadcn (already live) + heroui shelf |
| Figma MCP | Registered via Keychain launcher — **waiting on the operator's one-time keychain add** |
| google-fonts-mcp | HELD — no npm package exists |
| find-skills (vercel-labs) | DEFERRED — HQ BACKLOG task |
| CRO six (page/form/popup/signup/onboarding/paywall-cro) + mobile-design + theme-factory | DORMANT on disk — one gate away if a brief needs them; NOT in the activated wave |
| Instatic | Reference only — the parked post-handoff CMS conversation |
| Design-token bridge · component-system theming | FUTURE HOUSE BUILDS (operator: not yet) |

---
*Amendments: append-only; a changed row cites the ruling or gate evidence that changed it. Pairs with
`./HANDOFF.md` (state) and `./ACTIVATION_PLAN.md` (how things got here). The library exists so agents
find the right tool in one lookup — token discipline is the point (operator commission, 2026-08-14).*
