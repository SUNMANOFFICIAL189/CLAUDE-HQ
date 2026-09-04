#!/usr/bin/env python3
# ollama-bench.py -- pre-registered RSS/context bench for the hq-hermes pilot (T7).
# stdlib only.
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
PROMPT_DIR = "/Users/sunil_rajput/claude-hq/run/hermes-pilot/bench"


def build_prompt(n):
    text = ""
    while len(text) / 3.5 < n:
        text += PARAGRAPH
    return text + "\n\nIgnore everything above. Reply with exactly the single word OK."


def rss_ollama_gb():
    out = subprocess.run(["ps", "-axo", "rss=,command="], capture_output=True,
                          text=True, timeout=10).stdout
    kb = 0
    for line in out.splitlines():
        parts = line.strip().split(None, 1)
        if len(parts) == 2 and "ollama" in parts[1].lower():
            try:
                kb += int(parts[0])
            except ValueError:
                pass
    return kb / (1024.0 * 1024.0)


def colima_vm_gb():
    out = subprocess.run(["/opt/homebrew/bin/colima", "list"], capture_output=True,
                          text=True, timeout=10).stdout
    lines = out.splitlines()
    if not lines:
        return 0.0
    hdr = lines[0].split()
    if "MEMORY" not in hdr:
        return 0.0
    idx = hdr.index("MEMORY")
    for line in lines[1:]:
        cols = line.split()
        if len(cols) > idx:
            digits = "".join(c for c in cols[idx] if c.isdigit() or c == ".")
            if digits:
                return float(digits)
    return 0.0


def ollama_ps_line(model):
    out = subprocess.run(["/usr/local/bin/ollama", "ps"], capture_output=True,
                          text=True, timeout=10).stdout
    lines = out.splitlines()
    for line in lines[1:]:
        if model in line:
            return line.strip()
    return lines[-1].strip() if len(lines) > 1 else ""


class Sampler(threading.Thread):
    def __init__(self, model, colima_gb):
        super().__init__(daemon=True)
        self.model = model
        self.colima_gb = colima_gb
        self.stop_flag = threading.Event()
        self.peak_rss_ollama_gb = 0.0
        self.peak_total_gb = 0.0
        self.ollama_ps_peak_line = ""

    def run(self):
        while not self.stop_flag.is_set():
            rss = rss_ollama_gb()
            total = rss + self.colima_gb
            self.peak_rss_ollama_gb = max(self.peak_rss_ollama_gb, rss)
            if total > self.peak_total_gb:
                self.peak_total_gb = total
                self.ollama_ps_peak_line = ollama_ps_line(self.model)
            self.stop_flag.wait(2)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", required=True)
    ap.add_argument("--target-tokens", type=int, required=True)
    ap.add_argument("--max-time", type=float, required=True)
    ap.add_argument("--label", required=True)
    ap.add_argument("--out", required=True)
    a = ap.parse_args()

    prompt = build_prompt(a.target_tokens)
    with open(f"{PROMPT_DIR}/prompt-{a.label}.txt", "w") as f:
        f.write(prompt)

    cvm = colima_vm_gb()
    sampler = Sampler(a.model, cvm)
    payload = {
        "model": a.model, "stream": False,
        "messages": [{"role": "user", "content": prompt}],
        "options": {"num_predict": 16, "temperature": 0},
    }
    req = urllib.request.Request(
        OLLAMA_URL, data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json"},
    )

    result = {"label": a.label, "model": a.model, "target_tokens": a.target_tokens,
              "max_time": a.max_time, "colima_vm_gb": cvm}
    sampler.start()
    t0 = time.time()
    status, resp_json, err = None, None, None
    try:
        with urllib.request.urlopen(req, timeout=a.max_time) as resp:
            resp_json = json.loads(resp.read())
    except Exception as e:
        err = e
        status = "TIMEOUT" if "timed out" in str(e).lower() else "ERROR"
    wall_s = time.time() - t0
    sampler.stop_flag.set()
    sampler.join(timeout=5)

    result["wall_s"] = wall_s
    result["peak_rss_ollama_gb"] = sampler.peak_rss_ollama_gb
    result["peak_total_gb"] = sampler.peak_total_gb
    result["ollama_ps_peak_line"] = sampler.ollama_ps_peak_line

    if status is None:
        pec = resp_json.get("prompt_eval_count", 0)
        msg = resp_json.get("message") or {}
        tokens_ok = pec >= 0.9 * a.target_tokens
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
