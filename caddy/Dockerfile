FROM docker.io/library/caddy:2.11.6-builder@sha256:f5b1a66449d305280e559dba0ab9f7ce9a2a14c527c79d7c6fb48abc8f895818 AS builder
RUN xcaddy build \
    --with github.com/caddy-dns/cloudflare@v0.2.4 \
    --with github.com/mholt/caddy-ratelimit@v0.1.0 \
    --with github.com/corazawaf/coraza-caddy/v2@v2.6.2

FROM docker.io/library/caddy:2.11.7@sha256:504a44d7d74bd2bc28a66afc4774912fc21223ca8a67734af1c54ab2f999b489
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
