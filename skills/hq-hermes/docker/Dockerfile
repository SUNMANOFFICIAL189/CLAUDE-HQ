# hq-hermes pilot worker image.
# Base pinned by digest (not just tag) — captured via:
#   docker image inspect python:3.11-slim --format '{{index .RepoDigests 0}}'
# on 2026-09-03 against the colima VM's docker daemon.
FROM python:3.11-slim@sha256:9534e5a8e315485d4061ed659af0fd78a284c015f9b73661b41d6bab25604534

RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        shellcheck \
        ripgrep \
        jq \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --uid 10001 --create-home --shell /usr/sbin/nologin worker

USER worker
WORKDIR /work
