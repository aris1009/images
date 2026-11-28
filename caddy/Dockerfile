FROM docker.io/library/caddy:2.11.9-builder@sha256:cda07fe9d82728c7ac44d844306d435e98131423dc7b114f05a8a8ecfff94707 AS builder
# Caddy 2.11.9's go.mod pins golang.org/x/net v0.60.0. Lift it to v0.63.0 in
# the build. Verified: the resulting binary reports golang.org/x/net v0.63.0
# and builds all three plugins.
RUN xcaddy build \
    --with github.com/caddy-dns/cloudflare@v0.2.4 \
    --with github.com/mholt/caddy-ratelimit@v0.1.0 \
    --with github.com/corazawaf/coraza-caddy/v2@v2.6.2 \
    --replace golang.org/x/net=golang.org/x/net@v0.63.0

FROM docker.io/library/caddy:2.11.9@sha256:4851e54a46b206517c574821bb5cc67f170d2156041e9fbc4c9193b45e84a75b
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
