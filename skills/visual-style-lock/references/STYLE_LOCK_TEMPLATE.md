# STYLE_LOCK: [PROJECT NAME]

The governing guide for every generated image in this project. It locks the constants (the red thread) and defines how they flex per shot. Read before any generation. Fill every bracket; delete the guidance notes once filled.

Created: [DATE]
Engine: [ENGINE + MODEL] (see the skill's references/engine-adapters.md)
Status: [in progress / grade locked / set locked]

## 0. The red thread (what never changes)

Every image reads as a page from the same campaign. The constants below hold across every shot; only the variables in Section 3 move.

| Constant | Rule |
|---|---|
| Engine | [model — Higgsfield + GPT Image 2, or AtlasCloud + GPT Image 2 (edit); see references/engine-adapters.md]; 1k/test-size to explore and to lock composition, 2k/4k or hi-res only for approved finals. |
| Grade | [the locked plain-language grade clause; keep it simple; do not over-specify]. |
| Focus | [depth-of-field policy, e.g. deep focus throughout, no bokeh]. |
| Posing | [posing rule, e.g. natural, candid, unposed]. |
| Consistency | Attach the grade anchor (Section 6) on every generation plus the match-the-reference clause. Never rely on prompt text alone for colour. |
| Casting | [who appears across the set; representation rule]. |
| Wardrobe | [wardrobe and key props]. |
| Palette in frame | [the colours that lead; the accents]. |
| Text and marks | [logo and text policy; what is allowed in-frame vs added in layout]. |
| Authenticity | [imperfection rule, if any, e.g. 97% polish + 3% human detail]. |
| Default aspect | [default proportion + the engine's supported ratios]. |

## 0.5 Element inventory (derived from the anchor + supplied text; agent-written, operator-confirmed)

| Element | Class (FIXED/VARIABLE) | Distinctive noun (for the request check) | Source (image/text/both) | Notes |
|---|---|---|---|---|
| [e.g. the desk lamp] | [FIXED] | [lamp] | [image] | [must appear in every shot] |
| [e.g. the subject's watch] | [FIXED] | [watch] | [both] | [operator named it; image confirms it] |
| [e.g. shot framing] | [VARIABLE] | — | [text] | [changes per shot, see Section 3 flex matrix] |

## 1. The grade(s)

Define one grade, or two if the project needs a colour look and a bright look.

### Grade A: [name]
For [which shot types]. Anchor: [grade anchor ID].

> Grade clause (paste into prompts, keep simple): "[the locked clause]"

### Grade B: [name, optional]
For [which shot types]. Anchor: [grade anchor ID].

> Grade clause: "[the locked clause]"

Discipline note: record any grade wording that caused drift here, so it is never reintroduced. [e.g. "golden amber" went golden; "clean and airy, not milky" went cool and flat.]

## 1.4 The look, dissected (definitive spec)

A breakdown of the approved reference so the look reproduces on any shot. Everything here stays constant.

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

## 1.5 Master prompt (locked)

The canonical prompt. Reuse verbatim; change only the bracketed variable clause. Holding this constant is the strongest guarantee of the red thread.

> "[Full master prompt with every invariant written out, and exactly one bracketed clause: [SUBJECT / COMPOSITION / LOCATION]. Include wardrobe, environment, the grade clause, focus clause, posing clause, and the text/logo policy.]"

Swap only the bracket per shot. For a second grade or a branded shot, keep this structure and substitute the relevant grade clause and the asset instruction.

## 1.6 Consistency mechanism

Prompt text alone cannot hold colour across framings. Enforce two ways on every generation:

1. Attach the grade anchor (Section 6) in the engine's reference field.
2. Append: "Match the colour, white balance and grade of the reference image exactly. [Add the project's specific neutral-WB guard, e.g. whites stay clean, warm sources must not tint the frame.]"

Production-final option: once approved frames are local, colour-match the set to the grade anchor in one post pass for pixel-level consistency.

## 1.7 Reference order

The order of references sent to the engine is a control, not a formality. Record the exact ordered list here and what each later reference is allowed to steer.

1. [Scene/grade anchor — dominates composition and scene. Always first.]
2. [Identity or asset reference — steers a specific attribute only, e.g. "steers the shape of the subject's eyewear" or "steers the finish of the hero prop". Never first.]
3. [Additional reference, if any — state exactly what it may change and nothing else.]

Do not drop or reorder a reference on theory. A/B it at test size first (with/without) before treating the result as settled.

## 1.8 Dialogue and text policy

Dialogue, script lines, and captions are stripped from every prompt built from a storyboard or script; only the action and framing are described. Exclusion clause (append verbatim to every prompt): "no text, no words, no captions, no subtitles."

## 2. Shot categories

List the shot types this project needs. For each: setting, grade, lens, angle, light, framing.

- [2.1 type]: [spec]
- [2.2 type]: [spec]
- [2.3 type]: [spec]

## 3. The flex matrix

Constants hold down every column. Only the variable rows move.

| | [type 1] | [type 2] | [type 3] |
|---|---|---|---|
| Grade | | | |
| Focus | | | |
| Lens | | | |
| Angle | | | |
| Light | | | |
| Setting | | | |
| Subjects | | | |
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

## 6. Reference anchors

Locked anchors (engine job/media IDs; reuse as references on every generation):
- Grade anchor (CANONICAL): `[id]` ([what it is, when approved]).
- Brand-asset anchor (CANONICAL): `[id]` (the uploaded logo/mark; instruct "reproduce exactly, do not redraw or recolour"). [Note any upload constraint and the workaround.]
- Composition-only references (look not matched, used for layout/cast): `[ids]`.

External register references (mood only, never copied): [list].
Real-source references (ground truth for setting/asset): [list].

## 7. Reusable prompt templates

One template per shot category. Each fills the brackets and reuses the locked grade and policy clauses.

- [Category]: "[template]"

## 8. QC checklist (before any frame is approved)

Run references/qc-checklist.md. Project-specific additions:
- [any project-specific check].

## Provenance

- Created [date] from [reference source].
- [version notes: what locked, what was corrected and why].
- Engine: [model].
- Operator approved at: [gate + date].
