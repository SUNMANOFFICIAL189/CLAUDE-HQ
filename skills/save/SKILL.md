---
name: save
description: >
  Project-aware memory persistence, triggered by /save. Captures the session into every
  relevant memory layer — the auto-memory note, Obsidian (Hub + Decision Log),
  MemPalace, graphify, and claude-mem (the HANDOFF.md layer is delegated to the /handoff skill,
  its sole writer) — behind a CTDD output gate (reconcile to verified
  truth, mark ASSUMPTIONs, stop and wait for go), then backs up the vault and chains /sync
  to push the code repo. Append-only on Decision Logs; never records an unverified claim as
  fact. Mirrors the OFFLIMITS SAVE_AND_SYNC method + the HQ Second Brain Auto-Sync Protocol.
---

# /save — Persist the session to memory everywhere (project-aware)

Triggered by `/save`. The memory analogue of `/sync`. Mirrors OFFLIMITS `SAVE_AND_SYNC.md`
and the CLAUDE.md "Second Brain Auto-Sync Protocol", hardened with a CTDD output gate.

## Core promise
Nothing recorded as fact unless verified against disk. Nothing written before you approve.
Decision Logs and LESSONS are **append-only** — prior entries are never edited or deleted.

## STEP 0 — Detect context (know WHAT project + WHERE its memory lives)
From the current working directory, determine and REPORT:
- `repo_root = git rev-parse --show-toplevel` (or cwd if not a repo); derive `project` name.
- **Auto-memory note:** `~/.claude/projects/-Users-sunil-rajput/memory/project_<project>*.md` + the `MEMORY.md` index. (The richest running state.)
- **HANDOFF.md** — owned by the `/handoff` skill (its sole writer). `/save` may READ it for context but never writes it; it delegates the handoff layer (see STEP 3).
- **Obsidian vault folder:** `~/Vaults/Jarvis-Brain/JARVIS-BRAIN/Projects/<project>/` — its Hub + Decision Log.
- **MemPalace wing:** `mempalace.yaml` in repo / palace at `~/.mempalace/palace/`.
If any target does NOT exist, say so plainly — do NOT fabricate a vault folder or a note.

## STEP 1 — Reconcile to verified truth (CTDD)
Inventory two sources: (a) everything decided / built / changed this session, and (b) the
actual current state on disk. Verify every claim against the repo/files. Mark anything you
cannot verify as **ASSUMPTION** and list it. Never write an unverified claim as fact.
(This is the lesson behind LESSON: "narrating internals from memory produced fabrications.")

## STEP 2 — OUTPUT GATE (stop and wait)
Show a concise summary of every proposed write:
- Auto-memory note: status + new facts (diff summary).
- HANDOFF.md: (delegated — `/save` does not write it; chain `/handoff save` if a refresh is warranted).
- Obsidian: Hub "Current State" update + the new dated Decision Log entries (append-only).
- Which miners will run: `mempalace mine`, graphify refresh.
- Every ASSUMPTION needing your confirmation.
**WAIT for explicit go.** Write nothing before you respond.

## STEP 3 — Write the knowledge layers (on go)
- **Auto-memory note** — update running state; keep it the richest source. Update the
  `MEMORY.md` index pointer line.
- **HANDOFF.md** — do NOT write it here. `/handoff` is the SOLE writer of the handoff doc. If a
  handoff refresh is warranted this session, chain **`/handoff save`** (it runs its own CTDD reconcile,
  fail-closed secret gate, and output gate). `/save` owns the other memory layers; the handoff layer
  is delegated so there is exactly one writer and no drift.
- **Obsidian** — append new dated, provenance-tagged Decision Log entries; update the Hub
  "Current State". Append-only on logs; Glossary additions only, never redefinitions.
- **claude-mem** — always-on via hooks; no action (note it ran).

## STEP 4 — Run the miners
- **MemPalace:** `mempalace mine <repo_root>` — scope to the project dir. (Known quirk:
  mining from a dir can index a broader set than just the project; verify the wing afterward.)
- **graphify:** in the HQ repo the graph auto-rebuilds on file changes; elsewhere refresh via
  the `/graphify` skill (or `graphify` on the project) and export to the project's vault `Graph/`.

## STEP 5 — Back up
- **Vault git:** commit + push `~/Vaults/Jarvis-Brain` (the `jarvis-brain` private repo):
  `git add <project folder>` → commit "save: <project> <date>" → pull --rebase → push.
- **Code repo:** chain **`/sync`** (full scope chosen) — runs its own CTDD preview gate.

## STEP 6 — Report
State exactly what was written where, what was pushed (code + vault sync status: clean,
ahead/behind 0), and list any ASSUMPTIONs still awaiting your confirmation.

## Hard constraints (always)
- Decision Logs + LESSONS are **append-only**. Never edit or delete a prior entry.
- Never record an unverified claim as fact — mark it ASSUMPTION and surface it.
- No secrets anywhere (environment-variable NAMES only).
- Output gate before any write; reuse `/sync`'s git safety (no force/reset/clean; secret scan).
- If a memory target is missing for this project, report it — never fabricate one.

## Relationship to other skills
- **`/handoff`** owns the per-project `HANDOFF.md` (sole writer). `/save` delegates that layer to it and never writes the handoff doc directly.
- Calls `/sync` as its final code-repo step.
- Mirrors OFFLIMITS `_PROMPTS/SAVE_AND_SYNC.md` and the CLAUDE.md Second Brain Auto-Sync Protocol.
- The Stop hook (`watchdog/hooks/session-end.sh`) does some of this automatically at session
  end; `/save` is the on-command, full, CTDD-gated version for mid-session checkpoints.
