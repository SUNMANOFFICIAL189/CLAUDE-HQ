#!/usr/bin/env python3
"""
Incremental secret scrubber — PROTOTYPE (not yet wired into session-end.sh).

Drop-in replacement for ~/claude-hq/scripts/lib/secret-scrub.sh, but processes
only content NEW since the last run (watermarked), so it finishes in well under
a SessionEnd timeout instead of re-scanning ~750 MB every exit.

Stores scrubbed:
  1. CC transcripts   — ~/.claude/projects/**/*.jsonl  (THE REAL location; the
                        old bash version only scanned the legacy Library dir)
                        + legacy ~/Library/.../claude-code-sessions/*.json
  2. claude-mem.db    — observations / user_prompts / session_summaries
                        (UPDATE rows id>watermark; FTS auto-syncs via triggers)
  3. mempalace chroma — DETECT only (rowid>watermark), log for manual review
  4. Obsidian vault   — HALT push (sentinel) if a secret is in any file not yet
                        on origin/main (the exact set about to be pushed)

First run (no state file) = full scrub of everything, then records watermarks.
Every run after = only the delta. Same patterns + same [REDACTED:x] format as
the original. Env overrides (used by the test harness) keep it isolated-testable.
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

# Redaction patterns — kept in lockstep with secret-scrub.sh (lowered mins to
# catch pasted prefixes; reddit pinned to the one burned literal).
REDACT = [
    ("anthropic",    re.compile(r"sk-ant-[A-Za-z0-9_-]{12,}")),
    ("openai",       re.compile(r"sk-[A-Za-z0-9]{20,}")),
    ("github_pat",   re.compile(r"ghp_[A-Za-z0-9]{15,}")),
    ("github_oauth", re.compile(r"gho_[A-Za-z0-9]{15,}")),
    ("google_api",   re.compile(r"AIza[A-Za-z0-9_-]{15,}")),
    ("aws_access",   re.compile(r"AKIA[0-9A-Z]{16}")),
    ("slack",        re.compile(r"xox[baprs]-[0-9a-zA-Z-]{10,}")),
    ("reddit_sec",   re.compile(r"I3WI6Wmz_u-lAUjBuA[A-Za-z0-9_-]*")),
]
# Vault HALT detection = hard prefixes only (mirrors scrub_vault grep:257).
VAULT_RX = re.compile(r"sk-ant-[A-Za-z0-9_-]{12,}|ghp_[A-Za-z0-9]{15,}|AIza[A-Za-z0-9_-]{15,}|AKIA[0-9A-Z]{16}|xox[baprs]-[0-9a-zA-Z-]{10,}|I3WI6Wmz_u-lAUjBuA")
VAULT_EXT = (".md", ".txt", ".json", ".yaml", ".yml", ".canvas")

def log(msg):
    os.makedirs(os.path.dirname(SCRUB_LOG), exist_ok=True)
    with open(SCRUB_LOG, "a") as f:
        f.write(f"[{time.strftime('%F %T')}] {msg}\n")

def load_state():
    try:
        return json.load(open(SCRUB_STATE))
    except Exception:
        return {}   # no state => first run => full scrub

def save_state(st):
    os.makedirs(os.path.dirname(SCRUB_STATE), exist_ok=True)
    tmp = SCRUB_STATE + ".tmp"
    json.dump(st, open(tmp, "w"), indent=2)
    os.replace(tmp, SCRUB_STATE)   # atomic

def redact(s):
    for name, rx in REDACT:
        s = rx.sub(f"[REDACTED:{name}]", s)
    return s

# ---- 1. transcripts (incremental by mtime) --------------------------------
def scrub_transcripts(st):
    since = float(st.get("transcripts_mtime", 0))
    # Skip files modified within the last N seconds — they may be actively
    # written (this/other live sessions). They get caught on a later run once
    # quiescent. Prevents read-redact-write racing a live append (data loss).
    cutoff = time.time() - float(os.environ.get("SCRUB_SKIP_RECENT_SEC", "120"))
    newest = since
    touched = 0
    roots = [(CC_PROJECTS, ".jsonl"), (CC_SESSIONS, ".json")]
    for root, ext in roots:
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
                if mt > cutoff:          # actively-written → defer to a later run
                    continue
                newest = max(newest, mt)
                try:
                    body = open(fp, "r", encoding="utf-8", errors="replace").read()
                except OSError:
                    continue
                new = redact(body)
                if new != body:
                    open(fp, "w", encoding="utf-8").write(new)
                    touched += 1
    st["transcripts_mtime"] = newest
    log(f"transcripts(incr): scrubbed {touched} (since mtime {since:.0f})")
    return touched

# ---- 2. claude-mem (incremental by id; FTS auto-syncs via triggers) -------
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
    conn.execute("PRAGMA busy_timeout=10000")   # wait out concurrent claude-mem writes
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()
    total = 0
    for table, cols in targets:
        last = int(wm.get(table, -1))
        try:
            cur.execute(f"SELECT id,{','.join(cols)} FROM {table} WHERE id > ? ORDER BY id", (last,))
            rows = cur.fetchall()
        except sqlite3.OperationalError as e:
            log(f"claude-mem skip {table}: {e}"); continue
        maxid = last
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
                cur.execute(f"UPDATE {table} SET {setc} WHERE id=?",
                            list(updates.values()) + [row["id"]])
                total += 1
        wm[table] = maxid   # advance watermark to highest id seen (scrubbed or not)
    conn.commit(); conn.close()
    log(f"claude-mem(incr): {total} rows redacted")
    return total

# ---- 3. mempalace (DETECT only, incremental by rowid) ---------------------
def scrub_mempalace(st):
    if not os.path.isfile(MEMPALACE_DB):
        log("mempalace: db missing"); return 0
    last = int(st.get("mempalace_rowid", -1))
    conn = sqlite3.connect(MEMPALACE_DB); cur = conn.cursor()
    try:
        cur.execute("SELECT rowid,string_value FROM embedding_fulltext_search WHERE rowid > ? ORDER BY rowid", (last,))
        rows = cur.fetchall()
    except sqlite3.OperationalError as e:
        log(f"mempalace skip: {e}"); conn.close(); return 0
    hits = []; maxr = last
    for rid, val in rows:
        maxr = max(maxr, rid)
        if val and any(rx.search(val) for _, rx in REDACT):
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

# ---- 4. vault (HALT if a secret is in anything not yet on origin/main) ----
def _git(args):
    return subprocess.run(["git","-C",VAULT_ROOT]+args, capture_output=True, text=True)

def scrub_vault():
    if not os.path.isdir(os.path.join(VAULT_ROOT, ".git")):
        log("vault: not a git repo"); return True
    files = set()
    # committed-but-unpushed (tracked) — compare to origin/main if it exists
    has_origin = _git(["rev-parse","--verify","origin/main"]).returncode == 0
    if has_origin:
        d = _git(["diff","--name-only","origin/main"])
        files.update(x for x in d.stdout.splitlines() if x.strip())
    else:
        # no upstream ref -> full scan (first push / fresh clone)
        d = _git(["ls-files"]); files.update(d.stdout.splitlines())
    # untracked
    u = _git(["ls-files","--others","--exclude-standard"])
    files.update(x for x in u.stdout.splitlines() if x.strip())
    found = []
    for rel in files:
        if not rel.endswith(VAULT_EXT):
            continue
        fp = os.path.join(VAULT_ROOT, rel)
        try:
            if VAULT_RX.search(open(fp, "r", encoding="utf-8", errors="replace").read()):
                found.append(fp)
        except OSError:
            continue
    halt = os.path.join(VAULT_ROOT, ".scrub-halt")
    if found:
        log("vault: HALT — secret-shaped strings detected in:")
        for f in found:
            log(f"  {f}")
        open(halt, "w").write("scrub-halt\n")
        return False
    if os.path.exists(halt):
        os.remove(halt)
    log(f"vault(incr): clean ({len(files)} unpushed files checked)")
    return True

def main():
    t0 = time.time()
    st = load_state()
    first = not st
    log(f"=== scrub_incremental start ({'FULL first-run' if first else 'incremental'}) ===")
    timings = {}
    for name, fn in [("transcripts",scrub_transcripts),("claude_mem",scrub_claude_mem),("mempalace",scrub_mempalace)]:
        s = time.time();
        try: fn(st)
        except Exception as e: log(f"{name} ERROR: {e}")
        timings[name] = time.time()-s
    s = time.time()
    try: clean = scrub_vault()
    except Exception as e: log(f"vault ERROR: {e}"); clean = True
    timings["vault"] = time.time()-s
    save_state(st)
    dt = time.time()-t0
    log(f"=== scrub_incremental end ({dt:.2f}s) ===")
    print(json.dumps({"first_run":first,"clean":clean,"total_s":round(dt,3),
                      "stage_s":{k:round(v,3) for k,v in timings.items()}}))
    sys.exit(0 if clean else 1)

if __name__ == "__main__":
    main()
