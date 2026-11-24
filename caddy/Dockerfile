FROM docker.io/library/caddy:2.11.9-builder@sha256:345264d8c6b50f44f4a4d507d4e6b6bcae40eef2f210d70f76e717fd8cc31baf AS builder
# Caddy 2.11.9's go.mod pins golang.org/x/net v0.60.0. Lift it to v0.63.0 in
# the build. Verified: the resulting binary reports golang.org/x/net v0.63.0
# and builds all three plugins.
RUN xcaddy build \
    --with github.com/caddy-dns/cloudflare@v0.2.4 \
    --with github.com/mholt/caddy-ratelimit@v0.1.0 \
    --with github.com/corazawaf/coraza-caddy/v2@v2.6.2 \
    --replace golang.org/x/net=golang.org/x/net@v0.63.0

FROM docker.io/library/caddy:2.11.9@sha256:0c2243efcf437ab7f7a978f1027fcf0d4f9be8a75df27b1b3fbc5dbe0ffa8cf0
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
