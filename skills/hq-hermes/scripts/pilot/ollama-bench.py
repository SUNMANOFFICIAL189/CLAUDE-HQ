#!/usr/bin/env python3
# ollama-bench.py -- pre-registered token-sizing/memory bench for the hq-hermes pilot (T7b).
# stdlib only. v2: adaptive prompt sizing + an `ollama ps`-based memory recipe (RSS cannot
# see Metal-allocated model memory on this box).
import argparse
import json
import subprocess
import threading
import time
import urllib.request

PARAGRAPH = (
    "The quick brown fox jumps over the lazy dog near the riverbank while "
    "the autumn wind carries leaves across the quiet stone bridge. "
)
OLLAMA_URL = "http://127.0.0.1:11434/api/chat"
OLLAMA_BIN = "/usr/local/bin/ollama"
COLIMA_BIN = "/opt/homebrew/bin/colima"
PROMPT_DIR = "/Users/sunil_rajput/claude-hq/run/hermes-pilot/bench"
SUFFIX = "\n\nIgnore everything above. Reply with exactly the single word OK."
UNIT_GB = {"GB": 1.0, "MB": 1 / 1024.0, "KB": 1 / 1024.0 ** 2, "TB": 1024.0}

def reps_for_chars(divisor, n_tokens):
    return max(1, int((divisor * n_tokens) // len(PARAGRAPH)) + 1)

def prompt_for_reps(reps):
    return PARAGRAPH * reps + SUFFIX

def parse_size_to_gb(text):
    # "12 GB" / "7.3 GB" / "512 MB" -> float GB
    parts = text.strip().split()
    if len(parts) != 2:
        return 0.0
    try:
        val = float(parts[0])
    except ValueError:
        return 0.0
    unit = parts[1].upper()
    for prefix, mult in UNIT_GB.items():
        if unit.startswith(prefix):
            return val * mult
    return val

def run_cmd(argv):
    return subprocess.run(argv, capture_output=True, text=True, timeout=10).stdout

def rss_ollama_gb():
    kb = 0
    for line in run_cmd(["ps", "-axo", "rss=,command="]).splitlines():
        parts = line.strip().split(None, 1)
        if len(parts) == 2 and "ollama" in parts[1].lower():
            try:
                kb += int(parts[0])
            except ValueError:
                pass
    return kb / (1024.0 * 1024.0)

def colima_vm_gb():
    lines = run_cmd([COLIMA_BIN, "list"]).splitlines()
    if not lines or "MEMORY" not in lines[0].split():
        return 0.0
    idx = lines[0].split().index("MEMORY")
    for line in lines[1:]:
        cols = line.split()
        if len(cols) > idx:
            digits = "".join(c for c in cols[idx] if c.isdigit() or c == ".")
            if digits:
                return float(digits)
    return 0.0

def ollama_ps_size_gb(model):
    lines = run_cmd([OLLAMA_BIN, "ps"]).splitlines()
    if len(lines) < 2:
        return 0.0
    size_start = lines[0].index("SIZE")
    for line in lines[1:]:
        if model in line:
            toks = line[size_start:].strip().split()
            if len(toks) >= 2:
                return parse_size_to_gb(f"{toks[0]} {toks[1]}")
    return 0.0

def vm_stat_swapouts():
    for line in run_cmd(["vm_stat"]).splitlines():
        if line.strip().lower().startswith("swapouts:"):
            digits = "".join(c for c in line if c.isdigit())
            if digits:
                return int(digits)
    return 0

def pagesize_bytes():
    digits = "".join(c for c in run_cmd(["pagesize"]) if c.isdigit())
    return int(digits) if digits else 4096

class Sampler(threading.Thread):
    def __init__(self, model, colima_gb):
        super().__init__(daemon=True)
        self.model, self.colima_gb = model, colima_gb
        self.stop_flag = threading.Event()
        self.peak_rss_ollama_gb = 0.0
        self.peak_total_gb = 0.0
        self.peak_ollama_ps_size_gb = 0.0

    def run(self):
        while not self.stop_flag.is_set():
            rss = rss_ollama_gb()
            ps_size = ollama_ps_size_gb(self.model)
            total = ps_size + self.colima_gb
            self.peak_rss_ollama_gb = max(self.peak_rss_ollama_gb, rss)
            if total > self.peak_total_gb:
                self.peak_total_gb, self.peak_ollama_ps_size_gb = total, ps_size
            self.stop_flag.wait(2)

def post_chat(model, prompt, max_time):
    payload = {
        "model": model, "stream": False,
        "messages": [{"role": "user", "content": prompt}],
        "options": {"num_predict": 16, "temperature": 0},
    }
    req = urllib.request.Request(
        OLLAMA_URL, data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json"},
    )
    t0 = time.time()
    status, resp_json, err = None, None, None
    try:
        with urllib.request.urlopen(req, timeout=max_time) as resp:
            resp_json = json.loads(resp.read())
    except Exception as e:
        err = e
        status = "TIMEOUT" if "timed out" in str(e).lower() else "ERROR"
    return status, resp_json, err, time.time() - t0

def run_attempts(model, n, max_time):
    # Adaptive sizing: build @5.2 chars/token, POST; if undershoot 0.9xN, rebuild+retry (<=3).
    attempts = []
    divisor = 5.2
    reps = reps_for_chars(divisor, n)
    prompt = status = resp_json = err = sampler = None
    wall_s = 0.0
    cvm = colima_vm_gb()
    for attempt_i in range(1, 4):
        prompt = prompt_for_reps(reps)
        sampler = Sampler(model, cvm)
        sampler.start()
        status, resp_json, err, wall_s = post_chat(model, prompt, max_time)
        sampler.stop_flag.set()
        sampler.join(timeout=5)
        pec = resp_json.get("prompt_eval_count", 0) if status is None and resp_json else 0
        attempts.append({
            "attempt": attempt_i, "divisor": divisor, "reps": reps,
            "prompt_chars": len(prompt), "prompt_eval_count": pec, "wall_s": wall_s,
        })
        if status is not None or pec >= 0.9 * n or attempt_i == 3:
            break
        scale = (1.03 * n / pec) if pec > 0 else 2.0
        reps = max(reps + 1, int(reps * scale) + 1)
    return attempts, prompt, status, resp_json, err, wall_s, sampler, cvm

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", required=True)
    ap.add_argument("--target-tokens", type=int, required=True)
    ap.add_argument("--max-time", type=float, required=True)
    ap.add_argument("--label", required=True)
    ap.add_argument("--out", required=True)
    a = ap.parse_args()
    n = a.target_tokens
    swapouts_before = vm_stat_swapouts()
    pagesize = pagesize_bytes()
    attempts, prompt, status, resp_json, err, wall_s, sampler, cvm = run_attempts(
        a.model, n, a.max_time)
    with open(f"{PROMPT_DIR}/prompt-{a.label}.txt", "w") as f:
        f.write(prompt)
    swapouts_after = vm_stat_swapouts()
    swapouts_delta_gb = max(0, swapouts_after - swapouts_before) * pagesize / (1024.0 ** 3)
    result = {
        "label": a.label, "model": a.model, "target_tokens": n, "max_time": a.max_time,
        "colima_vm_gb": cvm, "attempts": attempts, "wall_s": wall_s,
        "rss_info_only": sampler.peak_rss_ollama_gb,
        "ollama_ps_size_gb": sampler.peak_ollama_ps_size_gb,
        "peak_total_gb": sampler.peak_total_gb,
        "swapouts_before": swapouts_before, "swapouts_after": swapouts_after,
        "swapouts_delta_gb": swapouts_delta_gb,
        "memory_pressure": swapouts_delta_gb > 1.0,
        "recipe": "v2: ollama ps SIZE + colima list MEMORY, 2 s samples; RSS info only; swapouts delta info only",
    }
    if status is None:
        pec = resp_json.get("prompt_eval_count", 0)
        msg = resp_json.get("message") or {}
        tokens_ok = pec >= 0.9 * n
        result.update({
            "prompt_eval_count": pec,
            "eval_count": resp_json.get("eval_count", 0),
            "prompt_eval_duration_s": resp_json.get("prompt_eval_duration", 0) / 1e9,
            "eval_duration_s": resp_json.get("eval_duration", 0) / 1e9,
            "total_duration_s": resp_json.get("total_duration", 0) / 1e9,
            "reply": msg.get("content", ""),
            "tokens_ok": tokens_ok,
        })
        if not tokens_ok:
            status = "FAIL_TOKENS"
        elif wall_s > a.max_time:
            status = "FAIL_TIME"
        elif result["peak_total_gb"] > 12.5:
            status = "FAIL_MEM"
        else:
            status = "PASS"
    else:
        result.update({"prompt_eval_count": 0, "eval_count": 0,
                        "prompt_eval_duration_s": 0, "eval_duration_s": 0,
                        "total_duration_s": 0, "reply": "", "tokens_ok": False,
                        "error": str(err) if err else ""})
    result["status"] = status
    with open(a.out, "w") as f:
        json.dump(result, f, indent=2)
    print(json.dumps(result))

if __name__ == "__main__":
    main()
