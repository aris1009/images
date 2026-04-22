FROM docker.io/library/node:22-slim@sha256:d415caac2f1f77b98caaf9415c5f807e14bc8d7bdea62561ea2fef4fbd08a73c

ARG VERSION

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git ca-certificates \
        curl jq \
        dnsutils iputils-ping netcat-openbsd \
        ripgrep && \
    rm -rf /var/lib/apt/lists/*

RUN npm install -g "@anthropic-ai/claude-code@${VERSION}"

# The dispatcher (claude-runner-api-rs) runs jobs as non-root so the Claude
# CLI's --dangerously-skip-permissions guard is satisfied, and bind-mounts
# credentials at $HOME/.claude. node:22-slim ships a `node` user at UID 1000,
# which matches the host keep user under --userns=keep-id.
ENV HOME=/home/node
USER node
WORKDIR /home/node

ENTRYPOINT ["claude"]
