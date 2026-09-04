# hq-hardened.patch — the pilot's hardening, reproducible from GitHub

Net diff from the pinned Hermes tag `v2026.8.31` (29112bef) to the pilot's hardened checkout `hq-hardened` (8 commits: T3 plugin strip, T3b core credential guards, T3c dashboard guards, T3d get_anthropic_key + child-env, T3e proof-check fixes + tests, T3f re-run fixes + wider tests, fixture hygiene, T3h fence tests pin HERMES_HOME — HEAD recorded in the pilot's memory note and HANDOFF). The checkout itself lives in the gitignored `repos/hermes-agent` and is never pushed; this **single** patch (deliberately not a per-commit series — a series would carry superseded test strings that trip the secret scanner) reproduces it.

Rebuild (operator runs the clone line via `!`; the HQ Trust Gate blocks agents from cloning an unlisted author):

```
# 1. clone the pinned tag (operator, via `!`, with the HQ_TRUST_OVERRIDE=1 prefix)
#    target: ~/claude-hq/repos/hermes-agent, branch/tag v2026.8.31, depth 1
# 2. then:
git -C ~/claude-hq/repos/hermes-agent switch -c hq-hardened
git -C ~/claude-hq/repos/hermes-agent apply ~/claude-hq/run/pilot-tree/skills/hq-hermes/patches/hq-hardened.patch
git -C ~/claude-hq/repos/hermes-agent add -- agent hermes_cli tools tests plugins
git -C ~/claude-hq/repos/hermes-agent commit -m "hq-hardened (from patch)" -- agent hermes_cli tools tests plugins
cd ~/claude-hq/repos/hermes-agent && uv sync --locked && ./.venv/bin/python -m unittest tests.hq_pilot.test_fence -v   # expect 12 OK
```

Verified with `git apply --check` against a pristine tag checkout on 2026-09-03. Reviewed by: T5 blind verify, `/proof-check`, re-run #1, re-run #3 (CLEAN) — see `../reviews/`. Re-generated + re-verified 2026-09-04 after T3h (8 commits over the tag).
