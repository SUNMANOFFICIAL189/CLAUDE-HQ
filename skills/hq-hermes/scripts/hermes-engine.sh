#!/usr/bin/env bash
# hermes-engine.sh — headless colima/docker engine helper for the hq-hermes pilot.
#
# Subcommands:
#   ensure       start colima (if not running), wait for docker, apply the VM-level
#                egress kill, verify it with two fail-closed probes.
#   build-image  temporarily lift the egress kill, build $IMG, re-apply the kill,
#                re-verify with the two probes.
#   stop         colima stop; verify docker is no longer reachable.
#   status       one-line report: colima / docker / egress-kill rule / image.
#   --engine docker-desktop   NOT implemented in this pilot (Docker Desktop must
#                             never be started here). Prints a message, exit 2.
#
# Rules followed: no eval, all variable expansions quoted, binaries resolved
# once (absolute paths) at the top, plain-English messages, fail closed on any
# egress-kill verification ambiguity.

set -euo pipefail

# ---- resolved binaries (once) ------------------------------------------------
readonly COLIMA_BIN="/opt/homebrew/bin/colima"
DOCKER_BIN="$(command -v docker)"
readonly DOCKER_BIN

# ---- constants ----------------------------------------------------------------
readonly IMG="hermes-pilot:v1"
readonly PROBE_FALLBACK_IMG="python:3.11-slim"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
SK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly SK_DIR
readonly DOCKER_BUILD_DIR="${SK_DIR}/docker"
readonly DOCKER_INFO_WAIT_SECS=90

log() {
    printf '[hermes-engine] %s\n' "$*"
}

err() {
    printf '[hermes-engine] ERROR: %s\n' "$*" >&2
}

usage() {
    cat <<'EOF'
Usage: hermes-engine.sh <ensure|build-image|stop|status>
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

# Picks the image to run the egress probes against: the pilot's own pinned
# image if it exists yet, otherwise python:3.11-slim (documented fallback for
# the first run, before hermes-pilot:v1 has been built).
select_probe_image() {
    if "${DOCKER_BIN}" image inspect "${IMG}" >/dev/null 2>&1; then
        printf '%s' "${IMG}"
    else
        log "NOTE: image ${IMG} does not exist yet (first run) — using ${PROBE_FALLBACK_IMG} for the egress probe instead." 1>&2
        printf '%s' "${PROBE_FALLBACK_IMG}"
    fi
}

# Runs the two egress probes against the given image. Fails closed: any
# outcome other than BLOCKED on both probes is treated as a verification
# failure and returns non-zero with a plain-English reason.
verify_egress() {
    local probe_image="$1"
    local out1 out2

    out1="$("${DOCKER_BIN}" run --rm "${probe_image}" sh -c 'timeout 5 wget -qO- http://1.1.1.1 >/dev/null 2>&1 && echo LEAK || echo BLOCKED')"
    log "probe 1/2 (public internet, http://1.1.1.1) using ${probe_image}: ${out1}"

    out2="$("${DOCKER_BIN}" run --rm "${probe_image}" sh -c 'timeout 5 wget -qO- http://host.docker.internal:11434 >/dev/null 2>&1 && echo LEAK || echo BLOCKED')"
    log "probe 2/2 (host Ollama, http://host.docker.internal:11434) using ${probe_image}: ${out2}"

    if [ "${out1}" != "BLOCKED" ] || [ "${out2}" != "BLOCKED" ]; then
        err "egress-kill verification FAILED. Container network egress is not reliably contained (probe1=${out1}, probe2=${out2}). Refusing to proceed."
        return 1
    fi

    log "egress-kill verification OK: both probes report BLOCKED."
    return 0
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

    local probe_image
    probe_image="$(select_probe_image)"

    if ! verify_egress "${probe_image}"; then
        exit 1
    fi

    log "ensure: OK. colima is up, docker is reachable, egress kill verified on ${chain}."
}

cmd_build_image() {
    if ! "${DOCKER_BIN}" info >/dev/null 2>&1; then
        err "docker daemon is not reachable. Run 'ensure' first."
        exit 1
    fi

    local chain
    chain="$(detect_chain)"

    log "temporarily removing the egress kill on ${chain} so the build can reach the registry/daemon..."
    remove_kill_on_chain "${chain}"

    local build_start build_end build_seconds
    build_start="$(date +%s)"
    if ! "${DOCKER_BIN}" build -t "${IMG}" "${DOCKER_BUILD_DIR}"; then
        err "docker build failed. Re-applying the egress kill before exiting (never leave the kill removed)."
        apply_kill_on_chain "${chain}"
        exit 1
    fi
    build_end="$(date +%s)"
    build_seconds=$((build_end - build_start))
    log "docker build of ${IMG} completed in ${build_seconds}s."

    log "re-applying the egress kill on ${chain}..."
    apply_kill_on_chain "${chain}"

    if ! verify_egress "${IMG}"; then
        exit 1
    fi

    log "build-image: OK. ${IMG} built in ${build_seconds}s, egress kill re-verified on ${chain}."
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
