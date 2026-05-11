FROM docker.io/library/node:22-slim@sha256:9f6d5975c7dca860947d3915877f85607946403fc55349f39b4bc3688448bb6e

ARG VERSION

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git ca-certificates \
        curl jq \
        dnsutils iputils-ping netcat-openbsd \
        ripgrep && \
    rm -rf /var/lib/apt/lists/*

RUN npm install -g "@anthropic-ai/claude-code@${VERSION}"

ENV HOME=/home/node
USER node
WORKDIR /home/node

ENTRYPOINT ["claude"]
