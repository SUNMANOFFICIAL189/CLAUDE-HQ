---
name: handoff
description: >
  The single, project-agnostic handoff skill. One living HANDOFF.md per project is the source of
  truth for resuming with zero context lost. Bare `/handoff` RESUMES (read-only): loads the doc +
  constitution, validates them against the actual code, flags drift (the code wins on conflict),
  summarises, and waits. `/handoff save` CHECKPOINTS: reconciles this session's work against disk
  (CTDD), actively prompts for the context that only lives in chat (failed approaches, running
  processes, uncommitted work, the operator-confirmed next action), runs a fail-closed secret gate,
  then updates the lean living doc + its append-only Session Log. Callable at ANY time, not just at
  session end. It is the SOLE writer of HANDOFF.md and supersedes the scattered handoff mechanisms.
  Triggers: "/handoff", "/handoff save", "resume this project", "hand off", "checkpoint", "save the
  handoff", "pick up where we left off", "write a handoff so we can continue in a new session".
---

# /handoff — one living context doc, zero loss, project-agnostic

## What this is
The one command that ends a session and starts a new one with **zero context lost**, in **any**
project, without you re-describing anything. There is exactly **one living `HANDOFF.md` per project**
(plus a stable constitution file) and this skill is its **only writer**. It replaces the scattered,
drifting handoff files HQ had accumulated.

**North-star model:** the handoff document is a *lossy index*, not the truth. **The code/canonical
files are authoritative. When the document and the code disagree, the CODE WINS.** This is the single
most important rule — it is why a resumed session never inherits a stale claim (HQ LESSON 26).

## Two modes (never guess the destructive one)
- **`/handoff`** (bare, or "resume …") → **RESUME**. Read-only. Safe default. Never writes.
- **`/handoff save`** (or "checkpoint / save the handoff") → **CHECKPOINT**. The only mode that writes.
- Any ambiguous phrasing defaults to **RESUME** (read-only). Writing requires the explicit `save` verb.

---

## STEP A — Locate the canonical document (both modes start here)
Run the locator; never guess a single path:

```
bash "$HOME/.claude/skills/handoff/scripts/locate.sh"
```

It prints one of:
- `CANONICAL <abs-path>` — use it.
- `UNREACHABLE <abs-path>` — the recorded doc is on an unmounted/missing volume. **STOP. Do NOT create
  a new doc** (that would fork a decoy). Tell the operator: "your handoff lives at `<path>` — mount that
  volume." (fixes the external-drive/decoy failure.)
- `NONE <default-abs-path>` — no handoff exists yet; `<default>` is `‹repo-root›/HANDOFF.md` (or cwd if
  not a git repo). On SAVE, create it there. On RESUME, say "no handoff yet — starting fresh."
- `AMBIGUOUS` followed by candidate paths — **more than one** handoff-shaped file exists. **Ask the
  operator once** which is canonical, then record the choice:
  `bash "$HOME/.claude/skills/handoff/scripts/locate.sh" --set "<chosen-abs-path>"`
  (writes `‹repo-root›/.claude/handoff-path`). After that the path is deterministic forever.

The **constitution** is `‹same-dir›/HANDOFF_CONSTITUTION.md` unless the project already has a `CLAUDE.md`
or `README.md`, in which case link to that instead of duplicating (anti-clutter).

---

## RESUME  (`/handoff`)
Goal: rebuild full context and hand yourself a clean starting point, trusting the code over the doc.

1. **Read** the canonical `HANDOFF.md` in full, then the constitution (or the `CLAUDE.md`/`README` it
   points to), then every file listed under **Pointers**.
2. **Validate against disk (code wins).** For each material claim in *Current State* and the *starred
   next action*, check it against the actual code/config/git state. Anything the code contradicts is
   **DRIFT** — trust the code, and flag it: `DRIFT: doc says X; code shows Y (file:line) → using Y`.
   Treat every claim tagged `[auto]` / `[unconfirmed]` as a hypothesis until you've validated it.
3. **Report back in under ~200 words:** the goal, the current state (with any drift corrections), the
   top open actions, and the single starred next action. Then **stop and wait** for the operator's go.
   Do not start work off an unvalidated handoff.
4. If drift was found, offer to fold the correction into the doc via `/handoff save` (per LESSON 26,
   fix the stale source this session so the next one inherits truth).

---

## SAVE  (`/handoff save`)  — the only writing mode
Apply **CTDD at every step**: verify against disk; never record an unverified claim as fact.

1. **Read** the current `HANDOFF.md` (locator STEP A). Inventory two sources: (a) everything decided,
   built, tried, or changed this session; (b) the actual current state of the repo on disk.
2. **Reconcile.** Verify every claim against the repo. Anything you cannot verify → mark **ASSUMPTION**
   and list it. Never write an unverified claim as fact.
3. **Actively PROMPT for the chat-only losses** (these are the things a disk scan cannot see — capture
   them or they are gone forever):
   - **What Didn't Work / Dead Ends** — approaches tried and abandoned, and *why* (the anti-repeat signal).
   - **Runtime / Environment** — what's running (processes, ports, dev servers, background jobs, feature
     flags) and **where uncommitted work sits** (dirty files, stashes, untracked scratch).
   - **The next action** — propose it, but it must be **operator-confirmed**, not your guess. Star it.
   - Any verbal constraints/approvals given in chat but not yet actioned.
   If a section legitimately has nothing, **write "nothing here" — never invent content to fill a header.**
4. **Update the lean living doc** (template: `templates/HANDOFF.template.md`). Rewrite the volatile
   sections to current truth; **Current State leads with a coherent narrative paragraph**, bullets after.
   Tag each Current-State claim `[firsthand]` (you did/saw it) or `[relayed]` (from a summary), and
   `[confirmed]` or `[unconfirmed]`.
5. **Append-only Session Log + Decision Log.** Add a new dated entry at the top of the Decision Log with
   rationale + rejected alternatives, provenance-tagged `[Sunil]` / `[Claude]` / `[Joint]`. **Never edit
   or delete a prior entry.** Push deep detail into canonical files and link them from **Pointers** —
   keep HANDOFF.md a map, not a dump.
6. **Constitution:** only touch it if near-static facts changed (identity, mechanics, setup, principles,
   repo layout, glossary, risks). Glossary is add-only; never redefine a term.
7. **SECRET GATE (fail-closed) — gate the EXACT bytes you will keep.** Write the finished proposed
   content to a temp file (or the destination), then scan THAT file — never gate the old file and then
   write new content (that validates stale bytes):
   ```
   bash "$HOME/.claude/skills/handoff/scripts/secret-gate.sh" <the-proposed-file-you-just-wrote>
   ```
   **Exit 0 = clean → proceed. ANY non-zero exit (1 = secret found, 2 = missing/unreadable, or anything
   else) → DO NOT KEEP OR COMMIT the file — fail closed.** On a hit: show the redacted offending line,
   remove the secret (environment-variable NAMES only — never values, never pasted `env`/config/log/
   response dumps), re-run the gate. The doc is committed to git; a leak is permanent. This is
   structural, not a convention. (Note: the gate is line-based — never paste a multi-line credential
   blob into a handoff regardless.)
8. **OUTPUT GATE (stop and wait).** Show a concise diff summary of every change + every ASSUMPTION.
   **Wait for explicit go.** Write nothing before the operator responds.
9. **On go:** write the **already-gated** content (the exact bytes from step 7) to the destination.
   Do **not** `git add -A` or commit here — chain **`/sync`** for the git step (it runs its own preview
   + secret scan). Report exactly what changed and where.

---

## Sub-task handoffs (chaining within a project)
For a bounded sub-task that will hand back (e.g. `explore → build → hand back`), you may write a
**scoped** handoff at `‹same-dir›/HANDOFF.<slug>.md` with a `chain:` header naming its parent
`HANDOFF.md`. It follows the same template + secret gate. This keeps sub-task batons out of the main
living doc while preserving one project truth. Retire it (fold its outcome into the main Decision Log)
when the sub-task closes.

---

## Consolidation — this skill is the single source of truth
- `/handoff` is the **sole writer** of `HANDOFF.md`. Nothing else writes it.
- **`/save`** keeps owning the other memory layers (auto-memory note, Obsidian, MemPalace, graphify,
  claude-mem) and **delegates its HANDOFF layer to `/handoff`** — it no longer edits HANDOFF.md directly.
- **`/sync`** stays git-only (the commit/push step this skill chains to).
- ECC `save-session`/`resume-session` and PAUL `/paul:handoff` are **superseded** for HANDOFF authoring;
  don't invoke them to write a handoff (they'd re-fragment the truth).

## How the automatic pieces fit (honest about what each can do)
- **Session start (hook):** `session-start.sh` auto-detects the canonical HANDOFF and surfaces it with
  the starred next action, so you never type anything to see where you left off. You run `/handoff` to
  fully resume.
- **Mid-session (this skill):** `/handoff save` any time — the **rich** capture (it has the full
  conversation; it can capture the "why", the dead ends, the intent).
- **Session end (hook):** `session-end.sh` appends a **mechanical** `[auto-mechanical/unconfirmed]`
  Session-Log line (git delta only — a bash hook has no LLM, so it cannot write the rich narrative).
  It is a *safety floor* that guarantees a trail even if `/handoff save` was never run; the next resume
  treats it as unconfirmed and reconstructs the detail from git + code. **For a full checkpoint, run
  `/handoff save` before ending** — proactively offer it when the session is wrapping up.

## Hard constraints (always)
- The code is authoritative; on doc-vs-code conflict, the **code wins**.
- Decision Log + Session Log are **append-only**. Never edit/delete a prior entry.
- Never record an unverified claim as fact — mark ASSUMPTION and surface it.
- A section may be legitimately empty — say "nothing here", never invent to fill a header.
- **No secrets** — environment-variable NAMES only; fail-closed secret gate before every write.
- Never create a decoy doc when the canonical one is unreachable — tell the operator to mount it.
- No naked `git add -A`; commits are delegated to `/sync`.
- Bare `/handoff` is read-only; only `/handoff save` writes.

## Pairs with
`/save` (full memory-layer sync — defers HANDOFF to this skill), `/sync` (git), `ctdd-precheck`
(verify-before-claim), `proof-check` (pre-ship gate). Chassis is the OFFLIMITS living-context method;
grafts: APM code-wins framing, ykdojo Dead-Ends section, mattpocock structural secret containment.
