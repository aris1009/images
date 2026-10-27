ARG VERSION
FROM docker.io/library/alpine:3.24@sha256:be2656061b536c1883c4034790e21d0a09c5aaaf51968b89368a3c0371ea2c9a
ARG VERSION

LABEL \
    org.opencontainers.image.source="https://github.com/aris1009/images" \
    org.opencontainers.image.title="file-scanner" \
    org.opencontainers.image.description="Generic ClamAV-backed file scanner (inotify pipelines, ntfy alerts). Client-only — clamd runs in a separate container." \
    org.opencontainers.image.version=$VERSION \
    org.opencontainers.image.licenses="MIT"

# clamav: provides clamdscan (client only)
# inotify-tools: inotifywait for filesystem event watching
# jq: JSON config parsing
# curl: ntfy push notifications
# netcat-openbsd: nc for clamd readiness probe
RUN apk add --no-cache \
    clamav \
    inotify-tools \
    jq \
    curl \
    netcat-openbsd

COPY scanner.sh /usr/local/bin/scanner.sh
RUN chmod +x /usr/local/bin/scanner.sh

ENTRYPOINT ["/usr/local/bin/scanner.sh"]
