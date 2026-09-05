# STYLE_LOCK: [PROJECT NAME]

The governing guide for every generated image in this project. It locks the constants (the red thread) and defines how they flex per shot. Read before any generation. Fill every bracket; delete the guidance notes once filled.

Created: [DATE]
Engine: [ENGINE + MODEL] (see the skill's references/engine-adapters.md)
Status: [in progress / world model confirmed / anchor set locked / grade locked / set locked]
Method: anchor-set delta model (four layers — world model, anchor set, shot spec/delta rule, gates; see the skill's SKILL.md "core idea")

## 0. The red thread (what never changes)

Every image reads as a page from the same campaign. The constants below hold across every shot; only the variables in Section 3 move.

| Constant | Rule |
|---|---|
| Engine | [model — Higgsfield + GPT Image 2, or AtlasCloud + GPT Image 2 (edit); see references/engine-adapters.md]; 1k/test-size to explore and to lock composition, 2k/4k or hi-res only for approved finals. |
| Grade | [the locked plain-language grade clause; keep it simple; do not over-specify]. |
| Focus | [default depth-of-field tendency only, e.g. deep focus by default. Optics, depth of field and subject scale are per shot family, not a single project constant — the authoritative values per family live in §0.6 (Anchor set) and §2.5 (Shot specs), and they override this default wherever they differ.] |
| Posing | [general posing tendency, e.g. natural, candid, unposed. The specific performance beat for each shot is recorded per shot in §2.5 — this row is the fallback tendency, not a substitute for a beat.] |
| Consistency | Attach the shot's chosen anchor(s) (§0.6, recorded per shot family) on every generation plus the match-the-reference clause. Never rely on prompt text alone for colour, and never assume one anchor covers every camera position. |
| Casting | [who appears across the set; representation rule]. |
| Wardrobe | [wardrobe and key props]. |
| Palette in frame | [the colours that lead; the accents]. |
| Text and marks | [logo and text policy; what is allowed in-frame vs added in layout]. |
| Authenticity | [imperfection rule, if any, e.g. 97% polish + 3% human detail]. |
| Default aspect | [default proportion + the engine's supported ratios]. |

## 0.5 Element inventory (derived from the anchor + supplied text; agent-written, operator-confirmed)

Class is ALWAYS (identity, wardrobe, key prop, light, grade — present in every frame), SET (framing-conditional — part of the world, present only when a shot's framing covers it), or VARIABLE (changes with framing). Every SET row must name which shot types see it — that column is the visibility map referenced in Section 3 and by Steps 3a/6b's per-shot checks. A SET element correctly absent from a shot whose framing would not see it is not a miss. Every row also carries a **bearing relative to the subject, never the frame** — frame-left/right inverts as the camera orbits, so a frame-relative bearing becomes wrong the moment the shot list adds a new camera position.

| Element | Class (ALWAYS/SET/VARIABLE) | Bearing (relative to the subject) | Visible in (shot types) | Distinctive noun (for the request check) | Source (image/text/both) | Notes |
|---|---|---|---|---|---|---|
| [e.g. the subject's watch] | [ALWAYS] | [on the wrist of the leading arm] | [every shot type] | [watch] | [both] | [operator named it; image confirms it; present in every frame] |
| [e.g. the lamp] | [SET (framing-conditional)] | [beyond the subject's right shoulder, at head height] | [wide shot, three-quarter shot — not the close-up, which crops it out of frame] | [lamp] | [image] | [reproduce exactly whenever the shot's framing covers it; never force it into a frame whose angle would not see it] |
| [e.g. shot framing] | [VARIABLE] | — | — | — | [text] | [changes per shot, see Section 3 flex matrix] |

### Continuity facts (first-class, not part of the presence inventory)

A presence-based inventory only asks "is it there" — it never watches handedness, leading side, crossing direction, or facing, so those flip silently between shots unless checked here as their own facts.

| Fact | Value | How to verify in a render |
|---|---|---|
| [e.g. which hand holds the hero prop] | [the subject's left hand] | [check the render shows the prop in the left hand, not mirrored to the right] |
| [e.g. which shoulder leads] | [the right shoulder leads, angled toward camera] | [check the shoulder line in the render matches, not reversed] |
| [e.g. which way the arms/limbs cross] | [left arm crosses in front of the right] | [check the crossing order in the render, not swapped] |
| [e.g. which way the subject faces] | [three-quarter toward the anchor's camera position] | [check gaze/body orientation in the render against this fact, not just "facing camera"] |

## 0.6 Anchor set (per shot family, agent-built from Step 1b, operator-confirmed)

One anchor cannot specify what every camera position needs — a single overhead under-determines a water-level close-up. This table is what makes the delta rule computable: the SHOWS and LACKS columns are load-bearing, not decorative. Draw anchors from the material the operator actually wants the result to resemble; flag any shot family with no anchor that serves it rather than letting a distant one stand in silently.

| Anchor | Shot families it serves | SHOWS | LACKS | Optics (lens, depth of field) | Grade | Camera position | Subject scale |
|---|---|---|---|---|---|---|---|
| [e.g. Anchor A — id/name] | [wide establishing shots] | [setting, overall light, grade, wardrobe silhouette] | [the hero prop; the subject's face at usable resolution] | [wide lens feel, deep focus] | [Grade A, see Section 1] | [overhead / frontal / lateral-perpendicular — height — distance] | [small in frame] |
| [e.g. Anchor B — id/name] | [close / detail shots] | [skin/material texture, hero prop, shallow depth of field] | [the wider setting; any SET element outside the crop] | [longer lens feel, shallow depth of field] | [Grade A, see Section 1] | [frontal — eye level — close distance] | [large in frame] |
| [flag: shot family with no anchor] | [name the family] | — | — | — | — | — | — |

## 1. The grade(s)

Define one grade, or two if the project needs a colour look and a bright look.

### Grade A: [name]
For [which shot types]. Anchors carrying this grade: see Section 0.6 (Anchor set) — the shot families that use this grade, and which anchor(s) serve each, are listed there rather than pinned to a single ID here.

> Grade clause (paste into prompts, keep simple): "[the locked clause]"

### Grade B: [name, optional]
For [which shot types]. Anchors carrying this grade: see Section 0.6.

> Grade clause: "[the locked clause]"

Discipline note: record any grade wording that caused drift here, so it is never reintroduced. [e.g. "golden amber" went golden; "clean and airy, not milky" went cool and flat.]

## 1.4 The look, dissected (definitive spec)

A breakdown of the approved reference so the look reproduces on any shot. Treat everything here as the project's *default* — the starting description before any shot family's own anchor and shot spec are built. Lens/optics, depth of field, and subject scale are per shot family (see Section 0.6 and Section 2.5); where a shot family's anchor differs from the default below, the anchor and its shot spec win, not this section.

### Colour and grade
- White balance: [warm-neutral / neutral / cool; how whites read].
- Saturation: [level; which colour leads; "not neon", "not muted"].
- Contrast: [level; how shadows and highlights behave].
- Shadow tone: [neutral / warm / cool; no unwanted cast].
- Character: [film/grain/finish in one line].

### Lighting
- Key: [source, direction, softness].
- Practicals: [any in-scene lights and their role].
- Quality: [harshness, shadow behaviour].

### Lens and optics
- Focal length: [range].
- Camera height: [eye-level / low / high].
- Focus: [deep focus / shallow; bokeh policy].

### Composition
- [balance, anchors, headroom, where type will sit].

### Texture and finish
- [grain, skin texture, material finish].

### Casting and expression
- [demographics, skin, makeup, gaze, mood].

### The only variables
- Shot type: [wide / mid / close].
- Who is in frame and their arrangement.
- Location / backdrop.
- Proportion.

## 1.5 Recurring delta text (reuse verbatim within a shot family)

There is no single whole-scene master prompt under the anchor-set delta model — each shot's actual prompt is computed live in Section 2.5 as (required-in-frame) MINUS (what that shot's chosen anchor already shows) + the camera move + the beat. What genuinely holds constant, and is worth locking word-for-word here, is any delta clause that recurs identically across every shot inside one shot family — i.e. a required element that family's anchor always LACKS (per Section 0.6), or the asset-fidelity instruction, or the text/logo exclusion clause. Lock each recurring clause below; reuse it verbatim wherever that shot family's anchor is used. Do not restate anything the family's anchor already SHOWS — that belongs nowhere in this file as prompt text, only as a row in Section 0.6.

> Shot family: [name] — recurring delta clause (paste into every shot in this family that uses the same anchor): "[the locked clause — only what the anchor LACKS, the asset-fidelity instruction if branded, and the exclusion clause; nothing the anchor already shows]"

Add one such block per shot family that has a genuinely recurring delta. A shot family whose every shot needs a different delta has nothing to lock here — go straight to Section 2.5.

## 1.6 Consistency mechanism

Prompt text alone cannot hold colour across framings. Enforce two ways on every generation:

1. Attach the shot's chosen anchor(s) — per shot family, from Section 0.6, registered by ID in Section 6 — in the engine's reference field. Never substitute a different shot family's anchor on the assumption that "it's close enough."
2. Append: "Match the colour, white balance and grade of the reference image exactly. [Add the project's specific neutral-WB guard, e.g. whites stay clean, warm sources must not tint the frame.]"

Production-final option: once approved frames are local, colour-match the set to the grade anchor in one post pass for pixel-level consistency.

## 1.7 Reference order

The order of references sent to the engine is a control, not a formality, and it applies within every shot's own reference call (a shot may combine its shot-family anchor from Section 0.6 with an asset anchor). Record the default ordered list per shot family here, and what each later reference is allowed to steer; note any shot that departs from the default.

1. [Scene/grade anchor for this shot family (Section 0.6) — dominates composition and scene. Always first.]
2. [Identity or asset reference — steers a specific attribute only, e.g. "steers the shape of the subject's eyewear" or "steers the finish of the hero prop". Never first.]
3. [Additional reference, if any — state exactly what it may change and nothing else.]

Do not drop or reorder a reference on theory. A/B it at test size first (with/without) before treating the result as settled.

## 1.8 Dialogue and text policy

Dialogue, script lines, and captions are stripped from every prompt built from a storyboard or script; only the action and framing are described. What replaces the dialogue is the performance beat, recorded per shot in Section 2.5 — never the dialogue's own words. Exclusion clause (append verbatim to every prompt): "no text, no words, no captions, no subtitles."

## 2. Shot categories

List the shot *families* this project needs — the level Section 0.6's anchor set and Section 3's flex matrix are indexed by. For each, state a complete framing clause — camera axis relative to the subject (overhead / frontal / lateral-perpendicular), height (overhead / head height / eye level / water level), the subject's side shown (left/right) where relevant, tilt (level / down / up), and distance (shot size); for planimetric styles add "squared to the frame, level horizon" — plus setting, grade, lens, light, and which SET elements this framing sees (cross-reference the visibility map in Section 0.5). This section defines each family once; the per-shot build for every individual shot inside a family — chosen anchor, required-in-frame list, delta, beat, frame exclusions — is Section 2.5.

- [2.1 type]: [axis / height / side / tilt / distance] — [setting, grade, lens, light, SET elements in view]
- [2.2 type]: [axis / height / side / tilt / distance] — [setting, grade, lens, light, SET elements in view]
- [2.3 type]: [axis / height / side / tilt / distance] — [setting, grade, lens, light, SET elements in view]

## 2.5 Shot specs (per shot; the delta prompt is computed here)

One row per shot. This is where the delta rule (SKILL.md, Layer 3) is actually executed: **prompt = (required-in-frame) MINUS (what the chosen anchor already shows) + the camera move + the beat.** The DELTA column is what must be named in the built prompt; it must never include anything the chosen anchor already SHOWS (Section 0.6), and it must include everything required that the anchor LACKS.

| Shot | Shot family (§2) | Chosen anchor (§0.6) | Camera position (axis / height / side / tilt / distance) | Required-in-frame (ALWAYS + SET this framing sees + beat) | DELTA — must be named (anchor LACKS + any corrections) | Performance beat | Frame exclusions |
|---|---|---|---|---|---|---|---|
| [e.g. Shot 1] | [family name] | [anchor id/name] | [axis / height / side / tilt / distance] | [list, drawn from §0.5] | [only what the anchor LACKS or shows differently — never what it already shows] | [what the subject is doing at this instant] | [e.g. nothing visible above the horizon line] |
| [e.g. Shot 2] | [family name] | [anchor id/name] | [axis / height / side / tilt / distance] | [list] | [list] | [beat] | [exclusions, or "none beyond the anchor's own"] |

Medium: name it in the DELTA column only if the chosen anchor does not already establish it (see SKILL.md Layer 3 — "Medium"). Never add a medium word the shot does not want.

## 3. The flex matrix

Constants hold down every column. Only the variable rows move. Optics, depth of field, subject scale and frame exclusions are per shot family (per column) — never one value copied across every column.

| | [type 1] | [type 2] | [type 3] |
|---|---|---|---|
| Grade | | | |
| Focus | | | |
| Lens | | | |
| Angle | | | |
| Camera (axis / height / side / tilt) | | | |
| Light | | | |
| Setting | | | |
| Set dressing in view | | | |
| Subjects | | | |
| Subject scale | | | |
| Frame exclusions | | | |
| Headroom / type space | | | |
| Text/logo policy | | | |

## 4. Aspect and resolution workflow

| Use | Aspect | Notes |
|---|---|---|
| [destination] | [ratio] | [note] |

Workflow: generate at 1k to lock composition and grade; re-run the approved frame at 2k/4k only when the operator asks for the final.

## 5. Casting, wardrobe, props

- Casting: [detail].
- Wardrobe: [detail].
- Hero prop: [detail].
- Set dressing: [detail].
- Handedness, leading side, and facing for these items are not repeated here — see the Continuity facts sub-table under Section 0.5, which is the single source checked at render time (Step 6b).

## 6. Reference anchors

The ID registry for every anchor named in Section 0.6 (Anchor set). Section 0.6 is the operational table — which anchor serves which shot family, and its SHOWS/LACKS, optics, grade, camera position, and subject scale; this section is the flat list of real engine job/media IDs behind those names, reused as references on every generation:
- Anchor [name/id, per Section 0.6 — one line per anchor]: `[id]` ([what it is, when approved, which shot families it serves — cross-reference Section 0.6]).
- Brand-asset anchor (CANONICAL, project-wide): `[id]` (the uploaded logo/mark; instruct "reproduce exactly, do not redraw or recolour"). [Note any upload constraint and the workaround.]
- Composition-only references (look not matched, used for layout/cast): `[ids]`.

External register references (mood only, never copied): [list].
Real-source references (ground truth for setting/asset): [list].

## 7. Reusable prompt templates

Under the delta rule there is one *built* prompt per shot (Section 2.5), not a single template — but a shot family whose shots share a chosen anchor typically shares the same recurring delta clause too (Section 1.5). Record one reusable delta-clause template per shot family here: the fixed part (what the family's anchor always LACKS, plus policy clauses) with the camera move and the beat left as the only brackets that move shot to shot.

- [Shot family]: "[recurring delta clause] + [camera position — varies per shot, see §2.5] + [beat — varies per shot, see §2.5]"

## 8. QC checklist (before any frame is approved)

Run references/qc-checklist.md — delta check (pre-spend), element presence (post-render, per-shot), continuity, camera honoured, no invention, grade and optics, technical. Project-specific additions:
- [any project-specific check].

## Provenance

- Created [date] from [reference source].
- Method: anchor-set delta model (world model / anchor set / shot spec + delta rule / gates).
- [version notes: what locked, what was corrected and why].
- Engine: [model].
- Operator approved at: [gate + date].
