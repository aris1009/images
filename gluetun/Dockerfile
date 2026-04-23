ARG VERSION

FROM docker.io/library/golang:1.25-alpine3.23@sha256:5caaf1cca9dc351e13deafbc3879fd4754801acba8653fa9540cea125d01a71f AS build
ARG VERSION
RUN apk add --no-cache git ca-certificates
WORKDIR /src
RUN git clone --depth=1 --branch "${VERSION}" https://github.com/qdm12/gluetun .
RUN set -eu; \
    COMMIT=$(git rev-parse --short HEAD); \
    CREATED=$(date -u +%Y-%m-%dT%H:%M:%SZ); \
    CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -trimpath -ldflags="-s -w \
      -X 'main.version=${VERSION}' \
      -X 'main.created=${CREATED}' \
      -X 'main.commit=${COMMIT}'" \
      -o /gluetun-entrypoint cmd/gluetun/main.go

FROM docker.io/library/alpine:3.23@sha256:5b10f432ef3da1b8d4c7eb6c487f2f5a8f096bc91145e68878dd4a5019afde11
ARG VERSION
LABEL \
    org.opencontainers.image.source="https://github.com/aris1009/images" \
    org.opencontainers.image.documentation="https://github.com/qdm12/gluetun" \
    org.opencontainers.image.title="gluetun (built from source by aris1009/images)" \
    org.opencontainers.image.description="VPN client rebuilt from pinned qdm12/gluetun source; cosign keyless signed + SLSA provenance + SBOM." \
    org.opencontainers.image.version=$VERSION \
    org.opencontainers.image.licenses="MIT"
ENV VPN_SERVICE_PROVIDER=pia \
    VPN_TYPE=openvpn \
    VPN_INTERFACE=tun0 \
    OPENVPN_ENDPOINT_IP= \
    OPENVPN_ENDPOINT_PORT= \
    OPENVPN_PROTOCOL=udp \
    OPENVPN_USER= \
    OPENVPN_PASSWORD= \
    OPENVPN_USER_SECRETFILE=/run/secrets/openvpn_user \
    OPENVPN_PASSWORD_SECRETFILE=/run/secrets/openvpn_password \
    OPENVPN_VERSION=2.6 \
    OPENVPN_VERBOSITY=1 \
    OPENVPN_FLAGS= \
    OPENVPN_CIPHERS= \
    OPENVPN_AUTH= \
    OPENVPN_PROCESS_USER=root \
    OPENVPN_MSSFIX= \
    OPENVPN_CUSTOM_CONFIG= \
    WIREGUARD_ENDPOINT_IP= \
    WIREGUARD_ENDPOINT_PORT= \
    WIREGUARD_CONF_SECRETFILE=/run/secrets/wg0.conf \
    WIREGUARD_PRIVATE_KEY= \
    WIREGUARD_PRIVATE_KEY_SECRETFILE=/run/secrets/wireguard_private_key \
    WIREGUARD_PRESHARED_KEY= \
    WIREGUARD_PRESHARED_KEY_SECRETFILE=/run/secrets/wireguard_preshared_key \
    WIREGUARD_PUBLIC_KEY= \
    WIREGUARD_ALLOWED_IPS= \
    WIREGUARD_PERSISTENT_KEEPALIVE_INTERVAL=0 \
    WIREGUARD_ADDRESSES= \
    WIREGUARD_ADDRESSES_SECRETFILE=/run/secrets/wireguard_addresses \
    WIREGUARD_MTU=1320 \
    WIREGUARD_IMPLEMENTATION=auto \
    SERVER_REGIONS= \
    SERVER_COUNTRIES= \
    SERVER_CITIES= \
    SERVER_HOSTNAMES= \
    SERVER_CATEGORIES= \
    ISP= \
    OWNED_ONLY=no \
    PRIVATE_INTERNET_ACCESS_OPENVPN_ENCRYPTION_PRESET= \
    VPN_PORT_FORWARDING=off \
    VPN_PORT_FORWARDING_LISTENING_PORT=0 \
    VPN_PORT_FORWARDING_PROVIDER= \
    VPN_PORT_FORWARDING_STATUS_FILE="/tmp/gluetun/forwarded_port" \
    VPN_PORT_FORWARDING_USERNAME= \
    VPN_PORT_FORWARDING_PASSWORD= \
    VPN_PORT_FORWARDING_UP_COMMAND= \
    VPN_PORT_FORWARDING_DOWN_COMMAND= \
    OPENVPN_CERT= \
    OPENVPN_KEY= \
    OPENVPN_CLIENTCRT_SECRETFILE=/run/secrets/openvpn_clientcrt \
    OPENVPN_CLIENTKEY_SECRETFILE=/run/secrets/openvpn_clientkey \
    OPENVPN_ENCRYPTED_KEY= \
    OPENVPN_ENCRYPTED_KEY_SECRETFILE=/run/secrets/openvpn_encrypted_key \
    OPENVPN_KEY_PASSPHRASE= \
    OPENVPN_KEY_PASSPHRASE_SECRETFILE=/run/secrets/openvpn_key_passphrase \
    SERVER_NUMBER= \
    SERVER_NAMES= \
    STREAM_ONLY= \
    FREE_ONLY= \
    SECURE_CORE_ONLY= \
    TOR_ONLY= \
    MULTIHOP_ONLY= \
    PREMIUM_ONLY= \
    PORT_FORWARD_ONLY= \
    FIREWALL_ENABLED_DISABLING_IT_SHOOTS_YOU_IN_YOUR_FOOT=on \
    FIREWALL_VPN_INPUT_PORTS= \
    FIREWALL_INPUT_PORTS= \
    FIREWALL_OUTBOUND_SUBNETS= \
    FIREWALL_DEBUG=off \
    LOG_LEVEL=info \
    HEALTH_SERVER_ADDRESS=127.0.0.1:9999 \
    HEALTH_TARGET_ADDRESSES=cloudflare.com:443,github.com:443 \
    HEALTH_ICMP_TARGET_IPS=1.1.1.1,8.8.8.8 \
    HEALTH_SMALL_CHECK_TYPE=icmp \
    HEALTH_RESTART_VPN=on \
    DNS_SERVER=on \
    DNS_UPSTREAM_RESOLVER_TYPE=DoT \
    DNS_UPSTREAM_RESOLVERS=cloudflare \
    DNS_BLOCK_IPS= \
    DNS_BLOCK_IP_PREFIXES= \
    DNS_CACHING=on \
    DNS_UPSTREAM_IPV6=off \
    BLOCK_MALICIOUS=on \
    BLOCK_SURVEILLANCE=off \
    BLOCK_ADS=off \
    DNS_UNBLOCK_HOSTNAMES= \
    DNS_REBINDING_PROTECTION_EXEMPT_HOSTNAMES= \
    DNS_UPDATE_PERIOD=24h \
    DNS_ADDRESS=127.0.0.1 \
    DNS_KEEP_NAMESERVER=off \
    HTTPPROXY= \
    HTTPPROXY_LOG=off \
    HTTPPROXY_LISTENING_ADDRESS=":8888" \
    HTTPPROXY_STEALTH=off \
    HTTPPROXY_USER= \
    HTTPPROXY_PASSWORD= \
    HTTPPROXY_USER_SECRETFILE=/run/secrets/httpproxy_user \
    HTTPPROXY_PASSWORD_SECRETFILE=/run/secrets/httpproxy_password \
    SHADOWSOCKS=off \
    SHADOWSOCKS_LOG=off \
    SHADOWSOCKS_LISTENING_ADDRESS=":8388" \
    SHADOWSOCKS_PASSWORD= \
    SHADOWSOCKS_PASSWORD_SECRETFILE=/run/secrets/shadowsocks_password \
    SHADOWSOCKS_CIPHER=chacha20-ietf-poly1305 \
    HTTP_CONTROL_SERVER_LOG=on \
    HTTP_CONTROL_SERVER_ADDRESS=":8000" \
    HTTP_CONTROL_SERVER_AUTH_CONFIG_FILEPATH=/gluetun/auth/config.toml \
    HTTP_CONTROL_SERVER_AUTH_DEFAULT_ROLE="{}" \
    UPDATER_PERIOD=0 \
    UPDATER_MIN_RATIO=0.8 \
    UPDATER_VPN_SERVICE_PROVIDERS= \
    UPDATER_PROTONVPN_EMAIL= \
    UPDATER_PROTONVPN_PASSWORD= \
    PUBLICIP_FILE="/tmp/gluetun/ip" \
    PUBLICIP_ENABLED=on \
    PUBLICIP_API=ipinfo,ifconfigco,ip2location,cloudflare \
    PUBLICIP_API_TOKEN= \
    STORAGE_FILEPATH=/gluetun/servers.json \
    PPROF_ENABLED=no \
    PPROF_BLOCK_PROFILE_RATE=0 \
    PPROF_MUTEX_PROFILE_RATE=0 \
    PPROF_HTTP_SERVER_ADDRESS=":6060" \
    VERSION_INFORMATION=on \
    TZ= \
    PUID=1000 \
    PGID=1000
ENTRYPOINT ["/gluetun-entrypoint"]
EXPOSE 8000/tcp 8888/tcp 8388/tcp 8388/udp
HEALTHCHECK --interval=5s --timeout=5s --start-period=10s --retries=3 CMD /gluetun-entrypoint healthcheck
# Runtime deps — mirror upstream qdm12/gluetun Dockerfile so behavior stays identical.
# OpenVPN 2.5 is pulled from Alpine v3.17 and kept alongside 2.6 so users with
# OPENVPN_VERSION=2.5 still work. This exact dance is upstream's and must stay in sync.
RUN apk add --no-cache --update -l wget && \
    apk add --no-cache --update -X "https://dl-cdn.alpinelinux.org/alpine/v3.17/main" openvpn~2.5 && \
    mv /usr/sbin/openvpn /usr/sbin/openvpn2.5 && \
    apk del openvpn && \
    apk add --no-cache --update openvpn ca-certificates iptables iptables-legacy tzdata && \
    mv /usr/sbin/openvpn /usr/sbin/openvpn2.6 && \
    rm -rf /var/cache/apk/* /etc/openvpn/*.sh /usr/lib/openvpn/plugins/openvpn-plugin-down-root.so && \
    deluser openvpn && \
    mkdir /gluetun
COPY --from=build /gluetun-entrypoint /gluetun-entrypoint
