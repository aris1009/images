# Claude Code for authorised offensive security assessment.
#
# Contains:
#   1. Offensive toolbelt (openssl, python3 + requests/pyjwt, socat, interactsh-client)
#   2. No pip, no build tooling, no sudo in the final image
#
# Deliberately absent: sudo, iptables, ipset, NET_ADMIN tooling. Containment belongs
# to the gateway, intended to run inside an egress cage.

ARG BASE=docker.io/library/node:26-slim@sha256:abe7e5a82b61a8ef67b315b85497c9e65173387ccf2f4a029248184b8e020be5

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
# stage: interactsh — built from source at the pinned tag, binary only.
#
# Built rather than downloaded because the published v1.4.1 binary carries
# golang.org/x/crypto v0.55.0, x/net v0.57.0 and klauspost/compress v1.18.2,
# which current advisory data still flags. The go.mod overrides below clear
# them; the same module set is used in gluetun/Dockerfile.
#
# Integrity: a tag can be moved, so the clone is checked against the tag's
# commit SHA. That replaces the release-archive checksums this stage used to
# verify.
# ---------------------------------------------------------------------------
FROM docker.io/library/golang:1.27-alpine3.23@sha256:8a5046497cda39860b832ffdbe8dd66018a0f05bb01352f533a36e7e2ced66a0 AS interactsh

ARG INTERACTSH_VERSION=1.4.1
ARG INTERACTSH_COMMIT=a5b78b2f1d990cd18c85cc422f0e651cf204c464

RUN apk add --no-cache git ca-certificates
WORKDIR /src
RUN set -eu; \
    git clone --depth=1 --branch "v${INTERACTSH_VERSION}" \
      https://github.com/projectdiscovery/interactsh .; \
    test "$(git rev-parse HEAD)" = "${INTERACTSH_COMMIT}"; \
    go get golang.org/x/crypto@v0.59.0 golang.org/x/net@v0.63.0 \
           golang.org/x/text@v0.44.0 github.com/klauspost/compress@v1.20.5; \
    CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" \
      -o /out/interactsh-client ./cmd/interactsh-client; \
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

# npm 11.20.0, which node 26.13.1 ships, bundles undici 6.28.0 and
# brace-expansion 5.0.9 — both below their fixed releases and not replaceable
# by a base-image bump, because every current node 26 build carries the same
# npm. Installing npm 12.2.3 brings undici 6.29.1 and brace-expansion 5.0.12.
# Its engines field is ^22.22.2 || ^24.15.0 || >=26.0.0, so node 26 qualifies.
RUN npm install -g --no-fund --no-audit npm@12.2.3

RUN npm install -g "@anthropic-ai/claude-code@${VERSION}"

COPY --from=pydeps /pydeps /opt/pydeps
COPY --from=interactsh /out/interactsh-client /usr/local/bin/interactsh-client

ENV PYTHONPATH=/opt/pydeps
ENV HOME=/home/node

USER node
WORKDIR /home/node

ENTRYPOINT ["claude"]
