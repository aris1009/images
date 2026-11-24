FROM docker.io/library/node:26-slim@sha256:e4db4c914bf8ad241bd24804fc25d272d89bad97e68cdc8a1414862790a02c39

ARG VERSION

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git ca-certificates \
        curl jq \
        dnsutils iputils-ping netcat-openbsd \
        ripgrep && \
    rm -rf /var/lib/apt/lists/*

# npm 11.20.0, which node 26-slim ships, bundles undici 6.28.0 and
# brace-expansion 5.0.9. npm 12.2.3 brings undici 6.29.1 and brace-expansion
# 5.0.12. Same step as offsec-claude/Dockerfile, whose SBOM already carries the
# newer pair.
RUN npm install -g --no-fund --no-audit npm@12.2.3

RUN npm install -g "@anthropic-ai/claude-code@${VERSION}"

ENV HOME=/home/node
USER node
WORKDIR /home/node

ENTRYPOINT ["claude"]
