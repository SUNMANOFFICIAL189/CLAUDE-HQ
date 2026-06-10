#!/usr/bin/env python3
"""
Incremental secret scrubber — v2 (wired into ~/.claude/hooks/session-end.sh).

Processes only content NEW since the last run (watermarked), so it finishes well
under a SessionEnd budget instead of re-scanning ~750 MB every exit.

Stores scrubbed:
  1. CC transcripts   — ~/.claude/projects/**/*.jsonl (the REAL location) + legacy
                        ~/Library/.../claude-code-sessions/*.json
  2. claude-mem.db    — observations / user_prompts / session_summaries
                        (UPDATE rows id>watermark; FTS auto-syncs via triggers)
  3. mempalace chroma — DETECT only (rowid>watermark), log for manual review
  4. Obsidian vault   — HALT push (sentinel) if a secret is in any file not yet
                        on origin/main (the exact set `git add -A && push` ships)

FAIL-CLOSED design (2026-06-10 adversarial review): the push gate is the
`.scrub-halt` sentinel. session-end.sh RAISES it before calling this scrubber;
this scrubber LOWERS it only on a fully-clean, fully-successful pass. So a crash,
kill, missing interpreter, exception, or a dirty vault all leave the gate UP and
the vault push is held — the guard defaults to BLOCK, never to ALLOW.

First run (no state file) = full scrub, then records watermarks. Env overrides
keep it isolated-testable.
"""
import json, os, re, sqlite3, subprocess, sys, time

HOME = os.path.expanduser("~")
CLAUDE_MEM_DB   = os.environ.get("CLAUDE_MEM_DB",   f"{HOME}/.claude-mem/claude-mem.db")
MEMPALACE_DB    = os.environ.get("MEMPALACE_DB",    f"{HOME}/.mempalace/palace/chroma.sqlite3")
VAULT_ROOT      = os.environ.get("VAULT_ROOT",      f"{HOME}/Vaults/Jarvis-Brain")
CC_PROJECTS     = os.environ.get("CC_PROJECTS_ROOT",f"{HOME}/.claude/projects")
CC_SESSIONS     = os.environ.get("CC_SESSIONS_ROOT",f"{HOME}/Library/Application Support/Claude/claude-code-sessions")
SCRUB_STATE     = os.environ.get("SCRUB_STATE",     f"{HOME}/claude-hq/run/scrub-state.json")
SCRUB_LOG       = os.environ.get("SCRUB_LOG",       f"{HOME}/claude-hq/scripts/.secret-scrub.log")
MAX_SCAN_BYTES  = int(os.environ.get("SCRUB_MAX_FILE_BYTES", str(25 * 1024 * 1024)))  # skip >25MB blobs

# Single source of truth — detection (vault HALT) == enforcement (redaction).
# Adding a pattern here protects BOTH the redactor and the push gate; they can't drift.
PATTERNS = [
    ("anthropic",    r"sk-ant-[A-Za-z0-9_-]{12,}"),
    ("openai",       r"sk-[A-Za-z0-9]{20,}"),
    ("github_pat",   r"ghp_[A-Za-z0-9]{15,}"),
    ("github_oauth", r"gho_[A-Za-z0-9]{15,}"),
    ("google_api",   r"AIza[A-Za-z0-9_-]{15,}"),
    ("aws_access",   r"AKIA[0-9A-Z]{16}"),
    ("slack",        r"xox[baprs]-[0-9a-zA-Z-]{10,}"),
    ("stripe",       r"[sr]k_live_[A-Za-z0-9]{20,}"),         # Stripe secret/restricted live keys
    ("jwt",          r"eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{6,}"),  # JWT (header.payload.sig)
    ("reddit_sec",   r"I3WI6Wmz_u-lAUjBuA[A-Za-z0-9_-]*"),   # pinned burned literal (no general reddit shape)
    ("private_key",  r"-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----[\s\S]*?-----END [A-Z0-9 ]*PRIVATE KEY-----"),
    ("private_key_open", r"-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----"),  # lone header (truncated paste) → still HALT
]
REDACT   = [(name, re.compile(p)) for name, p in PATTERNS]
VAULT_RX = re.compile("|".join(f"(?:{p})" for _, p in PATTERNS))   # == enforcement, by construction

def log(msg):
    os.makedirs(os.path.dirname(SCRUB_LOG), exist_ok=True)
    with open(SCRUB_LOG, "a") as f:
        f.write(f"[{time.strftime('%F %T')}] {msg}\n")

def load_state():
    try:
        return json.load(open(SCRUB_STATE))
    except Exception:
        return {}

def save_state(st):
    os.makedirs(os.path.dirname(SCRUB_STATE), exist_ok=True)
    tmp = SCRUB_STATE + ".tmp"
    json.dump(st, open(tmp, "w"), indent=2)
    os.replace(tmp, SCRUB_STATE)   # atomic

def redact(s):
    for name, rx in REDACT:
        s = rx.sub(f"[REDACTED:{name}]", s)
    return s

def _atomic_write(fp, text):
    tmp = fp + ".scrubtmp"
    with open(tmp, "w", encoding="utf-8") as f:
        f.write(text)
    os.replace(tmp, fp)   # atomic — never leaves a truncated file on crash (M3)

# ---- 1. transcripts (incremental by mtime; atomic; deferred-aware) ---------
def scrub_transcripts(st):
    since = float(st.get("transcripts_mtime", 0))
    # Defer files modified within the last N seconds — may be actively written.
    cutoff = time.time() - float(os.environ.get("SCRUB_SKIP_RECENT_SEC", "120"))
    newest = since
    min_deferred = None    # never let the watermark jump past a deferred file (M2)
    touched = 0
    for root, ext in [(CC_PROJECTS, ".jsonl"), (CC_SESSIONS, ".json")]:
        if not os.path.isdir(root):
            continue
        for dp, _, fns in os.walk(root):
            for fn in fns:
                if not fn.endswith(ext):
                    continue
                fp = os.path.join(dp, fn)
                try:
                    mt = os.path.getmtime(fp)
                except OSError:
                    continue
                if mt <= since:
                    continue
                if mt > cutoff:                       # actively-written → defer
                    min_deferred = mt if min_deferred is None else min(min_deferred, mt)
                    continue
                try:
                    body = open(fp, "r", encoding="utf-8", errors="replace").read()
                except OSError:
                    continue                          # unreadable → don't advance past it; retry next run
                new = redact(body)
                if new != body:
                    _atomic_write(fp, new)
                    touched += 1
                newest = max(newest, mt)              # advance ONLY after a successful scan
    wm_new = newest
    if min_deferred is not None:                      # cap below the oldest deferred file
        wm_new = min(wm_new, min_deferred - 0.001)
    st["transcripts_mtime"] = wm_new
    log(f"transcripts(incr): scrubbed {touched} (since {since:.0f}, deferred_min={min_deferred})")
    return touched

# ---- 2. claude-mem (incremental by id; commit-THEN-watermark) -------------
def scrub_claude_mem(st):
    if not os.path.isfile(CLAUDE_MEM_DB):
        log("claude-mem: db missing"); return 0
    targets = [
        ("observations",      ["text","facts","narrative","title","subtitle","concepts"]),
        ("user_prompts",      ["prompt_text"]),
        ("session_summaries", ["request","investigated","learned","completed","next_steps"]),
    ]
    wm = st.setdefault("claude_mem", {})
    conn = sqlite3.connect(CLAUDE_MEM_DB, timeout=10)
    conn.execute("PRAGMA busy_timeout=10000")
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()
    total = 0; failed = []
    for table, cols in targets:
        last = int(wm.get(table, -1))
        try:
            cur.execute(f"SELECT id,{','.join(cols)} FROM {table} WHERE id > ? ORDER BY id", (last,))
            rows = cur.fetchall()
        except sqlite3.Error as e:
            log(f"claude-mem read FAIL {table}: {e}"); failed.append(table); continue
        maxid = last; tbl = 0
        try:
            for row in rows:
                maxid = max(maxid, row["id"])
                updates = {}
                for c in cols:
                    v = row[c]
                    if v is None:
                        continue
                    nv = redact(v)
                    if nv != v:
                        updates[c] = nv
                if updates:
                    setc = ", ".join(f"{c}=?" for c in updates)
                    cur.execute(f"UPDATE {table} SET {setc} WHERE id=?", list(updates.values()) + [row["id"]])
                    tbl += 1
                    log(f"claude-mem redacted {table}#{row['id']} cols={list(updates)}")   # audit trail (M1)
            conn.commit()                              # commit FIRST...
        except sqlite3.Error as e:
            conn.rollback()
            log(f"claude-mem commit FAIL {table}: {e} — watermark NOT advanced, will re-scan")
            failed.append(table); continue            # ...do NOT advance watermark on failure (H1)
        wm[table] = maxid                              # ...advance ONLY after successful commit
        total += tbl
    conn.close()
    log(f"claude-mem(incr): {total} rows redacted; failed_tables={failed}")
    if failed:
        raise RuntimeError(f"claude-mem tables failed: {failed}")   # surface, don't silently 'clean' (H2)
    return total

# ---- 3. mempalace (DETECT only, incremental by rowid) ---------------------
def scrub_mempalace(st):
    if not os.path.isfile(MEMPALACE_DB):
        log("mempalace: db missing"); return 0
    last = int(st.get("mempalace_rowid", -1))
    conn = sqlite3.connect(MEMPALACE_DB, timeout=10)
    conn.execute("PRAGMA busy_timeout=10000")          # L1
    cur = conn.cursor()
    try:
        cur.execute("SELECT rowid,string_value FROM embedding_fulltext_search WHERE rowid > ? ORDER BY rowid", (last,))
        rows = cur.fetchall()
    except sqlite3.Error as e:
        log(f"mempalace skip: {e}"); conn.close(); return 0   # no advance → re-scan next run
    hits = []; maxr = last
    for rid, val in rows:
        maxr = max(maxr, rid)
        if val and VAULT_RX.search(val):
            hits.append((rid, (val or "")[:80]))
    if hits:
        with open(SCRUB_LOG, "a") as f:
            f.write(f"\n[mempalace] DETECTED {len(hits)} NEW row(s) — manual review:\n")
            for rid, pv in hits[:20]:
                f.write(f"  rowid={rid} preview={pv!r}\n")
    st["mempalace_rowid"] = maxr
    conn.close()
    log(f"mempalace(incr): {len(hits)} new suspicious rows")
    return len(hits)

# ---- 4. vault: DETECT every file the push will ship (C4); main owns sentinel
def _git(args):
    return subprocess.run(["git","-C",VAULT_ROOT]+args, capture_output=True, text=True)

def _decode_scannable(raw):
    """Return scannable text, or None for a genuine binary. UTF-16 (BOM) text would
    look 'binary' to a null-byte heuristic, so decode it explicitly (MED-3)."""
    if raw[:2] in (b"\xff\xfe", b"\xfe\xff"):
        try: return raw.decode("utf-16")
        except Exception: return None        # malformed UTF-16 → genuine binary
    if b"\x00" in raw[:8192]:
        return None                          # genuine binary (image/blob) → skip
    return raw.decode("utf-8", errors="replace")

def scrub_vault():
    """Return (clean: bool, checked: int). Raises on unexpected error → main fails closed."""
    if not os.path.isdir(os.path.join(VAULT_ROOT, ".git")):
        log("vault: not a git repo"); return True, 0
    files = set()
    has_origin = _git(["rev-parse","--verify","origin/main"]).returncode == 0
    if has_origin:
        files.update(x for x in _git(["diff","--name-only","origin/main"]).stdout.splitlines() if x.strip())
    else:
        files.update(_git(["ls-files"]).stdout.splitlines())     # no upstream → full tracked scan
    files.update(x for x in _git(["ls-files","--others","--exclude-standard"]).stdout.splitlines() if x.strip())
    files.discard(".scrub-halt")
    found = []
    for rel in files:
        fp = os.path.join(VAULT_ROOT, rel)
        if not os.path.isfile(fp):
            continue
        try:
            size = os.path.getsize(fp)
        except OSError:
            found.append(rel); continue        # can't stat an in-scope file → FAIL CLOSED
        if size > MAX_SCAN_BYTES:
            found.append(rel); continue        # too big to scan → FAIL CLOSED (MED-3, was clean-skip)
        try:
            raw = open(fp, "rb").read()
        except OSError:
            found.append(rel); continue        # unreadable in-scope file → FAIL CLOSED
        text = _decode_scannable(raw)
        if text is None:
            continue                           # genuine binary → not a text secret carrier
        if VAULT_RX.search(text):
            found.append(rel)
    if found:
        log("vault: HALT — secret-shaped strings detected in:")
        for f in found:
            log(f"  {f}")
        return False, len(files)
    log(f"vault(incr): clean ({len(files)} unpushed files checked)")
    return True, len(files)

def main():
    t0 = time.time()
    st = load_state()
    first = not st
    halt = os.path.join(VAULT_ROOT, ".scrub-halt")
    vault_is_git = os.path.isdir(os.path.join(VAULT_ROOT, ".git"))
    # FAIL CLOSED: raise the gate before doing anything. Only a clean+complete pass lowers it.
    if vault_is_git:
        try: _atomic_write(halt, "scrub-in-progress\n")
        except OSError: pass
    log(f"=== scrub_incremental start ({'FULL first-run' if first else 'incremental'}) ===")
    timings = {}; stage_ok = {}
    for name, fn in [("transcripts",scrub_transcripts),("claude_mem",scrub_claude_mem),("mempalace",scrub_mempalace)]:
        s = time.time()
        try:
            fn(st); stage_ok[name] = True
        except Exception as e:
            log(f"{name} ERROR: {e}"); stage_ok[name] = False
        timings[name] = time.time() - s
    s = time.time()
    try:
        vault_clean, _ = scrub_vault(); stage_ok["vault"] = True
    except Exception as e:
        log(f"vault ERROR: {e}"); vault_clean = False; stage_ok["vault"] = False   # FAIL CLOSED
    timings["vault"] = time.time() - s
    save_state(st)                                  # only committed/successful watermarks are in st
    all_ok = all(stage_ok.values())
    # The push gate reflects the VAULT specifically: lower it only if the vault is
    # proven clean AND the vault stage itself succeeded. (A claude-mem failure
    # surfaces via exit code but does NOT block a clean vault backup.)
    push_safe = bool(vault_clean and stage_ok.get("vault"))
    if vault_is_git:
        try:
            if push_safe: os.remove(halt)
            else: _atomic_write(halt, "scrub-halt\n")
        except OSError: pass
    dt = time.time() - t0
    log(f"=== scrub_incremental end ({dt:.2f}s) push_safe={push_safe} stages_ok={stage_ok} ===")
    print(json.dumps({"first_run":first, "push_safe":push_safe, "vault_clean":vault_clean,
                      "stages_ok":stage_ok, "total_s":round(dt,3),
                      "stage_s":{k:round(v,3) for k,v in timings.items()}}))
    sys.exit(0 if (push_safe and all_ok) else 1)

if __name__ == "__main__":
    main()
