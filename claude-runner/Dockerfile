FROM docker.io/library/node:26-slim@sha256:5adad64f9a1fca2d51972caa65983634c8a774eb300d72b20f7f2a0f60368072

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
