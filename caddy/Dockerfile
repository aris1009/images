FROM docker.io/library/caddy:2.11.2-builder@sha256:10ed0251c5cd1dbb4db0b71ad43121147961a51adfec35febce2c93ea25c24f4 AS builder
RUN xcaddy build \
    --with github.com/caddy-dns/cloudflare@v0.2.4 \
    --with github.com/mholt/caddy-ratelimit@v0.1.0

FROM docker.io/library/caddy:2.11.2@sha256:25cdc846626b62d05f6b633b9b40c2c9f6ef89b515dc76133cefd920f7dbe562
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
