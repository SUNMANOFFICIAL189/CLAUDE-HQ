---
name: visual-style-lock
description: Locks one consistent visual style across an entire image set so every frame reads as the same campaign regardless of subject, image proportion, or location. The agent inventories the anchor image and checks every render against that inventory before presenting it, and the method now also covers storyboard-to-stills work. Use when the user wants on-brand image generation, a repeatable look across shots, or says "lock a visual style", "keep these images consistent", "set up the image style for [project]", "reproduce the same look across proportions/locations", "make everything look like one shoot", "make these stills consistent", "storyboard to stills", "same look across every shot", or wants to start a new project's photography system from a reference image. Engine-adaptive method; live adapters are Higgsfield + GPT Image 2 and AtlasCloud + GPT Image 2 (edit). Carries the method only, never another project's content.
---

> **TWIN COPIES — operator ruling 2026-09-05.** This skill exists at exactly two paths and they must stay byte-identical: `/Volumes/Elements/My_Stuff/OFFLIMITS/.claude/skills/visual-style-lock` (project copy) and `/Users/sunil_rajput/claude-hq/skills/visual-style-lock` (HQ copy, symlinked into `~/.claude/skills/`). Any edit to one MUST be mirrored to the other in the same session, and the operator MUST be told that the twin needs the same change. Do not "deduplicate" them — the two copies are deliberate. Drift check: `diff -r <pathA> <pathB>` must print nothing.

# visual-style-lock

## Purpose

Produce a set of generated images that read as one campaign. Hold the look constant (colour grade, identity, branding, optics) while subject, image proportion, and location change. The skill encodes the repeatable method that achieves this; it does not store any single project's look.

## The core idea (read first)

Image models re-derive colour and identity per scene. Prompt text alone drifts: warm-heavy scenes go yellow, close frames stay neutral, faces wander, logos get redrawn. Consistency comes from three disciplines working together:

1. Anchor to fixed reference images on every generation, not from description.
2. Hold the invariants verbatim; move only one variable clause per shot.
3. Gate the workflow so a cheap test locks the look before anything scales.

The skill is method, not memory. Each new project starts blank. Nothing from a prior project (grade, faces, logo, anchors) carries over unless the operator copies a STYLE_LOCK file on purpose. This matches per-client isolation.

## Operating rules (non-negotiable)

- Anchor, do not describe. Attach the grade anchor and the brand-asset anchor in the generation call for every frame. Never rely on prompt text alone for colour or identity.
- Do not over-specify the grade. Plain, literal language holds. Decorative grade words drift (for example "golden amber", "faded matte milky blacks"). Lock the simplest clause that reproduces the look and keep it word-for-word.
- Invariants verbatim, one variable clause. The Master Prompt changes in exactly one place per shot.
- Asset fidelity. Upload the real logo or mark, reference it, and instruct "reproduce exactly, do not redraw or recolour".
- 1k by default. Generate at low resolution for every test and every composition pass. Step to 2k or 4k only when the operator asks for the hi-res final of an approved frame.
- The operator validates every gate; visibility into renders is engine-dependent. When the render is a local file (any API engine that returns a downloadable image), the agent CAN and MUST open it and run the element checklist (Step 6b) before presenting it — the operator then judges taste and grade at the gate. Only when an engine renders solely into the operator's UI (for example the Higgsfield MCP) does validation fall to the operator alone. Never claim a render matches without having checked it element by element.
- Per-project isolation. Do not reuse another project's anchors or STYLE_LOCK unless the operator instructs it.
- **Typed sections.** A master prompt is made of typed sections: IDENTITY, WARDROBE, SET DRESSING (props and environment that must appear in every shot), LIGHT, GRADE, and OPTICS are invariant; FRAMING (camera position, shot size, subject action) is the only variable section. Set dressing never lives inside the framing section. Before substituting any section per shot, enumerate what that section carried and re-home every constant.
- **The element inventory is derived, not remembered.** The required-elements list comes from the anchor image (agent inventory, Step 1a) unioned with any text the operator supplied — never from memory.
- **Verify the request, not the template.** Before any spend, the built request for every generation must contain each fixed element's distinctive noun; a miss fails the build. The template is not evidence; the sent bytes are.
- **Reference order is a control.** The first reference dominates composition and scene; each additional reference steers specific attributes (a second reference can change the shape of a subject's eyewear or a prop). Scene anchor first, identity reference second, never the reverse. Do not remove a reference on theory — A/B it at test size first (with/without), which costs cents and settles it.
- **Never put spoken lines, script or captions into an image prompt.** Image models render text they are given. When working from a storyboard, strip every line of dialogue and describe the action and framing only; add "no text, no words, no captions, no subtitles" to the exclusions.
- **Quote before spend.** A platform's headline price is a hypothesis. Quote every job through the platform's own calculator (or run one minimum-size job and read its real charge) before quoting a total to the operator; log real charges per job.
- **Edit models regenerate; they do not inpaint.** "Mirror the reference exactly" is achievable for the anchor's own framing within limits; a different framing cannot mirror the anchor's frame. Pixel-identical backgrounds come from cropping/extending the real anchor, not from generation. Say this to the operator at intake.

## Inputs

| Field | Required | Source |
|---|---|---|
| `reference_image` | yes | operator-supplied target look (one strong frame, or a small set), plus any optional text describing it; the agent derives the written element inventory from this — the operator confirms it, they do not author it |
| `brand_asset` | for branded shots | logo or mark, uploaded into the generation engine |
| `casting_and_wardrobe` | yes | who appears, what they wear, key props |
| `setting_range` | yes | the locations or backdrops the set must span |
| `proportions_needed` | yes | the aspect ratios the destination needs |
| `engine` | yes | defaults to Higgsfield + GPT Image 2; AtlasCloud + GPT Image 2 (edit) also live (see references/engine-adapters.md) |
| `storyboard` | optional | per-shot framing and action for storyboard-to-stills work; dialogue is stripped before any prompt is built |

## Process (gated workflow)

### Step 0: Intake
Collect the reference image, the brand asset, casting and wardrobe, the setting range, and the proportions needed — and, for storyboard-to-stills work, the storyboard itself. Confirm the engine (Higgsfield + GPT Image 2, or AtlasCloud + GPT Image 2 edit) and read its section of references/engine-adapters.md for mechanics and limits.

### Step 1: Dissect the reference into a style spec
Translate the reference into plain language across six dimensions: colour and grade, lighting, lens and optics, composition, texture and finish, casting and expression. Write each dimension as a constant. Apply the do-not-over-specify rule: prefer the simplest clause that reproduces the look. Record this in the project STYLE_LOCK file (see references/STYLE_LOCK_TEMPLATE.md).

### Step 1a: Inventory the anchor (agent-run)
The agent opens the anchor image and lists every element it carries — subject identity markers, wardrobe down to eyewear shape, props, set dressing, light direction, grade, and camera position — tagging each FIXED (must appear in every shot) or VARIABLE (changes with framing). Union this with any text the operator supplied: if the text names an element, or the image shows it, it is on the list. Record it in STYLE_LOCK Section "Element inventory" with a distinctive noun per element for the payload check (Step 3a). Present the list for a one-glance operator confirmation — the operator confirms or corrects it; they do not author it.

### Step 2: Split invariants from variables, write the Master Prompt
Write the Master Prompt as typed sections: IDENTITY, WARDROBE, SET DRESSING, LIGHT, GRADE, and OPTICS are invariant and carried verbatim from the element inventory (Step 1a); FRAMING (camera position, shot size, subject action) is the only variable section. Never let a constant hide inside the FRAMING section — if a prop or dressing item belongs in every shot, it lives in SET DRESSING. Reuse the Master Prompt word-for-word; edit only the FRAMING section.

### Step 3: Lock the anchors
Establish the canonical reference set:
- Grade anchor: the approved frame whose colour the set matches.
- Asset anchor: the uploaded logo or mark for branded items.
Record the anchor IDs in the STYLE_LOCK file, in reference order (see references/STYLE_LOCK_TEMPLATE.md Section 1.7): scene/grade anchor first, identity or asset reference second, never the reverse. The rule for every later generation: attach these anchors in the engine's reference field, in that order, plus a one-line "match the colour, white balance and grade of the reference exactly" clause.

### Step 3a: Pre-spend request check (mechanical)
Build every request the run will submit and dump the exact payloads before sending any of them. Assert, mechanically, that each FIXED element's distinctive noun appears in every payload (count of hits equals the number of generations) and that no dialogue line appears anywhere in the text. Fail closed on any miss — fix the prompt, rebuild, recheck. Only once the check is clean: quote each job through the platform's calculator and check the wallet balance before submitting anything.

### Step 4: Grade test (one frame, 1k)
Generate a single frame at low resolution to validate the grade and the anchoring. Present it. The operator judges the grade against the reference. On a miss, adjust the dissected spec (not decorative additions) and retest. On approval, the grade clause and the grade anchor are locked. Write the lock into STYLE_LOCK and note the approved anchor ID.

### Step 5: Scale the proportions (still 1k)
Reuse the Master Prompt verbatim, swap only the variable clause, attach the locked anchors, and produce the needed proportions and subject arrangements at 1k. Present the set. The operator confirms the look held across framings.

### Step 6: Hi-res (only on request)
Step an approved frame to 2k or 4k only when the operator asks for the final. Re-run the same prompt and anchors at the higher resolution and quality.

### Step 6b: Post-render element check (agent-run where visible)
For every render the agent can open — at the grade test, the proportion set, or the hi-res final, wherever the engine returns a downloadable file — tick each inventory element present or absent against the STYLE_LOCK element inventory. Any absent FIXED element is a FAIL: re-run it or flag it explicitly, never fold it into a footnote. Only once this check passes does the frame go to the operator for the taste and grade gate.

Each step ends at a gate: present, let the operator validate, then proceed.

## Outputs

- A per-project `STYLE_LOCK.md` (filled from the template) that governs every later generation for that project.
- A consistent image set produced under that lock.

## Supporting files

- `references/STYLE_LOCK_TEMPLATE.md`: the blank, parameterized playbook to fill per project.
- `references/engine-adapters.md`: tool-specific mechanics. Live adapters: Higgsfield + GPT Image 2, and AtlasCloud + GPT Image 2 (edit). Structured so a new engine is a new section with the core method untouched.
- `references/qc-checklist.md`: run before approving any frame.

## Anti-patterns (learned the hard way)

- Over-engineered grade language drifts. Simplify and lock.
- Text-only colour drifts across framings. Always anchor.
- Declaring "this matches" without checking it — either the agent's own element-by-element check when the render is visible, or the operator's eyes when it is not.
- Jumping to hi-res before composition approval. Slow and wasteful; test at 1k.
- Inventing a logo from a text description. Upload the real asset and reproduce it.
- Burying a constant inside the variable section, then swapping it out — the template still shows the words; the request does not.
- Noting a missing element as "a small difference" instead of failing the render.
