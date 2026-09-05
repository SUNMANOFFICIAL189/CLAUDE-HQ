# QC checklist

Run before approving any frame. The delta check runs pre-spend, mechanically, on the built prompt text. Everything else runs post-render, on the actual image, wherever the render reaches a local file the agent can open; where it does not, the operator runs it by eye. The agent presents the frame and waits.

## Delta check (pre-spend, mechanical)
- [ ] Every item on this shot's DELTA list (STYLE_LOCK §2.5) — everything required that the chosen anchor LACKS, plus any correction to something the anchor shows differently — actually appears in the built prompt text, in words.
- [ ] The built prompt does NOT also restate anything the chosen anchor already SHOWS (per its Section 0.6 inventory). A redundant restatement is a failure in its own right, not a harmless extra.
- [ ] The medium is named only if the anchor does not already establish it — no medium word added out of habit.
- [ ] A missing per-shot required-in-frame list, or a missing anchor SHOWS/LACKS inventory, is itself a FAIL — there is no bypass by omission; the check cannot run without them.
- [ ] The job was quoted through the platform's calculator (or a minimum-size job's real charge was read) and the wallet balance checked, before submission.

## Element presence (post-render, per-shot list — agent-run where the render is visible)
- [ ] Every ALWAYS element from the STYLE_LOCK element inventory (§0.5) is visibly present — list them by name when running this check (for example: "the desk", "the subject's watch").
- [ ] Every SET element the visibility map says this shot type sees is visibly present — and no SET element is forced into a shot whose framing would not naturally see it. This is a per-shot check against that shot's own list, never a single global list.
- [ ] Eyewear and prop shapes match the anchor image, not a secondary reference.
- [ ] No burned-in text, captions, or subtitles appear anywhere in the frame.
- [ ] The logo or mark reproduces exactly; it is not redrawn, recoloured, or distorted; text and logo policy is honoured (only the allowed marks appear in-frame).
- [ ] Wardrobe and key props match the locked spec; casting is consistent with the set and the project's representation rule.
- [ ] The performance beat specified for this shot (§2.5) is visibly happening — a frame with the right camera position and no beat is a held pose, not the moment that was asked for.
- [ ] A missing ALWAYS element, a SET element forced into (or missing from) the wrong shot, or a missing beat is a FAIL, not a note — re-run it or flag it explicitly.

## Anatomy and guards
- [ ] Hands, fingers and limbs are correct in number and articulation — count them; a strong anchor does not prevent a duplicated limb.
- [ ] No text, captions or subtitles anywhere in frame.
- [ ] If a named attribute correction did not land, record it: the next attempt changes the anchor or adds a reference, it does not re-word the prompt.

## Continuity
- [ ] Every fact in the STYLE_LOCK Continuity facts sub-table (§0.5) is correct in the render: which hand holds which prop, which arm or shoulder leads, which way limbs cross, which way the subject faces.
- [ ] None of these facts has silently flipped relative to the anchor or the locked spec — a presence check alone would miss this; check it explicitly.
- [ ] Any continuity mismatch is a FAIL, not a note.

## Camera honoured
- [ ] The camera position specified in the shot spec (§2.5) was honoured: axis relative to the subject, height, subject side, tilt, and distance/shot size — not just the shot name.
- [ ] For planimetric styles: squared to the frame, level horizon.
- [ ] Headroom or clear area for type is present where the destination needs it.

## No invention
- [ ] Nothing appears in the frame that is not in the world model (§0.5) or a named delta (§2.5) — no invented elements, no invented scenery, no invented set dressing.
- [ ] Nothing was carried over from a different project's anchors or STYLE_LOCK.
- [ ] Placed beside the rest of the set, this frame reads as the same shoot — no stylistic foreign body, even if no single invented object can be pointed to.

## Grade and optics
- [ ] Colour and white balance match the shot's chosen anchor (§0.6) — not warmer, not cooler, not flatter — for that anchor's own shot family, not a different family's grade.
- [ ] Contrast and shadow tone match the dissected spec (§1.4) or the shot family's own anchor where it overrides the default.
- [ ] No drift word reintroduced (check the STYLE_LOCK discipline note, §1).
- [ ] Focus policy (depth of field) is correct for this shot family's own optics (§0.6 / §3) — not inherited wholesale from a different shot family's anchor.

## Technical
- [ ] Aspect ratio correct for the destination.
- [ ] Resolution correct for the stage (1k for test and composition; hi-res only for an approved final).
