FROM docker.io/library/node:24-slim@sha256:a5f4366e834695d5f363b920c104953a535d3a9864d1bdf74566a0ebe01daee5

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
