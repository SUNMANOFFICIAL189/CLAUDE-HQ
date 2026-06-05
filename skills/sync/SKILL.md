---
name: sync
description: >
  Project-agnostic safe two-way git sync, triggered by /sync. Detects the current repo +
  branch from the working directory and syncs it with its GitHub remote, both directions,
  behind a CTDD preview-and-confirm gate so nothing is committed, overwritten, or deleted
  by mistake. Never force-pushes, resets --hard, or cleans. When run inside the claude-hq
  repo it also reconciles the ~/.claude live-system symlinks (non-destructive). Mirrors the
  OFFLIMITS sync method (_SCRIPTS/sync.sh + _PROMPTS/SYNC.md), hardened with the CTDD gate.
---

# /sync — Safe two-way git sync (works in ANY project)

Triggered by `/sync`. Mirrors the OFFLIMITS sync method, hardened with a preview gate.

## Core promise
Never lose, overwrite, or delete a file by mistake. Every destructive-capable step is
previewed and waits for explicit go. **Never** `git reset --hard`, `git clean -f`, or
`git push --force`. One repo per run — the one the working directory is in.

## STEP 0 — Detect context (the "intelligence": know exactly WHAT to sync)
From the current working directory, determine and then REPORT to the user before acting:
- `repo_root  = git rev-parse --show-toplevel`  — if this fails → **STOP**: "Not inside a
  git repo. cd into the project you want to sync." Never guess or pick a repo.
- `branch     = git branch --show-current`
- `remote     = git remote get-url origin`  — if none → **STOP** ("no remote to sync to").
- `upstream   = git rev-parse --abbrev-ref @{u}` (may be absent for a brand-new branch)

Report: "Syncing **<repo_root>** on branch **<branch>** → **<remote>**." This is the
"which file/folder/branch" answer, made explicit so you can catch a wrong target before
anything happens.

## STEP 1 — Clear a stale lock (only if safe)
If `.git/index.lock` or `.git/HEAD.lock` exists AND no git process is running
(`pgrep -x git` returns nothing) → remove it and say so. Otherwise leave it and report.

## STEP 2 — CTDD preview (the gate — STOP and wait)
Gather and SHOW, concisely:
- `git status --porcelain` (modified / untracked / **deleted**)
- `git diff --stat` and `git diff --cached --stat`
- **Deletions / renames of tracked files** — list these explicitly; they are the dangerous ones.
- **Secret scan** — scan changed + untracked paths for `credential|\.env$|secret|\.key$|\.pem$`.
  Any hit → STOP, do NOT stage it, tell the user.
- **Unexpected files** — flag backups, `.rtf`, caches, `*.db`, large binaries, `.venv`,
  anything that smells un-committable (the watchdog-clutter class).

Present: "About to commit N files (+a/-b). Deletions: [...]. Untracked to add: [...].
Secrets: none. Proceed? (yes / pick files / abort)." **WAIT for explicit go.** Do not
stage or commit before the user responds.

## STEP 3 — Stage (scoped, never blind)
- Default: stage the reviewed set BY NAME (`git add <paths>`). Use `git add -A` ONLY if the
  user explicitly says "add everything" after seeing the preview.
- Re-run the secret scan on the staged set (`git diff --cached --name-only`); any secret
  name → **ABORT** before committing.

## STEP 4 — Commit
`git commit -m "sync: <YYYY-MM-DD HH:MM>"` (or the user's message).

## STEP 5 — Pull (rebase, never force)
`git pull --rebase`. If it cannot rebase cleanly → **STOP**. Show the exact conflicts and
say: "resolve, then `git rebase --continue`, or `git rebase --abort`." Never `reset --hard`,
never force, never auto-resolve.

## STEP 6 — Push
- Upstream exists → `git push`.
- No upstream (new branch) → confirm with the user first (pushing a new branch is
  outward-facing), then `git push -u origin <branch>`.

## STEP 7 — Verify
Report `git status` (must be clean) + ahead/behind (both must be 0). If not in sync → STOP
and state exactly what is out of sync.

## STEP 8 — claude-hq ONLY: reconcile live-system symlinks (non-destructive)
If `repo_root` is the claude-hq repo:
- For each `~/claude-hq/skills/*`, ensure `~/.claude/skills/<name>` is a symlink to it;
  create it if missing. If a NON-symlink (real dir/file) already sits at the target →
  report the conflict, do NOT touch it.
- Report orphans: skills in `~/.claude/skills/` that are NOT symlinks into the repo (e.g.
  `ctdd-precheck`) so they can be versioned later. **Do NOT delete them.**

## Hard constraints (always)
- Never `git reset --hard`, `git clean -f`, or `git push --force[-with-lease]`.
- Never delete a tracked or untracked file without showing it in the preview + explicit go.
- Never commit a file matching the secret patterns.
- Never `git add -A` unless the user okays it after the preview.
- One repo per run — the repo the cwd is in. Never sync a repo the user isn't in.

## Relationship to other skills
- Mirrors OFFLIMITS `_SCRIPTS/sync.sh` + `_PROMPTS/SYNC.md`, hardened with the CTDD gate.
- End-of-session memory capture across Obsidian / graphify / MemPalace / claude-mem is the
  separate `/save` skill (it calls `/sync` as its final step).
