#!/usr/bin/env bash
# HQ Hermes pilot — T8c-B config renderer (bash + sed + a self-check python
# invocation, no other tools).
#
# Usage: render-config.sh {ollama|groq} [--model <name>] [--template <path>]
#                          [--workdir <abs dir>]
#   ollama -> fully resolves the template (default $SK/templates/config.yaml.tmpl,
#             or --template's fenced path -- see below) and writes it
#             atomically (temp file + mv) to $HH/config.yaml, where $HH is
#             $HERMES_HOME if set in the environment, else the pilot's real
#             HERMES_HOME. Rejects a --model argument (T7 already pinned the
#             Ollama model; it is never overridden here).
#   groq   -> resolves BASE_URL/SECRETS_ENABLED/KEY_ENV_BLOCK/@@MODEL@@ for
#             the Groq arm using the REQUIRED --model <name> argument (the
#             real Groq model is chosen at T10 from live rate-limit headers,
#             never hardcoded here) and writes atomically to $HH/config.yaml
#             ONLY -- the same $HH resolution as the ollama arm. It NEVER
#             writes $SK/templates/config.groq.yaml.tmpl.pending (HQ pilot
#             T8b fix for proof-check-s3-2026-09-04.md's MEDIUM-6: the old
#             groq branch wrote into that TRACKED path and never installed a
#             config at all). That stale hand-authored preview file -- a
#             14-aux-block snapshot from before this arm existed, sitting
#             inside the --template allowlist directory -- has been removed
#             entirely by T8d (LOW-b); this comment IS the up-to-date
#             description of what `groq` does. T10 still supplies the real
#             --model value from live rate-limit headers; nothing here
#             renders a groq config until that argument is given.
#   Missing --model on the groq arm -> exit 2. Any other first argument
#   (including none, or more than one positional) -> exit 2.
#
# --workdir <abs dir> (T8d fix for proof-check-s3-rerun2-2026-09-04.md
# HIGH-2): the OLD template pinned `docker_mount_cwd_to_workspace: true`
# with no `terminal.cwd`, so a job container mounted whatever directory the
# wrapper happened to be LAUNCHED from -- read-write -- at /workspace,
# `~/claude-hq` included. The template now ships
# `docker_mount_cwd_to_workspace: false` and mounts nothing by default.
# --workdir <dir> opts a single render into a job-specific mount: the
# argument must physically resolve (`cd ... && pwd -P`, symlinks and `..`
# followed) to an EXISTING directory under $PR (the pilot's run/output
# tree) -- else exit 2 before anything is read or written. On acceptance,
# the rendered config gets `terminal.cwd: "<resolved dir>"` and
# `terminal.docker_volumes: ["<resolved dir>:/workspace"]`; without
# --workdir, `terminal.docker_volumes` stays `[]` and no `terminal.cwd` key
# is written at all.
#
# --template <path> (T8c-B fix for proof-check-s3-rerun-2026-09-04.md
# MEDIUM-a): the OLD `TEMPLATE=<env var>` escape hatch has been REMOVED
# ENTIRELY -- it was an uncontained input to a script that also lets
# $HERMES_HOME steer the write target, so together they could point the
# whole render at an arbitrary source and destination with zero fencing. The
# only way to render from a non-default template now is the --template flag,
# and it is honoured ONLY when its FULLY resolved path -- directory
# physically resolved via `cd ... && pwd -P` (after stripping any trailing
# slash from the argument, same L-a lesson as hermes-engine.sh's override
# fence: a trailing slash defeats a `-L` test taken on the unresolved
# argument, so `-L` here is taken on the resolved dir+basename, never the
# raw argument) plus its basename -- is a regular file (`-f`), is NOT a
# symlink (`-L` on the resolved path), and lives under $SK/templates. Any
# other value -> exit 2 before anything is read or written.
#
# HERMES_HOME, if set in the environment, must name an existing directory
# (-d) -- else exit 2. This is the same variable that decides $OUT below, so
# a typo'd or already-gone HERMES_HOME must never silently create a fresh
# hierarchy in the wrong place.
#
# Self-check (C1b, proof-check-s3-2026-09-04.md CRITICAL fix; expanded by
# T8c-B for proof-check-s3-rerun-2026-09-04.md MEDIUM-a): after every
# substitution pass and BEFORE the atomic mv, the rendered file must:
#   (1) contain zero unresolved @@ placeholders;
#   (2) parse as YAML with terminal.backend == "docker", secrets.command
#       .enabled a real bool, hooks a list/dict, and _config_version an int
#       (H3);
#   (3) approvals.deny a non-empty list;
#   (4) auxiliary.free_only is True;
#   (5) terminal.docker_network is False;
#   (6) terminal.docker_mount_cwd_to_workspace is False (T8d, HIGH-2 fix --
#       was pinned True with no terminal.cwd, mounting whatever directory
#       the wrapper happened to launch from);
#   (7) terminal.docker_persist_across_processes is False;
#   (8) terminal.docker_extra_args == []; and, on terminal.cwd (T8d):
#       - absent -> terminal.docker_volumes == [];
#       - present -> it physically resolves to an EXISTING directory under
#         $PR, and terminal.docker_volumes == ["<that dir>:/workspace"]
#         (exactly one volume, job-specific, never the renderer's own cwd);
#   (9) every `DEFAULT_CONFIG["auxiliary"]` sub-dict with a "provider" key
#       (imported live, with HERMES_HOME set, from
#       hermes_cli.config_defaults -- never a list hand-maintained here) is
#       present in the rendered file with provider == "custom".
# Any failure -> a message on stderr, exit 1, and the target file left
# UNCHANGED (the EXIT trap only ever removes this script's own temp files,
# never $OUT — the atomic mv is the last statement in the script, after
# every check passes).

set -euo pipefail

SK="/Users/sunil_rajput/claude-hq/run/pilot-tree/skills/hq-hermes"
PY="/Users/sunil_rajput/claude-hq/repos/hermes-agent/.venv/bin/python"

usage() {
    echo "usage: render-config.sh {ollama|groq} [--model <name>] [--template <path>] [--workdir <abs dir>]" >&2
}

readonly PR_DIR="/Users/sunil_rajput/claude-hq/run/hermes-pilot"

# ---- HERMES_HOME fence: if set, must already exist as a directory ----------
if [ -n "${HERMES_HOME:-}" ] && [ ! -d "${HERMES_HOME}" ]; then
    echo "render-config.sh: HERMES_HOME=${HERMES_HOME} is set but is not an existing directory" >&2
    exit 2
fi
HH="${HERMES_HOME:-/Users/sunil_rajput/claude-hq/run/hermes-hq}"

ARM="${1:-}"
shift || true

MODEL_ARG=""
TEMPLATE_ARG=""
WORKDIR_ARG=""
while [ "$#" -gt 0 ]; do
    case "$1" in
        --model)
            if [ "$#" -lt 2 ] || [ -z "${2:-}" ]; then
                usage
                exit 2
            fi
            MODEL_ARG="$2"
            shift 2
            ;;
        --template)
            if [ "$#" -lt 2 ] || [ -z "${2:-}" ]; then
                usage
                exit 2
            fi
            TEMPLATE_ARG="$2"
            shift 2
            ;;
        --workdir)
            if [ "$#" -lt 2 ] || [ -z "${2:-}" ]; then
                usage
                exit 2
            fi
            WORKDIR_ARG="$2"
            shift 2
            ;;
        *)
            usage
            exit 2
            ;;
    esac
done

case "$ARM" in
    ollama)
        if [ -n "$MODEL_ARG" ]; then
            usage
            exit 2
        fi
        MODEL="hq-coder-64k"
        BASE_URL="http://127.0.0.1:11434/v1"
        SECRETS_ENABLED="false"
        KEY_ENV_BLOCK=""
        ;;
    groq)
        if [ -z "$MODEL_ARG" ]; then
            usage
            exit 2
        fi
        MODEL="$MODEL_ARG"
        BASE_URL="https://api.groq.com/openai/v1"
        SECRETS_ENABLED="true"
        KEY_ENV_BLOCK="providers:
  groq:
    base_url: \"https://api.groq.com/openai/v1\"
    key_env: \"GROQ_API_KEY\""
        ;;
    *)
        usage
        exit 2
        ;;
esac

# ---- --template fence: fully-resolved path must be a regular, non-symlink
# file under $SK/templates. Trailing slash stripped before dirname/basename
# so a symlinked basename can't hide behind one (same lesson as B5). --------
SK_TEMPLATES_PHYS="$(cd "$SK/templates" && pwd -P)"
if [ -n "$TEMPLATE_ARG" ]; then
    _tpl_stripped="${TEMPLATE_ARG%/}"
    _tpl_dirname="$(dirname "$_tpl_stripped")"
    _tpl_base="$(basename "$_tpl_stripped")"
    _tpl_dir="$(cd "$_tpl_dirname" 2>/dev/null && pwd -P)" || _tpl_dir=""
    _tpl_ok=0
    _tpl_resolved=""
    if [ -n "$_tpl_dir" ]; then
        case "$_tpl_dir/" in
            "$SK_TEMPLATES_PHYS/"*)
                _tpl_resolved="$_tpl_dir/$_tpl_base"
                if [ -f "$_tpl_resolved" ] && [ ! -L "$_tpl_resolved" ]; then
                    _tpl_ok=1
                fi
                ;;
        esac
    fi
    if [ "$_tpl_ok" -ne 1 ]; then
        echo "render-config.sh: --template must physically resolve to an existing, non-symlink regular file under $SK_TEMPLATES_PHYS (got: $TEMPLATE_ARG)" >&2
        exit 2
    fi
    TMPL="$_tpl_resolved"
    unset _tpl_stripped _tpl_dirname _tpl_base _tpl_dir _tpl_ok _tpl_resolved
else
    TMPL="$SK/templates/config.yaml.tmpl"
fi

# ---- --workdir fence (T8d, HIGH-2 fix): must physically resolve (`pwd -P`,
# symlinks and `..` followed) to an EXISTING directory under $PR_DIR. A
# nonexistent directory fails the `cd` itself; an existing one outside
# $PR_DIR fails the prefix check below. Either way -> exit 2 before
# anything is read or written. ------------------------------------------
PR_PHYS="$(cd "$PR_DIR" && pwd -P)"
if [ -n "$WORKDIR_ARG" ]; then
    _wd_resolved="$(cd "$WORKDIR_ARG" 2>/dev/null && pwd -P)" || _wd_resolved=""
    _wd_ok=0
    if [ -n "$_wd_resolved" ]; then
        case "$_wd_resolved/" in
            "$PR_PHYS/"*)
                _wd_ok=1
                ;;
        esac
    fi
    if [ "$_wd_ok" -ne 1 ]; then
        echo "render-config.sh: --workdir must physically resolve to an existing directory under $PR_PHYS (got: $WORKDIR_ARG)" >&2
        exit 2
    fi
    WORKDIR="$_wd_resolved"
    unset _wd_resolved _wd_ok
else
    WORKDIR=""
fi

if [ -n "$WORKDIR" ]; then
    WORKDIR_BLOCK="  cwd: \"$WORKDIR\"
  docker_volumes: [\"$WORKDIR:/workspace\"]"
else
    WORKDIR_BLOCK="  docker_volumes: []"
fi

OUT="$HH/config.yaml"

if [ ! -f "$TMPL" ]; then
    echo "render-config.sh: template not found: $TMPL" >&2
    exit 2
fi

OUT_DIR="$(dirname "$OUT")"
mkdir -p "$OUT_DIR"

TMP_MAIN="$(mktemp "$OUT_DIR/.render-config.XXXXXX")"
TMP_WORKDIR="$(mktemp "$OUT_DIR/.render-config-workdir.XXXXXX")"
TMP_FINAL="$(mktemp "$OUT_DIR/.render-config-final.XXXXXX")"
cleanup() {
    rm -f "$TMP_MAIN" "$TMP_WORKDIR" "$TMP_FINAL"
}
trap cleanup EXIT

# Single-line placeholders first (pipe delimiter -- BASE_URL contains slashes).
sed \
    -e "s|@@MODEL@@|${MODEL}|g" \
    -e "s|@@BASE_URL@@|${BASE_URL}|g" \
    -e "s|@@SECRETS_ENABLED@@|${SECRETS_ENABLED}|g" \
    "$TMPL" > "$TMP_MAIN"

# @@WORKDIR_BLOCK@@ is a whole-line marker (T8d). Always non-empty (either
# the no-mount default or the job-specific cwd+volume pair) -- read its
# contents in after the marker line, then delete the marker line itself
# (same r/d idiom as @@KEY_ENV_BLOCK@@ below).
WORKDIR_BLOCK_FILE="$(mktemp "$OUT_DIR/.render-config-workdirblock.XXXXXX")"
trap 'rm -f "$TMP_MAIN" "$TMP_WORKDIR" "$TMP_FINAL" "$WORKDIR_BLOCK_FILE"' EXIT
printf '%s\n' "$WORKDIR_BLOCK" > "$WORKDIR_BLOCK_FILE"
sed -e "/^@@WORKDIR_BLOCK@@\$/{
r ${WORKDIR_BLOCK_FILE}
d
}" "$TMP_MAIN" > "$TMP_WORKDIR"
rm -f "$WORKDIR_BLOCK_FILE"
trap cleanup EXIT

# @@KEY_ENV_BLOCK@@ is a whole-line marker. Empty block -> delete the line.
# Non-empty block -> read its contents in after the marker line, then delete
# the marker line itself (classic sed r/d idiom -- no other tool needed).
if [ -z "$KEY_ENV_BLOCK" ]; then
    sed -e '/^@@KEY_ENV_BLOCK@@$/d' "$TMP_WORKDIR" > "$TMP_FINAL"
else
    KEYENV_BLOCK_FILE="$(mktemp "$OUT_DIR/.render-config-keyenv.XXXXXX")"
    trap 'rm -f "$TMP_MAIN" "$TMP_WORKDIR" "$TMP_FINAL" "$KEYENV_BLOCK_FILE"' EXIT
    printf '%s\n' "$KEY_ENV_BLOCK" > "$KEYENV_BLOCK_FILE"
    sed -e "/^@@KEY_ENV_BLOCK@@\$/{
r ${KEYENV_BLOCK_FILE}
d
}" "$TMP_WORKDIR" > "$TMP_FINAL"
    rm -f "$KEYENV_BLOCK_FILE"
fi

# ---- self-check: BEFORE the mv. $OUT is untouched by anything below;
# only $TMP_MAIN/$TMP_WORKDIR/$TMP_FINAL (cleaned up by the trap) are read
# or written. ----
# HQ pilot (T8d, LOW-c proof-check-s3-rerun2-2026-09-04.md): `grep -c`
# counts MATCHING LINES, not occurrences -- two unresolved placeholders on
# one line would have under-counted as 1. `grep -o | wc -l` counts each
# occurrence.
PLACEHOLDER_COUNT="$(grep -o '@@' "$TMP_FINAL" | wc -l | tr -d '[:space:]' || true)"
if [ "$PLACEHOLDER_COUNT" -ne 0 ]; then
    echo "render-config.sh: refusing to install -- $PLACEHOLDER_COUNT unresolved @@ placeholder(s) remain in the rendered file ($OUT left unchanged)" >&2
    exit 1
fi

if ! HERMES_HOME="$HH" "$PY" - "$TMP_FINAL" <<'PY'
import os
import sys

import yaml

PR_DIR_PHYS = os.path.realpath(
    "/Users/sunil_rajput/claude-hq/run/hermes-pilot"
)

path = sys.argv[1]
with open(path, encoding="utf-8") as f:
    text = f.read()

try:
    d = yaml.safe_load(text)
except Exception as e:
    print(f"render-config.sh: rendered file failed to parse as YAML: {e}", file=sys.stderr)
    sys.exit(1)

errors = []
if not isinstance(d, dict):
    errors.append("top-level YAML is not a mapping")
else:
    terminal = d.get("terminal") or {}
    auxiliary = d.get("auxiliary") or {}
    approvals = d.get("approvals") or {}
    secrets_enabled = ((d.get("secrets") or {}).get("command") or {}).get("enabled")

    if terminal.get("backend") != "docker":
        errors.append('terminal.backend != "docker"')
    if not isinstance(secrets_enabled, bool):
        errors.append("secrets.command.enabled is not a real bool")
    if not isinstance(d.get("hooks"), (list, dict)):
        errors.append("hooks is not a list or dict")
    cfg_version = d.get("_config_version")
    if isinstance(cfg_version, bool) or not isinstance(cfg_version, int):
        errors.append("_config_version is not an int")

    deny = approvals.get("deny")
    if not isinstance(deny, list) or not deny:
        errors.append("approvals.deny is not a non-empty list")
    if auxiliary.get("free_only") is not True:
        errors.append("auxiliary.free_only is not True")
    if terminal.get("docker_network") is not False:
        errors.append("terminal.docker_network is not False")
    if terminal.get("docker_mount_cwd_to_workspace") is not False:
        errors.append("terminal.docker_mount_cwd_to_workspace is not False")
    if terminal.get("docker_persist_across_processes") is not False:
        errors.append("terminal.docker_persist_across_processes is not False")
    if terminal.get("docker_extra_args") != []:
        errors.append("terminal.docker_extra_args is not []")

    # T8d (HIGH-2 fix): terminal.cwd is optional -- absent means no mount at
    # all; present means it must be an EXISTING directory under $PR and the
    # ONLY volume must be that exact "<cwd>:/workspace" pair (never the
    # renderer's own launch directory).
    cwd = terminal.get("cwd")
    if cwd is None:
        if terminal.get("docker_volumes") != []:
            errors.append("terminal.docker_volumes is not [] (no terminal.cwd present)")
    elif not isinstance(cwd, str) or not cwd:
        errors.append(f"terminal.cwd is not a non-empty string (got: {cwd!r})")
    else:
        cwd_phys = os.path.realpath(cwd)
        if not os.path.isdir(cwd_phys) or not (
            cwd_phys == PR_DIR_PHYS or cwd_phys.startswith(PR_DIR_PHYS + os.sep)
        ):
            errors.append(
                f"terminal.cwd does not resolve to an existing directory under {PR_DIR_PHYS} (got: {cwd!r})"
            )
        if terminal.get("docker_volumes") != [f"{cwd}:/workspace"]:
            errors.append(
                f"terminal.docker_volumes != ['{cwd}:/workspace'] (got: {terminal.get('docker_volumes')!r})"
            )

    try:
        from hermes_cli.config_defaults import DEFAULT_CONFIG
    except Exception as e:
        DEFAULT_CONFIG = None
        errors.append(f"could not import DEFAULT_CONFIG to derive the auxiliary surface list: {e}")

    if DEFAULT_CONFIG is not None:
        aux_defaults = DEFAULT_CONFIG.get("auxiliary") or {}
        surfaces = sorted(
            key for key, value in aux_defaults.items()
            if isinstance(value, dict) and "provider" in value
        )
        if not surfaces:
            errors.append("derived 0 auxiliary surfaces from DEFAULT_CONFIG -- refusing to trust an empty fence")
        for surface in surfaces:
            surface_cfg = auxiliary.get(surface)
            if not isinstance(surface_cfg, dict) or surface_cfg.get("provider") != "custom":
                errors.append(f"auxiliary.{surface}.provider != 'custom' (got: {surface_cfg!r})")

if errors:
    for e in errors:
        print(f"render-config.sh: self-check failed: {e}", file=sys.stderr)
    sys.exit(1)
PY
then
    echo "render-config.sh: self-check failed -- refusing to install $OUT ($OUT left unchanged)" >&2
    exit 1
fi

mv "$TMP_FINAL" "$OUT"
chmod 600 "$OUT" 2>/dev/null || true

echo "$OUT"
