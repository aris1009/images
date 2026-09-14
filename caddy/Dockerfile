FROM docker.io/library/caddy:2.11.4-builder@sha256:f2b98918658f949a3c533f2c73bd0806e3f2576ccf8eb182c8b1690c977007ea AS builder
RUN xcaddy build \
    --with github.com/caddy-dns/cloudflare@v0.2.4 \
    --with github.com/mholt/caddy-ratelimit@v0.1.0 \
    --with github.com/corazawaf/coraza-caddy/v2@v2.6.1

FROM docker.io/library/caddy:2.11.4@sha256:13ba145cba2f3e28fa801994876e4c086d1b95d5aa2a520a734765ffb6b12017
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
