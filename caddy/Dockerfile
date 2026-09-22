FROM docker.io/library/caddy:2.11.4-builder@sha256:f2b98918658f949a3c533f2c73bd0806e3f2576ccf8eb182c8b1690c977007ea AS builder
RUN xcaddy build \
    --with github.com/caddy-dns/cloudflare@v0.2.4 \
    --with github.com/mholt/caddy-ratelimit@v0.1.0 \
    --with github.com/corazawaf/coraza-caddy/v2@v2.6.1

FROM docker.io/library/caddy:2.11.4@sha256:14a9c00d4e833ebc2b65d36515b37bde3b73f0b323a2663aaafc88953d8c4e3f
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
