# Claude Code for authorised offensive security assessment.
#
# Contains:
#   1. Offensive toolbelt (openssl, python3 + requests/pyjwt, socat, interactsh-client)
#   2. No pip, no build tooling, no sudo in the final image
#
# Deliberately absent: sudo, iptables, ipset, NET_ADMIN tooling. Containment belongs
# to the gateway, intended to run inside an egress cage.

ARG BASE=docker.io/library/node:24-slim@sha256:ba849c60be29959425b8734d57b8b4b7d56f98edd9504c9af091d5281095a71e

# ---------------------------------------------------------------------------
# stage: pydeps — resolve Python deps with hash verification.
# ---------------------------------------------------------------------------
FROM ${BASE} AS pydeps

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 python3-pip ca-certificates && \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt /tmp/requirements.txt

# --require-hashes: every distribution, including the full transitive closure,
# must match a pinned sha256 or the build fails. Never loosen this.
RUN python3 -m pip install \
        --no-cache-dir \
        --require-hashes \
        --no-deps \
        --break-system-packages \
        --target=/pydeps \
        -r /tmp/requirements.txt && \
    python3 -c "import sys; sys.path.insert(0,'/pydeps'); import requests, jwt; print(requests.__version__, jwt.__version__)"

# ---------------------------------------------------------------------------
# stage: interactsh — pinned release, checksum-verified, binary only.
# ---------------------------------------------------------------------------
FROM ${BASE} AS interactsh

ARG TARGETARCH
ARG INTERACTSH_VERSION=1.3.1
ARG INTERACTSH_SHA256_AMD64=d553fb3dd4c2684c953aedeb555f13f0d1ca94bd75112c949a5fd975d385a903
ARG INTERACTSH_SHA256_ARM64=475aa78c59afad115149a5b0d6d9c99d2410a4f12d0c6f5a24c32e7338fc6adb

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl unzip ca-certificates && \
    rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    case "${TARGETARCH}" in \
      amd64) sha="${INTERACTSH_SHA256_AMD64}" ;; \
      arm64) sha="${INTERACTSH_SHA256_ARM64}" ;; \
      *) echo "unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    f="interactsh-client_${INTERACTSH_VERSION}_linux_${TARGETARCH}.zip"; \
    curl -fsSL --retry 3 -o "/tmp/${f}" \
      "https://github.com/projectdiscovery/interactsh/releases/download/v${INTERACTSH_VERSION}/${f}"; \
    echo "${sha}  /tmp/${f}" | sha256sum -c -; \
    mkdir -p /out; \
    unzip -j -o "/tmp/${f}" interactsh-client -d /out; \
    chmod 0755 /out/interactsh-client; \
    /out/interactsh-client -version 2>&1 | head -1 || true

# ---------------------------------------------------------------------------
# final stage
# ---------------------------------------------------------------------------
FROM ${BASE}

ARG VERSION

# ripgrep  — Claude Code's search path; how the agent reads mounted source
# git      — reading target history on a read-only mount is intel
# openssl  — s_client, cert inspection, hashing; byte-level TLS work
# socat    — relays and listeners beyond netcat's reach
# netcat   — raw sockets; the capability the cage design preserves on purpose
# dnsutils — dig, for OOB verification and observing what the cage resolves
# jq       — for JSON & JSONL
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git ca-certificates \
        curl jq \
        dnsutils netcat-openbsd \
        openssl socat \
        python3 \
        ripgrep && \
    rm -rf /var/lib/apt/lists/*

RUN npm install -g "@anthropic-ai/claude-code@${VERSION}"

COPY --from=pydeps /pydeps /opt/pydeps
COPY --from=interactsh /out/interactsh-client /usr/local/bin/interactsh-client

ENV PYTHONPATH=/opt/pydeps
ENV HOME=/home/node

USER node
WORKDIR /home/node

ENTRYPOINT ["claude"]
