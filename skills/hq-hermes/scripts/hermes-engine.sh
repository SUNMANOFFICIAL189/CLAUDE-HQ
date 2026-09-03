#!/usr/bin/env bash
# hermes-engine.sh — headless colima/docker engine helper for the hq-hermes pilot.
#
# Subcommands:
#   ensure       start colima (if not running), wait for docker, apply the VM-level
#                egress kill, verify it with two fail-closed negative probes.
#   build-image  temporarily lift the egress kill, run the positive control
#                (proves the probe can see a real leak) while the wall is
#                down for the build, build $IMG, re-apply the kill, re-verify
#                with the two negative probes.
#   selftest     positive control (remove kill, require LEAK) followed by the
#                negative control (re-apply kill, require BLOCKED on both) —
#                proves the probe mechanism itself works, not just that it
#                printed the string we hoped for. Never starts colima.
#   stop         colima stop; verify docker is no longer reachable.
#   status       one-line report: colima / docker / egress-kill rule / image /
#                last recorded probe results (if any).
#   --engine docker-desktop   NOT implemented in this pilot (Docker Desktop must
#                             never be started here). Prints a message, exit 2.
#
# Egress probe method: a python3 -c one-liner run INSIDE the target image via
# `docker run` (python3 is present in both hermes-pilot:v1 and its
# python:3.11-slim base; wget is present in NEITHER, which is why the old
# wget-based probe printed "BLOCKED" unconditionally — exit 127 from a
# missing binary satisfied the `|| echo BLOCKED` fallback every time,
# regardless of whether the wall was actually up. A check that cannot fail
# proves nothing at runtime — Lesson 34). The urllib probe distinguishes a
# real connection (LEAK) from any exception raised while trying to make one
# (BLOCKED <ExceptionName>), and the `selftest`/`build-image` positive
# control proves the probe can actually see LEAK before trusting a BLOCKED
# result anywhere else.
#
# Rules followed: no eval, all variable expansions quoted, binaries resolved
# once (absolute paths) at the top, plain-English messages, fail closed on any
# egress-kill verification ambiguity, the wall is never left down at the end
# of a subcommand (EXIT trap re-applies it if anything goes wrong mid-probe).

set -euo pipefail

# ---- resolved binaries (once) ------------------------------------------------
readonly COLIMA_BIN="/opt/homebrew/bin/colima"
DOCKER_BIN="$(command -v docker)"
readonly DOCKER_BIN
CURL_BIN="$(command -v curl)"
readonly CURL_BIN

# ---- constants ----------------------------------------------------------------
readonly IMG="hermes-pilot:v1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
SK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly SK_DIR
readonly DOCKER_BUILD_DIR="${SK_DIR}/docker"
readonly DOCKERFILE_PATH="${DOCKER_BUILD_DIR}/Dockerfile"
# M8 fix (proof-check-2026-09-03.md): the probe fallback image must be
# referenced by the SAME digest as the Dockerfile's FROM line, checked with
# `docker image inspect` first -- never pulled by a mutable tag (a by-tag
# `docker run`/`docker pull` goes through the daemon, which the DOCKER-USER
# egress kill does not filter, since that chain only governs FORWARDed
# container traffic). Parsed once, here, from the Dockerfile itself so the
# two references can never drift out of sync.
PROBE_FALLBACK_IMG="$(
    grep -m1 -oE '^FROM[[:space:]]+[^[:space:]]+@sha256:[0-9a-f]{64}' "${DOCKERFILE_PATH}" \
        | awk '{print $2}'
)"
readonly PROBE_FALLBACK_IMG
if [ -z "${PROBE_FALLBACK_IMG}" ]; then
    printf '[hermes-engine] ERROR: %s\n' "could not parse a digest-pinned FROM line out of ${DOCKERFILE_PATH}. Refusing to guess a probe fallback image." >&2
    exit 1
fi
readonly DOCKER_INFO_WAIT_SECS=90
readonly PUBLIC_PROBE_URL="http://1.1.1.1"
readonly OLLAMA_PROBE_URL="http://host.docker.internal:11434"
readonly OLLAMA_HOST_PRECHECK_URL="http://127.0.0.1:11434/api/tags"
# PR — the pilot's run/output directory, sibling of the pilot-tree worktree
# ($HQ/run/pilot-tree/skills/hq-hermes -> up 3 -> $HQ/run -> hermes-pilot).
PR_DIR="$(cd "${SK_DIR}/../../../hermes-pilot" && pwd)"
readonly PR_DIR
readonly LAST_PROBE_FILE="${PR_DIR}/engine-last-probe.txt"

# ---- mutable globals ----------------------------------------------------------
# Image the current probe run targets; set by select_probe_image()/build-image
# before probe_egress()/positive_control_probe() are called.
PROBE_IMAGE=""
# Most recent probe lines, used by write_last_probe_file().
LAST_PROBE_LINE_POSCTRL1=""
LAST_PROBE_LINE_POSCTRL2=""
LAST_PROBE_LINE1=""
LAST_PROBE_LINE2=""
# Chain currently expected to be re-applied by trap_reapply_kill (empty =
# nothing pending). Set right before a remove_kill_on_chain, cleared right
# after the matching apply_kill_on_chain.
CURRENT_KILL_CHAIN=""

log() {
    printf '[hermes-engine] %s\n' "$*"
}

err() {
    printf '[hermes-engine] ERROR: %s\n' "$*" >&2
}

usage() {
    cat <<'EOF'
Usage: hermes-engine.sh <ensure|build-image|selftest|stop|status>
       hermes-engine.sh --engine docker-desktop
EOF
}

# Returns 0 and prints the chain name that holds the container-forward filter.
# Prefers DOCKER-USER (docker's own hook chain); falls back to FORWARD if
# DOCKER-USER does not exist in this VM's iptables.
detect_chain() {
    if "${COLIMA_BIN}" ssh -- sudo iptables -S DOCKER-USER >/dev/null 2>&1; then
        printf 'DOCKER-USER'
    else
        printf 'FORWARD'
    fi
}

# Idempotently insert a DROP-all rule into the given chain.
apply_kill_on_chain() {
    local chain="$1"
    if "${COLIMA_BIN}" ssh -- sudo iptables -C "${chain}" -j DROP >/dev/null 2>&1; then
        log "egress-kill DROP rule already present on ${chain}."
    else
        "${COLIMA_BIN}" ssh -- sudo iptables -I "${chain}" -j DROP
        log "egress-kill DROP rule inserted on ${chain}."
    fi
}

# Detects the chain, applies the kill, prints the chain name on stdout.
apply_kill() {
    local chain
    chain="$(detect_chain)"
    apply_kill_on_chain "${chain}" 1>&2
    printf '%s' "${chain}"
}

# Removes the DROP-all rule from the given chain (best-effort; does not fail
# the caller if the rule is already gone).
remove_kill_on_chain() {
    local chain="$1"
    if "${COLIMA_BIN}" ssh -- sudo iptables -C "${chain}" -j DROP >/dev/null 2>&1; then
        "${COLIMA_BIN}" ssh -- sudo iptables -D "${chain}" -j DROP
        log "egress-kill DROP rule removed from ${chain}."
    else
        log "egress-kill DROP rule was not present on ${chain} (nothing to remove)."
    fi
}

# Trap target for the "wall deliberately down" window (positive control /
# build). Safety net only: normal code paths re-apply the kill and clear
# CURRENT_KILL_CHAIN explicitly before disarming the trap. If anything exits
# the script unexpectedly while a chain is pending, this re-applies the DROP
# rule so the wall can never be left down at the end of a subcommand.
trap_reapply_kill() {
    if [ -n "${CURRENT_KILL_CHAIN}" ]; then
        err "unexpected exit while the egress kill was removed — re-applying it on ${CURRENT_KILL_CHAIN} now."
        apply_kill_on_chain "${CURRENT_KILL_CHAIN}" >/dev/null 2>&1 || true
    fi
}

# Picks the image to run the egress probes against: the pilot's own pinned
# image if it exists yet, otherwise the digest-pinned base image from the
# Dockerfile (documented fallback for the first run, before hermes-pilot:v1
# has been built). M8 fix: the fallback is checked with `docker image
# inspect` first and this function fails closed (exit 1, plain reason) if
# it is absent -- it is NEVER pulled by tag, which would go through the
# daemon unfiltered by the DOCKER-USER egress kill.
select_probe_image() {
    if "${DOCKER_BIN}" image inspect "${IMG}" >/dev/null 2>&1; then
        printf '%s' "${IMG}"
        return 0
    fi

    log "NOTE: image ${IMG} does not exist yet (first run) — falling back to the digest-pinned base image ${PROBE_FALLBACK_IMG} for the egress probe instead." 1>&2
    if "${DOCKER_BIN}" image inspect "${PROBE_FALLBACK_IMG}" >/dev/null 2>&1; then
        printf '%s' "${PROBE_FALLBACK_IMG}"
        return 0
    fi

    err "fallback probe image ${PROBE_FALLBACK_IMG} is not present locally. Refusing to pull it by tag (a by-tag pull goes through the daemon, unfiltered by the DOCKER-USER egress kill -- M8: proof-check-2026-09-03.md). Run '$(basename "$0") build-image' first (it pulls the exact pinned digest as part of the Docker build, with the wall intentionally down and the positive control watching), or pull it manually: docker pull ${PROBE_FALLBACK_IMG}"
    return 1
}

# Runs a single egress probe INSIDE ${PROBE_IMAGE} against the given URL,
# using python3 -c (present in both hermes-pilot:v1 and python:3.11-slim; no
# host tool can do this job, since the thing under test is the CONTAINER's
# network path, not the host's). Prints exactly "LEAK" or
# "BLOCKED <ExceptionName>" and nothing else on stdout. A docker/run failure
# unrelated to the probe (e.g. daemon unreachable) propagates as a non-zero
# exit under `set -e`, which is deliberate: an infrastructure failure must
# not be silently read as "BLOCKED".
probe_egress() {
    local url="$1"
    "${DOCKER_BIN}" run --rm "${PROBE_IMAGE}" python3 -c '
import urllib.request, urllib.error, sys
try:
    urllib.request.urlopen(sys.argv[1], timeout=5)
    print("LEAK")
except urllib.error.HTTPError:
    # A real HTTP response (even an error status) means the packet reached
    # the target and a reply came back -- a completed round trip, i.e. a
    # leak, not a block.
    print("LEAK")
except Exception as e:
    print("BLOCKED", type(e).__name__)
' "${url}"
}

# H5 fix (proof-check-2026-09-03.md): before trusting a LEAK/BLOCKED result
# from the OLLAMA_PROBE_URL positive control, confirm the host itself is
# actually serving Ollama. Runs on the HOST (not inside the probe
# container) via a plain curl. Without this, a DNS/connection failure to
# host.docker.internal would print "BLOCKED URLError" with or without the
# wall (Lesson 34 class) and a passing positive control on probe 1 alone
# would mask that probe 2 never proved anything.
check_ollama_reachable_from_host() {
    if ! "${CURL_BIN}" -s -m 3 "${OLLAMA_HOST_PRECHECK_URL}" >/dev/null 2>&1; then
        err "host Ollama is not reachable at ${OLLAMA_HOST_PRECHECK_URL}. The ${OLLAMA_PROBE_URL} positive control cannot be trusted without a live Ollama on the host to leak to (Lesson 34 -- a probe that cannot fail proves nothing). Start Ollama on the host before running this subcommand."
        return 1
    fi
    return 0
}

# Positive control: call ONLY while the egress kill has already been removed
# from the chain by the caller. Requires BOTH probe URLs to report exactly
# "LEAK" -- H5 fix (proof-check-2026-09-03.md): the old positive control
# only exercised PUBLIC_PROBE_URL, so probe 2 (host.docker.internal, a NAME
# rather than an IP literal) had no positive control at all; a DNS failure
# there prints "BLOCKED URLError" with or without the wall (Lesson 34
# class). If either probe reports anything but LEAK with the wall down, the
# probe itself is broken, this VM has no outbound network path, or
# host.docker.internal cannot reach the host Ollama -- any of which means a
# later BLOCKED result on that probe could not be trusted, so this must
# fail loudly rather than let the pilot proceed on an unfalsifiable check.
# Sets LAST_PROBE_LINE_POSCTRL1 / LAST_PROBE_LINE_POSCTRL2. Does not touch
# iptables itself.
positive_control_probe() {
    if ! check_ollama_reachable_from_host; then
        return 1
    fi

    local out1 out2
    out1="$(probe_egress "${PUBLIC_PROBE_URL}")"
    log "positive control (wall DOWN, public internet, ${PUBLIC_PROBE_URL}) using ${PROBE_IMAGE}: ${out1}"
    LAST_PROBE_LINE_POSCTRL1="positive-control (${PUBLIC_PROBE_URL}, wall down): ${out1}"

    out2="$(probe_egress "${OLLAMA_PROBE_URL}")"
    log "positive control (wall DOWN, host Ollama, ${OLLAMA_PROBE_URL}) using ${PROBE_IMAGE}: ${out2}"
    LAST_PROBE_LINE_POSCTRL2="positive-control (${OLLAMA_PROBE_URL}, wall down): ${out2}"

    local failed=0
    if [ "${out1}" != "LEAK" ]; then
        err "positive control FAILED on ${PUBLIC_PROBE_URL}: probe_egress reported '${out1}' with the egress kill REMOVED. Either the probe itself is broken, or this VM has no outbound network path to ${PUBLIC_PROBE_URL} at all — a later BLOCKED result from this probe cannot be trusted."
        failed=1
    fi
    if [ "${out2}" != "LEAK" ]; then
        err "positive control FAILED on ${OLLAMA_PROBE_URL}: probe_egress reported '${out2}' with the egress kill REMOVED, even though the host pre-check confirmed Ollama is reachable at ${OLLAMA_HOST_PRECHECK_URL}. Either the probe is broken, or host.docker.internal cannot resolve/route to the host from inside the container — a later BLOCKED result from this probe cannot be trusted."
        failed=1
    fi

    [ "${failed}" -eq 0 ]
}

# Runs the two negative egress probes (both must report a line starting with
# BLOCKED). Fails closed: any outcome other than that on either probe is a
# verification failure — non-zero, plain-English reason. Sets
# LAST_PROBE_LINE1 / LAST_PROBE_LINE2 for write_last_probe_file(). Never
# touches iptables.
verify_egress() {
    local out1 out2

    out1="$(probe_egress "${PUBLIC_PROBE_URL}")"
    log "probe 1/2 (public internet, ${PUBLIC_PROBE_URL}) using ${PROBE_IMAGE}: ${out1}"
    LAST_PROBE_LINE1="probe1 (${PUBLIC_PROBE_URL}): ${out1}"

    out2="$(probe_egress "${OLLAMA_PROBE_URL}")"
    log "probe 2/2 (host Ollama, ${OLLAMA_PROBE_URL}) using ${PROBE_IMAGE}: ${out2}"
    LAST_PROBE_LINE2="probe2 (${OLLAMA_PROBE_URL}): ${out2}"

    case "${out1}" in
        BLOCKED*) ;;
        *)
            err "egress-kill verification FAILED. probe 1 did not report BLOCKED (got: '${out1}'). Container network egress is not reliably contained. Refusing to proceed."
            return 1
            ;;
    esac
    case "${out2}" in
        BLOCKED*) ;;
        *)
            err "egress-kill verification FAILED. probe 2 did not report BLOCKED (got: '${out2}'). Container network egress is not reliably contained. Refusing to proceed."
            return 1
            ;;
    esac

    log "egress-kill verification OK: both probes report BLOCKED."
    return 0
}

# Appends a fresh, timestamped snapshot of the most recent probe results to
# $PR/engine-last-probe.txt. Overwrites (not appends) so `status` always
# shows the latest run, not an ever-growing log.
write_last_probe_file() {
    local subcommand="$1"
    {
        printf 'subcommand: %s\n' "${subcommand}"
        printf 'timestamp_utc: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        printf 'probe_image: %s\n' "${PROBE_IMAGE}"
        if [ -n "${LAST_PROBE_LINE_POSCTRL1}" ]; then
            printf '%s\n' "${LAST_PROBE_LINE_POSCTRL1}"
        fi
        if [ -n "${LAST_PROBE_LINE_POSCTRL2}" ]; then
            printf '%s\n' "${LAST_PROBE_LINE_POSCTRL2}"
        fi
        if [ -n "${LAST_PROBE_LINE1}" ]; then
            printf '%s\n' "${LAST_PROBE_LINE1}"
        fi
        if [ -n "${LAST_PROBE_LINE2}" ]; then
            printf '%s\n' "${LAST_PROBE_LINE2}"
        fi
    } > "${LAST_PROBE_FILE}"
    log "probe results recorded to ${LAST_PROBE_FILE}"
}

wait_for_docker() {
    local waited=0
    until "${DOCKER_BIN}" info >/dev/null 2>&1; do
        if [ "${waited}" -ge "${DOCKER_INFO_WAIT_SECS}" ]; then
            err "docker info did not succeed within ${DOCKER_INFO_WAIT_SECS}s of colima starting. The engine is not usable."
            return 1
        fi
        sleep 3
        waited=$((waited + 3))
    done
    log "docker daemon reachable (waited ${waited}s)."
    return 0
}

cmd_ensure() {
    if "${COLIMA_BIN}" status >/dev/null 2>&1; then
        log "colima is already running."
    else
        log "colima is not running — starting it now. First start downloads a VM image and can take up to ~10 minutes: colima start --cpus 2 --memory 3 --disk 20 --vm-type vz"
        "${COLIMA_BIN}" start --cpus 2 --memory 3 --disk 20 --vm-type vz
    fi

    if ! wait_for_docker; then
        exit 1
    fi

    local chain
    chain="$(apply_kill)"
    log "egress kill is applied on chain: ${chain}"

    PROBE_IMAGE="$(select_probe_image)"

    # ensure NEVER removes the wall — negative probes only.
    if ! verify_egress; then
        exit 1
    fi

    write_last_probe_file "ensure"

    log "ensure: OK. colima is up, docker is reachable, egress kill verified on ${chain}."
}

cmd_build_image() {
    if ! "${DOCKER_BIN}" info >/dev/null 2>&1; then
        err "docker daemon is not reachable. Run 'ensure' first."
        exit 1
    fi

    local chain
    chain="$(detect_chain)"

    PROBE_IMAGE="$(select_probe_image)"

    log "temporarily removing the egress kill on ${chain} so the build can reach the registry/daemon..."
    CURRENT_KILL_CHAIN="${chain}"
    # H6 fix (proof-check-2026-09-03.md): EXIT alone does not cover
    # SIGTERM/SIGHUP/SIGINT arriving during the wall-down window (e.g. the
    # docker build below), which would leave the DROP rule off. Trap all
    # four so any of them re-applies the kill.
    trap trap_reapply_kill EXIT INT TERM HUP
    remove_kill_on_chain "${chain}"

    log "running the positive control while the wall is down for the build..."
    if ! positive_control_probe; then
        err "Re-applying the egress kill before exiting (never leave the kill removed)."
        apply_kill_on_chain "${chain}"
        trap - EXIT INT TERM HUP
        CURRENT_KILL_CHAIN=""
        exit 1
    fi

    local build_start build_end build_seconds
    build_start="$(date +%s)"
    if ! "${DOCKER_BIN}" build -t "${IMG}" "${DOCKER_BUILD_DIR}"; then
        err "docker build failed. Re-applying the egress kill before exiting (never leave the kill removed)."
        apply_kill_on_chain "${chain}"
        trap - EXIT INT TERM HUP
        CURRENT_KILL_CHAIN=""
        exit 1
    fi
    build_end="$(date +%s)"
    build_seconds=$((build_end - build_start))
    log "docker build of ${IMG} completed in ${build_seconds}s."

    log "re-applying the egress kill on ${chain}..."
    apply_kill_on_chain "${chain}"
    trap - EXIT INT TERM HUP
    CURRENT_KILL_CHAIN=""

    PROBE_IMAGE="${IMG}"
    if ! verify_egress; then
        exit 1
    fi

    write_last_probe_file "build-image"

    log "build-image: OK. ${IMG} built in ${build_seconds}s, positive control confirmed the probe can see a real leak, egress kill re-verified on ${chain}."
}

# Positive control (proves the probe can detect a real leak) immediately
# followed by the negative control (proves the wall stops it). Requires
# colima/docker already up — never starts colima, never leaves the wall down.
cmd_selftest() {
    if ! "${DOCKER_BIN}" info >/dev/null 2>&1; then
        err "docker daemon is not reachable. Run 'ensure' first (selftest does not start colima itself)."
        exit 1
    fi

    local chain
    chain="$(detect_chain)"

    PROBE_IMAGE="$(select_probe_image)"

    log "selftest: removing the egress kill on ${chain} to run the positive control..."
    CURRENT_KILL_CHAIN="${chain}"
    # H6 fix (proof-check-2026-09-03.md): trap every signal that can end
    # this process during the wall-down window, not just normal EXIT.
    trap trap_reapply_kill EXIT INT TERM HUP
    remove_kill_on_chain "${chain}"

    local pc_failed=0
    positive_control_probe || pc_failed=1

    log "selftest: re-applying the egress kill on ${chain}..."
    apply_kill_on_chain "${chain}"
    trap - EXIT INT TERM HUP
    CURRENT_KILL_CHAIN=""

    if [ "${pc_failed}" -ne 0 ]; then
        err "selftest FAILED at the positive control. The egress kill has been re-applied; refusing to proceed."
        exit 1
    fi

    log "selftest: egress kill is back on ${chain} — both probes must now report BLOCKED..."
    if ! verify_egress; then
        exit 1
    fi

    write_last_probe_file "selftest"

    log "selftest: OK — probe can detect a leak and the wall stops it"
}

cmd_stop() {
    "${COLIMA_BIN}" stop
    if "${DOCKER_BIN}" info >/dev/null 2>&1; then
        err "docker info still succeeds after 'colima stop' — the VM does not appear to have stopped cleanly."
        exit 1
    fi
    log "stop: OK. colima is stopped and the docker daemon is no longer reachable."
}

cmd_status() {
    if "${COLIMA_BIN}" status >/dev/null 2>&1; then
        log "colima: running"
        local colima_up=1
    else
        log "colima: not running"
        local colima_up=0
    fi

    if "${DOCKER_BIN}" info >/dev/null 2>&1; then
        log "docker daemon: reachable"
    else
        log "docker daemon: not reachable"
    fi

    if [ "${colima_up}" -eq 1 ]; then
        local chain rule_line
        chain="$(detect_chain)"
        rule_line="$("${COLIMA_BIN}" ssh -- sudo iptables -S "${chain}" 2>/dev/null | grep -- '-j DROP' || true)"
        if [ -n "${rule_line}" ]; then
            log "egress-kill rule (${chain}): PRESENT — ${rule_line}"
        else
            log "egress-kill rule (${chain}): ABSENT"
        fi
    else
        log "egress-kill rule: cannot check (colima is not running, no VM to inspect)"
    fi

    if "${DOCKER_BIN}" image inspect "${IMG}" >/dev/null 2>&1; then
        log "image ${IMG}: present"
    else
        log "image ${IMG}: absent"
    fi

    if [ -f "${LAST_PROBE_FILE}" ]; then
        log "last probe results (${LAST_PROBE_FILE}):"
        local line
        while IFS= read -r line; do
            log "  ${line}"
        done < "${LAST_PROBE_FILE}"
    else
        log "last probe results: none recorded yet (run ensure/selftest/build-image)"
    fi
}

main() {
    local arg
    for arg in "$@"; do
        if [ "${arg}" = "--engine" ]; then
            log "fallback not enabled in this pilot"
            exit 2
        fi
    done

    case "${1:-}" in
        ensure)
            cmd_ensure
            ;;
        build-image)
            cmd_build_image
            ;;
        selftest)
            cmd_selftest
            ;;
        stop)
            cmd_stop
            ;;
        status)
            cmd_status
            ;;
        *)
            usage
            exit 64
            ;;
    esac
}

main "$@"
