---
name: capture
description: >
  Frictionless capture, triggered by /capture. Instantly saves whatever you dump (a thought,
  task, idea, reference, link) to captures/INBOX.md so it is NEVER lost, then auto-categorizes
  it (TASK / IDEA / REFERENCE / NOTE / EVENT) and routes it to the right HQ home (BACKLOG,
  memory, Obsidian). Archive-never-delete: processed entries are marked filed, never removed.
  Speed-first on capture; CTDD only where routing is ambiguous or high-stakes. Adapted from
  the Obsidian Personal OS capture pattern to HQ's existing homes. Sibling to /save and /sync.
---

# /capture — Frictionless capture inbox (works in any project)

Triggered by `/capture <whatever>`. Two-phase, mirroring the Obsidian Personal OS pattern:
capture FAST (never lose it), then categorize + route. Adapted to HQ's real homes, not a
new 8-folder vault.

## Core promise
**Never lose a capture. Never delete one.** Capture is speed-first — no decisions block the
save. Categorization happens after the input is already safe on disk.

## STEP 0 — Capture instantly (the safety net — do this FIRST, always)
Append the raw input verbatim to `~/claude-hq/captures/INBOX.md` with an ISO-8601 timestamp:
```
- [2026-06-05T14:32Z] <raw input verbatim>   <!-- status: new -->
```
Create `captures/INBOX.md` if missing. Do this BEFORE any analysis — if anything else fails,
the thought is already saved. Never edit/overwrite prior lines; append only.

## STEP 1 — Categorize
Tag the entry as exactly one of:
- **TASK** — something to do ("fix X", "email Y", "chase Z")
- **IDEA** — a possibility/improvement worth keeping ("what if we…")
- **REFERENCE** — a fact/link/resource to keep findable
- **NOTE** — context/observation tied to a project or topic
- **EVENT** — something time-bound (date/deadline/meeting)
Also detect a **project tag** if it clearly relates to a known project (flightclub, PATS-Copy,
OFFLIMITS, claude-hq, etc.). If unclear, leave untagged.

## STEP 2 — Route to the right HQ home
- **TASK / IDEA** → append to the relevant `BACKLOG.md` (project's if tagged; else
  `~/claude-hq/docs/BACKLOG.md`) as a one-line `[Open]` note. (HQ rule 18: BACKLOG is the
  canonical "note for later".)
- **REFERENCE** → a `reference_*.md` memory file, or the project's Obsidian `Resources`/notes.
- **NOTE (project-tagged)** → the project's auto-memory note; **(general)** → leave in INBOX,
  tagged, for later.
- **EVENT** → surface to the operator (HQ has no calendar integration) AND keep in INBOX
  tagged `EVENT` so it is not lost.
Keep routing destinations to existing homes — do NOT fabricate new folders or vaults.

## STEP 3 — Mark filed (archive-never-delete)
Update the INBOX line's status marker in place — `status: new` → `status: filed → <dest>`.
**Never delete the INBOX entry.** It is the audit trail.

## STEP 4 — Report (terse — keep it fast)
One line: `Captured → <CATEGORY> [project] → filed to <dest>.` Nothing more unless asked.

## CTDD (only where it matters — don't slow capture down)
- Capture (STEP 0) is unconditional and instant — never gated.
- Only PAUSE to confirm if routing is **ambiguous** (could be two homes) or **high-stakes**
  (e.g. it implies deleting/overwriting something, or a money/secret/irreversible action).
- Never write a secret into any tracked file (env-var names only).
- Never overwrite; append only. Never delete a capture.

## Relationship to other skills
- `/capture` = fast inbox for single thoughts (this skill).
- `/save` = full end-of-session persistence across all memory layers (calls `/sync`).
- `/sync` = safe two-way git sync of the current repo.
- A future scheduled "capture processor" (BACKLOG) could batch-process INBOX leftovers.
