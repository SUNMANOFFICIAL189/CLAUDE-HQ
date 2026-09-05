---
name: visual-style-lock
description: Locks one consistent visual style across an entire image set with an anchor-set delta method — build a world-model inventory of every element (each carrying a bearing relative to the subject, plus its own continuity facts), assemble a shot-family anchor set whose entries record both what each anchor SHOWS and what it LACKS, then compute each shot's prompt as the delta between that shot's required-in-frame list and what the chosen anchor already shows, gated by a pre-spend delta check and a post-render presence/continuity/camera check. Use when the user wants on-brand image generation, a repeatable look across shots, or says "lock a visual style", "keep these images consistent", "set up the image style for [project]", "reproduce the same look across proportions/locations", "make everything look like one shoot", "make these stills consistent", "storyboard to stills", "same look across every shot", "the render dropped something that was in the reference", "the model invented scenery that wasn't in the reference", or wants to start a new project's photography system from a reference image. Engine-adaptive method; live adapters are Higgsfield + GPT Image 2 and AtlasCloud + GPT Image 2 (edit). Carries the method only, never another project's content.
---

> **TWIN COPIES — operator ruling 2026-09-05.** This skill exists at exactly two paths and they must stay byte-identical: `/Volumes/Elements/My_Stuff/OFFLIMITS/.claude/skills/visual-style-lock` (project copy) and `/Users/sunil_rajput/claude-hq/skills/visual-style-lock` (HQ copy, symlinked into `~/.claude/skills/`). Any edit to one MUST be mirrored to the other in the same session, and the operator MUST be told that the twin needs the same change. Do not "deduplicate" them — the two copies are deliberate. Drift check: `diff -r <pathA> <pathB>` must print nothing.

# visual-style-lock

## Purpose

Produce a set of generated images that read as one campaign. Hold the look constant — colour grade, identity, branding, optics — while subject, image proportion, and location change, using an anchor-set delta method: describe only what the chosen anchor does not already show, computed per shot. The skill encodes the repeatable method that achieves this; it does not store any single project's look.

## The core idea (read first)

Two failure modes sit at opposite ends of the same dial, and both were paid for before this method existed.

At one extreme, a long prose prompt (several hundred words) described an entire scene in words, attached to a strong reference image. It drifted: the model invented scenery the reference never showed and mis-placed pieces of the set. Prose restates in loose language what an image states precisely; wherever the words are looser than the picture, the words win, and the picture is demoted to mood board.

At the other extreme, a short prompt (well under a hundred words) named only the camera move and relied on a well-chosen reference for everything else. It reproduced the look, the optics, the world and the grade with no trouble — then silently dropped a required prop, because the chosen reference did not show that prop and nothing in the prompt named it. An absence in the anchor becomes an absence in the render; a reference is not obligated to volunteer what it does not contain.

A third finding pointed at the fix from a different angle: swapping the anchor for a frame drawn from the material the operator actually wanted to resemble restored grade, depth of field, framing discipline and medium-feel — with zero words spent describing any of them. A style reference is a place the render is taken to, not a colour swatch quoted from memory.

The resolution is one rule, and everything else in this skill exists to make it computable: **describe only what the chosen anchor does not already show; never describe what it already shows. The prompt is a delta against the anchor, not a description of the shot.** Computing a delta requires, at all times: a list of everything a shot could require (Layer 1 — world model), an anchor whose own contents are known precisely enough to subtract (Layer 2 — anchor set), the subtraction itself, done per shot, in one place (Layer 3 — shot spec and the delta rule), and a check that the subtraction was actually done and actually true (Layer 4 — gates). None of the four layers is optional; skipping any one of them reopens one of the two failure modes above.

### Layer 1 — World model (per project, built once, operator-confirmed)

Everything that can appear across the set, classed ALWAYS (present in every frame), SET (part of the world, present only when a shot's framing covers it), or VARIABLE (changes with framing). Two additions make the inventory usable by a camera that moves:

- **Bearing.** Every element carries a bearing relative to the subject, not the frame — "on the subject's right, beyond their feet," never "frame-left." Frame-left and frame-right invert as the camera orbits; a bearing tied to the frame becomes wrong the moment the shot list changes the camera position. Without a subject-relative bearing, a camera move is unresolvable: nothing tells you which side of the subject a prop falls on once the axis changes.
- **Continuity facts.** Which hand holds which prop, which arm or shoulder leads, which way limbs cross, which way the subject faces — recorded as their own rows, not folded into the element inventory. An inventory is presence-based (is the element there, yes/no); it does not watch handedness or facing, so those flip silently between shots unless they are checked as facts in their own right.

### Layer 2 — Anchor set (per shot family, not one anchor for the project)

One grade anchor cannot specify what every camera position needs — an overhead plan-view under-determines a water-level close-up at the other end of the shot list. So the method takes a *set* of anchors, one (or a small group) per shot family, and treats each with equal rigour:

- Every anchor carries its own inventory, and the column that matters is not just what it shows — it is **what it SHOWS and what it LACKS.** Record both, plus the anchor's optics (lens feel, depth of field), its grade, its camera position, and its subject scale. The LACKS column is the load-bearing one: it is what makes Layer 3's subtraction computable at all. An anchor inventory with only a SHOWS column is a description, not a tool.
- Per shot, choose the anchor whose look and camera position sit closest to the target, and say so in the shot spec — a stated choice, not a default.
- Draw the anchor set from the material the operator actually wants the result to resemble. An anchor that is off-style from the target still "works" mechanically, but every render pays an invisible tax for it — grade, lens feel and framing discipline all drift toward the anchor's own source, not the target's. If a shot family in the plan has no anchor that serves it, flag it; do not let a distant anchor stand in silently.

### Layer 3 — Shot spec, and the delta rule

Per shot, record:

- **Camera position**, stated as a position on the plan, not a description of a view: axis relative to the subject (overhead / frontal / lateral-perpendicular), height, which side of the subject is shown, tilt, and distance/shot size; for planimetric styles also state squared-to-frame and level horizon.
- **Required-in-frame list** = the ALWAYS elements this framing would see + the SET elements this framing would see (per the visibility map) + the performance beat. Framing decides membership both ways: an ALWAYS element that this framing crops out is not required in this frame; a SET element this angle cannot see must not be forced into it.
- **The delta rule** — the centre of the method: **the prompt = (required-in-frame) MINUS (what the chosen anchor already shows) + the camera move + the beat. Nothing else.** Three consequences follow, and all three must be checked, not assumed:
  1. Anything required that the anchor LACKS must be named in the prompt, in words — if it is not named, it will be dropped, because the anchor cannot volunteer what it does not contain.
  2. Anything required that the anchor already SHOWS must NOT be named — restating it in looser prose is exactly what licenses the model to drift away from what the picture already states precisely.
  3. An attribute the anchor shows in a form that differs from the locked spec is also a delta, and must be named as a correction (for example: the anchor shows an element in one variant; the project has ruled a different variant for this shot) — silence here is read as agreement with the anchor, not with the spec.
     **But naming it is frequently not enough.** Measured: three consecutive renders refused a
     named correction to an attribute the anchor asserted strongly, including one prompt that
     stated the wanted form and the rejected form explicitly. On attribute conflicts the picture
     beats the words. So: name the correction once and look at the result; if the anchor's form
     survives, stop arguing with the picture and **change the input** — swap in an anchor that
     shows the wanted form, or add a second reference that carries it (accepting that a second
     reference steers other attributes too, per the reference-order rule). Budget one test frame
     for this, not four.
- **Medium.** Name the medium only when the anchor does not already establish it, and never ask for a medium the shot does not want — a prompt that says "photograph" gets a photograph even when the intent was a film frame. Default to letting the anchor carry the medium; override it only with a named delta.
- **Guards are not part of the delta.** A small fixed set of protective clauses rides on
  every prompt regardless of what the anchor shows: the no-text/no-caption exclusion, and the
  anatomy guard (hands, limb count, duplicated features). They cost a handful of words, they are
  never "already supplied by the anchor" in any useful sense, and dropping them is how a
  minimal prompt buys a clean look and an extra hand in the same frame. Exclude them from the
  subtraction; append them verbatim.
- **Performance beat.** Keep it even though dialogue is stripped from any storyboard source: state what the subject is doing at that instant. A frame with a camera position and no beat reads as a held pose, not a moment.
- **Frame exclusions, optics, depth of field and subject scale are per shot family, not one project-wide constant.** Carry them from the anchor where the anchor already establishes them; name them as deltas otherwise. Treating any of these as a single global rule is how a deep-focus overhead plan-view ends up governing a shallow-focus close-up several shot families away.

### Layer 4 — Gates (both mechanical, both fail closed)

- **Pre-spend.** For every shot: assert each delta item from Layer 3 actually appears in the built prompt text, and assert the prompt does not also restate anything the anchor already shows. A missing per-shot required-in-frame list, or a missing anchor SHOWS/LACKS inventory, is itself a failure with no bypass by omission — the check cannot run without them, so their absence fails the gate directly. Only once this is clean: quote the job and check the wallet.
- **Post-render**, wherever the render reaches a local file the agent can open: every required-in-frame item is actually visible; every continuity fact is correct (which hand, which side, which way things cross, which way the subject faces); the camera position was honoured (axis, height, side, tilt); and nothing appears that is not in the world model or a named delta. Any failure is a FAIL — re-run it or flag it explicitly; it never becomes a footnote.

The skill is method, not memory. Each new project starts blank. Nothing from a prior project (grade, faces, logo, anchors) carries over unless the operator copies a STYLE_LOCK file on purpose. This matches per-client isolation.

## Operating rules (non-negotiable)

- **Anchor to a set, not a single reference.** Attach the anchor(s) chosen for this shot's shot family (Layer 2) in the generation call for every frame. Never rely on prompt text alone for colour, identity, or world content — and never assume one project-wide anchor covers every camera position.
- **The prompt is a delta, not a description.** Describe only what the chosen anchor does not already show (Layer 3). Plain, literal language holds for what genuinely needs naming; decorative language layered on top of an anchor's own information is where drift starts — this is where the old "do not over-specify the grade" caution now lives (for example, decorative grade words like "golden amber" or "faded matte milky blacks" drift; the simplest clause that reproduces what the anchor cannot supply on its own is the one to lock).
- **Reuse delta text verbatim within a shot family; only the camera position and the beat vary shot to shot inside that family.** A recurring delta clause — an element every anchor in a family lacks — is locked once and reused word for word. This is where the old "invariants verbatim, one variable clause" discipline now lives, scoped to what a family's anchor actually lacks rather than to a single whole-project master prompt.
- **Asset fidelity.** Upload the real logo or mark, reference it, and instruct "reproduce exactly, do not redraw or recolour" — this is always a delta, since no chosen anchor is expected to already carry a specific project's brand mark.
- **1k by default.** Generate at low resolution for every test and every composition pass. Step to 2k or 4k only when the operator asks for the hi-res final of an approved frame.
- **The operator validates every gate; visibility into renders is engine-dependent.** When the render is a local file (any API engine that returns a downloadable image), the agent CAN and MUST open it and run the post-render check (Step 6b) before presenting it — the operator then judges taste and grade at the gate. Only when an engine renders solely into the operator's UI does validation fall to the operator alone. Never claim a render matches without having checked it element by element.
- **Per-project isolation.** Do not reuse another project's world model, anchor set, or STYLE_LOCK unless the operator instructs it.
- **The world model is derived, not remembered.** The element inventory, the bearings, and the continuity facts come from the anchor images (agent inventory, Step 1a) unioned with any text the operator supplied — never from memory or from a prior project.
- **Bearings are relative to the subject, never the frame.** Frame-left and frame-right invert as the camera orbits; a bearing recorded against the frame becomes wrong the moment the shot list adds a new camera position.
- **Continuity facts are checked, not assumed.** Which hand, which side, which way things cross, which way the subject faces — these are watched explicitly (Step 6b) because a presence-only inventory does not notice them flip.
- **An anchor's inventory needs two columns, not one.** What it SHOWS matters for knowing what not to repeat; what it LACKS matters for knowing what must be named, or it will be dropped. An anchor description with only a SHOWS column cannot support the delta rule.
- **Choose anchors from the material the operator actually wants to resemble.** An off-style anchor still renders, but every shot pays its tax invisibly, in grade, lens feel and framing discipline the target never asked for. Flag any shot family with no anchor that serves it — do not force a distant one to stand in silently.
- **Required-in-frame membership is decided by framing, not by a checklist.** An ALWAYS element cropped out by a tight frame is not required in that frame; a SET element the angle cannot see must not be forced in. This is the surviving form of the old "typed sections" rule: IDENTITY, WARDROBE, LIGHT, GRADE, OPTICS, and SET DRESSING still classify what a thing IS in the world model, but whether it enters a given shot's prompt text is now governed entirely by the delta rule, not by a fixed section repeated in every prompt regardless of what the anchor already shows.
- **Camera position is stated as a position on the plan, not a description of a view.** Axis relative to the subject, height, subject side, tilt, and distance/shot size; for planimetric styles also state squared-to-frame and level horizon. A bare shot name ("side profile", "close-up") is not a camera position — left underspecified, the engine fills the gaps with a three-quarter view from slightly above more often than not. **Stating a dimension and pinning it are different things, and the difference is a creative decision, not a technical one.** State the dimensions the shot actually calls for — the shot list or storyboard calls them, not this skill. A dimension you state is repeatable across runs; a dimension you leave unstated is delegated to the anchor and WILL vary between runs. That is a legitimate choice when the anchor already holds the value you want and the shot list specifies none, and a fault only when you needed it fixed and assumed it was. Measured: an identical prompt with distance unstated produced a tight framing on one run and a wide one on the next, both faithful readings of the same words. So name a dimension when the shot changes it or must reproduce it, leave it to the anchor otherwise, and never assume an unstated dimension will hold. Do NOT convert this into a gate that refuses a camera move lacking all five dimensions — that turns a creative call into a lock (tried 2026-09-05, rejected by the operator, removed).
- **Name the medium only when the anchor does not already establish it, and never ask for a medium you do not want.** A prompt that says "photograph" gets a photograph even when the intent is a film frame; prefer letting the anchor carry it.
- **Keep the beat even when the words are stripped.** When dialogue is stripped from a storyboard, the acting must not be stripped with it — state what the subject is doing at that instant, or the frame reads as a pose.
- **Optics, depth of field, subject scale, and frame exclusions are per shot family, never one project-wide constant.** Carry them from the anchor where the anchor already establishes them; name them as deltas otherwise.
- **Reference order is a control, inside every anchor call.** The first reference dominates composition and scene; each additional reference steers specific attributes only (a second reference can change the shape of a subject's eyewear or a prop). Scene anchor first, identity or asset reference second, never the reverse. Do not remove or reorder a reference on theory — A/B it at test size first (with/without), which costs cents and settles it.
- **Never put spoken lines, script or captions into an image prompt.** Image models render text they are given. When working from a storyboard, strip every line of dialogue and describe the action (as the beat) and the framing only; add "no text, no words, no captions, no subtitles" to the exclusions.
- **Quote before spend.** A platform's headline price is a hypothesis. Quote every job through the platform's own calculator (or run one minimum-size job and read its real charge) before quoting a total to the operator; log real charges per job.
- **Edit models regenerate; they do not inpaint.** "Mirror the reference exactly" is achievable for the anchor's own framing within limits; a different framing cannot mirror the anchor's frame. Pixel-identical backgrounds come from cropping/extending the real anchor, not from generation. Say this to the operator at intake.

## Inputs

| Field | Required | Source |
|---|---|---|
| `reference_image` | yes | operator-supplied target look (one strong frame, or a small set) plus any optional text describing it; the agent derives the world model (Step 1a) from this, and this same material seeds the anchor set (Step 1b) — the operator confirms both, they do not author them |
| `brand_asset` | for branded shots | logo or mark, uploaded into the generation engine |
| `casting_and_wardrobe` | yes | who appears, what they wear, key props |
| `setting_range` | yes | the locations or backdrops the set must span |
| `proportions_needed` | yes | the aspect ratios the destination needs |
| `engine` | yes | defaults to Higgsfield + GPT Image 2; AtlasCloud + GPT Image 2 (edit) also live (see references/engine-adapters.md) |
| `storyboard` | optional | per-shot framing and action for storyboard-to-stills work; the action becomes each shot's performance beat (Step 2); dialogue is stripped before any prompt is built |

## Process (gated workflow)

### Step 0: Intake
Collect the reference image or image set, the brand asset, casting and wardrobe, the setting range, and the proportions needed — and, for storyboard-to-stills work, the storyboard itself. Confirm the engine (Higgsfield + GPT Image 2, or AtlasCloud + GPT Image 2 edit) and read its section of references/engine-adapters.md for mechanics, limits, and how strongly that engine's references override its prompt text — its "reference authority." The delta rule assumes strong reference authority; if an engine's authority is weak, say so to the operator before relying on the anchor to carry anything.

### Step 1: Dissect the reference(s) into a style spec
Translate the primary reference into plain language across six dimensions: colour and grade, lighting, lens and optics, composition, texture and finish, casting and expression. Write each dimension as the project's default — the base description the anchor set (Step 1b) and shot specs (Step 2) override per shot family where they need to. Apply the do-not-over-specify rule: prefer the simplest clause that reproduces what actually needs naming. Record this in the project STYLE_LOCK file (see references/STYLE_LOCK_TEMPLATE.md §1 / §1.4).

### Step 1a: Build the world model — inventory, bearings, continuity (agent-run)
The agent opens the reference(s) and lists every element they carry — subject identity markers, wardrobe down to eyewear shape, props, set dressing, light direction, grade, and camera position — tagging each ALWAYS (identity, wardrobe, key prop, light, grade — present in every frame), SET (framing-conditional — part of the world, present only when a shot's framing covers it), or VARIABLE (changes with framing, e.g. shot size, arrangement). Beyond presence, two more things are recorded for every element and fact:
- **Bearing** relative to the subject ("on the subject's right, beyond their feet"), never relative to the frame.
- **Continuity facts**, as their own rows, not folded into the element list: which hand holds which prop, which arm or shoulder leads, which way limbs cross, which way the subject faces.

Union all of this with any text the operator supplied: if the text names an element, or the image shows it, it is on the list. Record it in STYLE_LOCK §0.5 (element inventory with bearings, plus the Continuity facts sub-table) and the per-shot visibility map. Present the list for a one-glance operator confirmation — the operator confirms or corrects it; they do not author it.

### Step 1b: Build the anchor set — per shot family, SHOWS and LACKS (agent-run)
One anchor cannot specify what every camera position needs. For each shot family in the plan, the agent proposes the anchor (or small group of anchors) whose look and camera position sit closest to that family's target, then inventories it on two columns that matter: what it SHOWS and what it LACKS, plus its optics (lens feel, depth of field), its grade, its camera position, and its subject scale. Draw candidates from the material the operator actually wants the result to resemble — an anchor that is merely available but off-style from the target still renders, but every shot built on it pays that tax invisibly. Flag, explicitly, any shot family with no anchor that serves it; do not let a distant anchor stand in without saying so. Record the set in STYLE_LOCK §0.6. Present it for operator confirmation before any shot spec is written against it.

### Step 2: Write the shot spec and compute the delta prompt
For each shot: confirm the chosen anchor (from Step 1b — override it if the operator prefers a different one from the set); state the camera position as a position on the plan (axis, height, subject side, tilt, distance — plus squared-to-frame and level horizon for planimetric styles); build the required-in-frame list (the ALWAYS elements this framing sees + the SET elements this framing sees, per the visibility map + the performance beat); then compute the delta: **prompt = (required-in-frame) MINUS (what the chosen anchor already shows) + the camera move + the beat.** Name anything required that the anchor LACKS. Do not name anything required that the anchor already SHOWS. Name, as a correction, anything the anchor shows in a form that differs from the locked spec. Decide the medium call (name it only if the anchor does not already establish it). Note any frame exclusions for this shot family that the anchor does not already enforce. Record the whole shot spec in STYLE_LOCK §2.5.

### Step 3: Lock the anchor set
Once the shot specs are written and every shot's chosen anchor is settled, record the canonical anchor set in the STYLE_LOCK file (§0.6 and §6): every anchor's engine job/media ID, in reference order (scene/grade anchor first, identity or asset reference second, never the reverse — see §1.7), the shot families each one serves, and its SHOWS/LACKS inventory. The rule for every later generation: attach the shot's chosen anchor(s) in the engine's reference field, in that order, plus a one-line "match the colour, white balance and grade of the reference exactly" clause.

### Step 3a: Pre-spend delta check (mechanical)
Build every request the run will submit and dump the exact payloads before sending any of them. For each payload: assert every item on that shot's delta list (Step 2) appears in the built prompt text, in words. Assert the prompt does NOT also restate anything the chosen anchor already shows — a redundant restatement is a failure in its own right, not a harmless extra. A missing per-shot required-in-frame list, or a missing anchor SHOWS/LACKS inventory, is itself a failure — there is no bypass by omission, because the check cannot run without them. Fail closed on any miss — fix the prompt, rebuild, recheck. Only once the check is clean: quote each job through the platform's calculator and check the wallet balance before submitting anything.

### Step 4: Delta test (one frame per shot family, 1k)
Generate one frame per shot family at low resolution to validate that its delta-built prompt reproduces the family's chosen anchor and actually surfaces every named delta. Present it. The operator judges the grade and the delta items against the reference. On a miss, adjust the delta list or the dissected spec (never add decorative language), and retest. On approval, that shot family's anchor and delta text are locked; write the lock into STYLE_LOCK.

### Step 5: Scale the proportions (still 1k)
Reuse each shot's locked delta prompt verbatim, swap only the camera move and the beat where the shot list calls for it, attach the anchors it names, and produce the needed proportions and subject arrangements at 1k. Present the set. The operator confirms the look held across framings and shot families.

### Step 6: Hi-res (only on request)
Step an approved frame to 2k or 4k only when the operator asks for the final. Re-run the same prompt and anchors at the higher resolution and quality.

### Step 6b: Post-render check (agent-run where visible)
For every render the agent can open — at the delta test, the proportion set, or the hi-res final, wherever the engine returns a downloadable file — check that every item on that shot's required-in-frame list is actually visible (ALWAYS elements on every render; SET elements only where the visibility map says that shot type should see them — a SET element correctly absent from a shot whose framing would not see it is not a miss). Check every continuity fact is correct: which hand, which side, which way things cross, which way the subject faces. Check the camera position was honoured: the right axis, height, subject side, and tilt for that shot. Check that nothing appears which is not in the world model or a named delta — no invented elements. Any failure on any of these is a FAIL: re-run it or flag it explicitly, never fold it into a footnote. Only once this check passes does the frame go to the operator for the taste and grade gate.

Each step ends at a gate: present, let the operator validate, then proceed.

## Outputs

- A per-project `STYLE_LOCK.md` (filled from the template) that governs every later generation for that project — its world model, its anchor set, and its per-shot delta specs.
- A consistent image set produced under that lock.

## Supporting files

- `references/STYLE_LOCK_TEMPLATE.md`: the blank, parameterized playbook to fill per project.
- `references/engine-adapters.md`: tool-specific mechanics, including each live engine's reference authority. Live adapters: Higgsfield + GPT Image 2, and AtlasCloud + GPT Image 2 (edit). Structured so a new engine is a new section with the core method untouched.
- `references/qc-checklist.md`: run before approving any frame — delta check, element presence, continuity, camera, no invention, grade and optics, technical.

## Anti-patterns (learned the hard way)

- Arguing with the anchor in prose. If a named correction to an attribute does not land on the first try, the fix is a different anchor or an added reference, not stronger wording.
- Dropping the safety guards when the prompt goes minimal — a clean look and a sixth finger in the same frame.
- Describing what the anchor already shows — the words are looser than the picture, and looser wins; this is how a strong reference gets overridden by its own caption.
- Failing to name what the anchor lacks — an absence in the anchor is not neutral; it propagates straight into the render as a silent drop.
- One global anchor for every camera position — a single grade anchor cannot specify what a shot at the opposite end of the plan needs; an overhead under-determines a water-level close-up.
- One global optics rule for every shot family — a deep-focus overhead plan-view's depth of field, inherited wholesale by a close shot several shot families away.
- Asking for the wrong medium — naming "photograph" when the intent is a film frame, or the reverse, when the anchor would have carried it for free.
- Stripping the beat along with the dialogue — a frame with the words removed and nothing put in their place reads as a held pose, not a moment.
- Over-engineered grade language drifts. Simplify and lock.
- Text-only colour drifts across framings. Always anchor — to a set, not a single frame.
- Declaring "this matches" without checking it — either the agent's own element-by-element check when the render is visible, or the operator's eyes when it is not.
- Jumping to hi-res before composition approval. Slow and wasteful; test at 1k.
- Inventing a logo from a text description. Upload the real asset and reproduce it.
- Burying a constant inside the variable section, then swapping it out — the template still shows the words; the request does not.
- Noting a missing element as "a small difference" instead of failing the render.
- Forcing set dressing into every frame regardless of camera angle — the over-correction of the deletion failure. The set is consistent; its visibility is not.
- A framing clause that names the shot but not the camera (axis, height, side, tilt) — the engine fills the gaps with a three-quarter view from above.
