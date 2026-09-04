ARG VERSION
# Pinned by digest (Renovate bumps VERSION + this digest together).
FROM docker.io/library/haproxy:3.4-alpine@sha256:0878b11eb64c433be1b0f578a584b8aca12f6caaa64c8f239b8b556c0dd5eeeb
ARG VERSION

LABEL \
    org.opencontainers.image.source="https://github.com/aris1009/images" \
    org.opencontainers.image.title="haproxy-sni" \
    org.opencontainers.image.description="TLS-SNI egress allowlist (HAProxy mode tcp). Deny-by-default, no MITM/decrypt — reads the ClientHello SNI and routes allowlisted hosts to their real upstream, drops the rest. Mount allowlist.txt (one host/line); app reaches the proxy by DNS alias." \
    org.opencontainers.image.version=$VERSION \
    org.opencontainers.image.licenses="MIT"

USER root

COPY haproxy.cfg.base /usr/local/etc/haproxy/haproxy.cfg.base
COPY entrypoint.sh /usr/local/bin/sni-entrypoint.sh
# The allowlist is runtime configuration. Mount it:
#   volumes:
#     - ./allowlist.txt:/etc/haproxy/allowlist.txt:ro
# Absent or empty => deny ALL egress (fail closed).
RUN chmod +x /usr/local/bin/sni-entrypoint.sh

# Back to the unprivileged upstream default; no caps/iptables needed (the proxy
# dials named upstreams, it does not intercept). Compose publishes/aliases it.
USER haproxy

# 443 = the SNI gate the app connects to (via DNS alias of each allowed host).
EXPOSE 443

# Entrypoint generates /tmp/haproxy.cfg from allowlist.txt, then runs this CMD.
ENTRYPOINT ["/usr/local/bin/sni-entrypoint.sh"]
CMD ["haproxy", "-f", "/tmp/haproxy.cfg"]
