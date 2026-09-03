# GATE 0 — Focused re-review of PLAN v2 security tickets (2026-09-03)
Independence: fresh-agent only (Codex unavailable — local CLI ENOENT). One Opus reviewer, 15 reads, 178,803 tokens.
**Verdict: FIX-THEN-PROCEED.** All findings verified by the foreman and folded into PLAN v2.1 (same file, change log at top). Foreman notes are marked ▸.

## A. Prior findings — closure table

| Finding | Verdict | What's missing (if any) | Ticket |
|---|---|---|---|
| C1 fence keys asserted not measured | **PARTIAL** | The unknown-key detector is `$HERMES --help \| grep -ci unknown` → `--help` never loads `config.yaml`, so it cannot detect a mistyped fence key. `approvals.mode` (default `smart`, scout D §3) is never set. | T8, T6(h), T11 |
| C2 Groq egress / no sandbox | **PARTIAL** | Container is in, but the "host allow-list proxy" binds only the host-side Hermes process — it cannot see container egress (see 🔴N1). T6(c) may return "no per-container network", and the stated fallback is factually wrong. | T4/T6(c)/T9/T11 P11 |
| C3 `WRITE_SAFE_ROOT` doesn't bound `terminal` | **CLOSED** | Container + integrity manifest + P1b (`echo>`, `cp`, `git -C $HQ`, `ln -sf`) is a real consequence measurement. Manifest omits `~/.ssh`, `~/.gitconfig`, `~/.local/bin` — cheap to add. | T9, T11 P1b, T12(10) |
| C4 Keychain read unprovable | **PARTIAL** | Strip + census is sound and is the real control. The dynamic proofs are weaker than claimed (🟠N5): `log show` without `--info --debug` persists nothing for a keychain read, no positive control, and test A' is tautological once the provider plugin is gone. | T3, T10 |
| C5 kill rule movable | **PARTIAL** | Pre-registration is real, but two freedoms remain: which attempt's tokens count after a VOID+retry, and how a median of 3 behaves when one job is INCONCLUSIVE (🟡N11). | §1.4–1.5, T13 |
| H1 caller-supplied fences | **CLOSED** | Workdir under `$PR/`, toolset allow-list, hard caps — T12(1). | T12 |
| H2 vacuous guard acceptance | **CLOSED** | Forwarded param + positive control both specified. | T12(1), T14 |
| H3 T2/T3 acceptance unsatisfiable | **CLOSED** | Explicit `magika` + `secret-scan.sh`, override-line criterion dropped. | T2 |
| H4 `uv`/`brew` ungated bytes | **PARTIAL** | `.venv` scan is right. `magika $(which colima)` is a file-type check on one binary; brew's closure (lima, vz/qemu deps) is unscanned. Honest control is "Homebrew-core formula" — say that instead of implying a scan. | T2, T4, T5 |
| H5 32k fallback | **CLOSED** | §1.7 states no fallback; T6 precedes T7. | §1.7, T6, T7 |
| H6 J1 inputs unpinned / `$SK` leaks | **CLOSED for J1, REOPENED via J2** | `inputs.txt` frozen + `$SK` excluded — but J2's worktree of `$HQ` re-admits `$SK` wholesale (🟠N7). | T17, T19 |
| H7 verifier backstop | **CLOSED** | §1.11 commit-on-branch + clean-status check. Undermined in practice by a dirty tree (🟠N9). | §1.11 |
| H8 early doctrine edits | **CLOSED** | All doctrine deferred to T22; T13 writes only BACKLOG. | T13, T22 |
| H9 `--resume` / Paperclip | **CLOSED** | T19 dropped; wrapper rejects `--resume`; P14 probes it. | §1.8, T12(1), T11 |
| H10 quota omits foreman | **CLOSED** | 2.6–4.4M incl. ~1.0M boot; T1/T7 on haiku; waves merged. | §7 |

## B. New holes

### 🔴 CRITICAL

**N1 — The proxy cannot see container egress; the compensating control for C2 does not exist as written.** — §1.2, T9(1), T11 P11, T12(5), risk row 3 — `hermes-proxy.py` listens on host `127.0.0.1:<port>` and is bound to the Hermes process by `HTTPS_PROXY` (T12(6)). The terminal now runs in a container on a Colima VM. Inside the container `127.0.0.1` is the container itself, so a proxy-honouring client gets connection-refused and a non-honouring client (or raw sockets, or `aiohttp`, which ignores proxy env unless `trust_env=True`) egresses via VM NAT — **unlogged**. P11's stated fallback, "if VM NAT is the residual, the attempt is LOGGED by the proxy", is false. Honest residual for a Groq-hosted model with a shell in that container: (a) the entire bind-mounted workdir — for J2 that is a full checkout of the HQ repo; (b) whatever Hermes injects into the container env (unknown until T6(c) — possibly `GROQ_API_KEY`); (c) **host loopback services via `host.docker.internal`** if Colima maps it (Paperclip :3100, Ollama :11434, dashboards). "No client IP in inputs" is true for J1/J3 and **false for J2**. *Fix:* T6(c) must test a real `docker network create --internal` + whether Hermes accepts a network name; T11 must probe `curl 1.1.1.1` and `curl host.docker.internal:3100` from inside the container and record the answers as evidence, not assumption; and drop `--worktree` for J2, which shrinks the mount to 26 scripts.
▸ Foreman fix adopted in v2.1: **VM-level egress kill** — the engine script inserts `iptables -I DOCKER-USER -j DROP` inside the Colima VM after every start (all container traffic, including `host.docker.internal`, is dropped; Hermes-independent), T6(c) additionally checks for a per-container network option, T11 P11 measures `curl 1.1.1.1` and `curl host.docker.internal:{3100,11434}` from inside the container (all must fail). The host proxy governs only the Hermes process, which is the only thing that needs egress.

**N2 — J1's Hermes arms cannot read their own inputs.** — T17 J1 vs T12(1) + T11 P1b — `inputs.txt` is a realpath list under `$HQ/skills` and `~/.claude/skills`; the wrapper refuses any workdir not under `$PR/` and the container bind-mounts only that workdir; P1b exists precisely to prove those host paths are unreachable. So J1-B/J1-C — the *pre-registered primary comparison* (§1.4) — have no way to open the ~40–60 SKILL.md files. *Fix:* T17 stages J1 by copying the resolved files into `$PR/jobs/J1/<arm>/wd/inputs/` (identical bytes for every arm, sha256-manifested) and rewrites `inputs.txt` to workdir-relative paths.
▸ Adopted.

### 🟠 HIGH

**N3 — T3's strip acceptance cannot detect the break it is most likely to cause.** — `$HERMES --help` → 0 parses argv and never touches the provider registry. *Fix:* T3's acceptance = a config/provider-loading invocation plus one real `-z "ping"` against Ollama once T7/T8 land, re-run as a gate before T10. ▸ Adopted (T3 + "T3b smoke" at the start of T10).

**N4 — the C1 fix is vacuous.** — `--help` does not load `config.yaml`. *Fix:* capture stderr from a config-loading invocation and diff the key set in `config.yaml` against T6's mapped-key list mechanically. ▸ Adopted (`hermes doctor` + `config-keys.py`).

**N5 — the Keychain proof's dynamic half is unfalsifiable as specified.** — (i) `log show` without `--info --debug` shows only persisted messages; (ii) no positive control; (iii) post-T3, test A dies at provider lookup, so A' returns "identical result" trivially. *Fix:* add `--info --debug`; positive control (the secrets helper's legitimate read of `claude-hermes-groq` must appear); state that **T3 + the census are the control, the dynamic tests are corroboration** — invert §1.3/T10's framing. ▸ Adopted.

**N6 — J2's corpus is 15 files, below the pilot's own hand-off gate.** — 26 `.sh` under `scripts/`, 15 after exclusions; SKILL.md's gate is "≥30 files or ≥20 uniform items". *Fix:* widen to repo-wide tracked `.sh` (37, ~30 after exclusions) and count SC findings as the unit; freeze before T18. ▸ Adopted.

**N7 — J2's worktree un-blinds both arms and breaks git inside the container.** — A worktree from `hermes-pilot` checks out `$SK/**` (plan, board with the kill rule, gold files); a worktree's `.git` is a file with an absolute `gitdir:` path outside the bind-mount, so git fails inside the container while arm A has full git. *Fix:* drop `--worktree`; copy `scripts/**` into the job workdir; grade by diff against the frozen copy. ▸ Adopted — `--worktree` removed from the wrapper entirely.

**N8 — the job branch names cannot exist.** — `hermes-pilot` (a ref file) vs `hermes-pilot/<job>-<arm>` (needs a directory) — git refuses. ▸ Moot after N7 (no job branches).

**N9 — the tree is dirty now, so T1's branch and §1.11's commits will sweep unrelated work.** — 15 entries in `git status --porcelain` incl. today's doctrine edits; `git switch -c` carries all of it. *Fix:* T1 records the dirty set and either stashes or fails; pathspec-only commits; T13's baseline cites the recorded set. ▸ Adopted with a stronger shape: **the pilot branch lives in its own worktree `$PT=$HQ/run/pilot-tree`** created from `main` HEAD (committed state only); the main tree stays on `main` for every other session (also closes N19); pilot commits use explicit pathspecs only.

### 🟡 MEDIUM
- **N10** — second model-selection surfaces unmapped (vision aux router native-Anthropic; `approvals.mode: smart` aux-LLM triage; curator aux model). ▸ T6 enumerates `auxiliary.*`/aux-router keys; T8 pins `approvals.mode: manual`, aux routers → custom or off, curator off.
- **N11** — kill-rule residual freedom (VOID accounting; INCONCLUSIVE in a median of 3). ▸ Pre-registered: sum all attempts' tokens; an INCONCLUSIVE job contributes 0% saving.
- **N12** — ledger: `journal_mode=delete`; `INSERT OR IGNORE` swallows every constraint failure. ▸ `ON CONFLICT(session_id) DO NOTHING` + `changes()` check that fails loudly; `busy_timeout` + retries; journal mode left alone (owned by model-router.py).
- **N13** — P10 measures model cooperation, not the container env. ▸ `docker inspect --format '{{json .Config.Env}}'` on the live container during a run (T11), T6(c) enumerates what Hermes injects.
- **N14** — T7 RSS recipe unspecified (Ollama runner child process); no action when both models miss. ▸ Recipe pre-registered (sum all `ollama*` RSS + VM memory); BLOCKED to the foreman, never a substitute model.
- **N15** — S7 T12 ∥ T13 not disjoint on state (baseline snapshot vs mutating tree). ▸ T13 first, then T12.
- **N16** — GATE C ordering (landing before T22's doctrine write-backs). ▸ Order fixed: T21 → operator go → T22 → GATE C landing → T23 if DROP.
- **N17** — test C still absence-of-noise. ▸ Positive control (one deliberate egress must appear as 403) + `lsof -i -p` sampling; `NO_PROXY` loopback note recorded.
- **N18** — P8 threshold mis-stated (first-match-wins IS grounded: scout D §3). ▸ Expected delta = `min(len(CLAUDE.md), 20k chars) − len(.hermes.md)` in tokens, paired with the behavioural canary.
- **N19** — the pilot would own `$HQ`'s only working tree for 14 days. ▸ Closed by the pilot worktree (N9).

### 🟢 LOW
`security lock-keychain` can break Claude Code's own OAuth refresh — trap-unlock, window <60 s (▸ adopted). · T5 must source T3's NEEDS_CONTEXT from the board, not the worker's report (▸ adopted). · T13's `grep -c "Pre-registered"` is a read-back (▸ replaced by a hash match of the kill-rule text against §1.4–1.5). · Shim dir stays strictly inside `env -i` (▸ adopted).

**Doctrine/rails check (reviewer):** Lesson 17 honoured; 24 honoured; 32 honoured except N16; 33 honoured; **34 violated at N3, N4 and one LOW** (▸ all fixed). Foreman rails: no worker spawns workers; every implementation ticket has a WRITE SET; Opus is the ceiling; no Fable.

## C. What's solid (reviewer, verified)
Container-for-all-arms + sha256 integrity manifest with FAIL+HALT is a real fix for C3 and the right answer to "the OS is the only boundary"; P1b measures a consequence. Stripping the impersonating provider plugins is the correct primary control for C4 and is reproducible (`hq-hardened` branch). T6 as a schema-reading ticket before any config or model work, with `file:function` on every claim and explicit UNKNOWNs, is the single best structural change in v2. Frozen realpath'd inputs with `$SK` excluded, dual-metric verdicts that must agree, rerun-both-arms with the mean, VOID≠FAIL, anonymised grading — a stronger measurement protocol than the first review asked for. Wrapper guard tests with a positive control, `env -i` with no `ANTHROPIC_*`/`CLAUDE_*`, absolute `$HERMES`, `.env` = 0 bytes, read-only copy of HQ skills all land their prior findings. §1.9's honest cost note and §8 survive intact.

## Verdict: FIX-THEN-PROCEED → applied as PLAN v2.1 (2026-09-03). Next review = GATE A (`/ctdd-precheck` + `/proof-check`) after T11.
