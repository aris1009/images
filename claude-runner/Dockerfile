FROM docker.io/library/node:24-slim@sha256:ba849c60be29959425b8734d57b8b4b7d56f98edd9504c9af091d5281095a71e

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
