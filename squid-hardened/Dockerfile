# Pinned by digest (Renovate bumps this digest and VERSION together).
# Multi-arch index: linux/amd64 + linux/arm64.
FROM docker.io/library/alpine:3.24.4@sha256:f59abe656b692d901e184be3445e084786602108599d2a51d229c0f5a48c71bf AS builder
ARG VERSION
# sha512 of the SQUID_7_8 GitHub archive. It is identical to the hash Alpine's
# aports recipe publishes for squid-7.8.tar.gz, so two independent packaging
# recipes agree on the bytes. Upstream does not sign GitHub archive tarballs;
# this hash is the trust anchor, and it is the only thing that pins the source
# when VERSION moves.
ARG SQUID_SHA512=db2a9490f8313062f1cbcdac8c225686027c43d9810a8cb02fab46be18e44b2fedbd3b2cfab1ece00e26727629f02c97a4810a1d3145edd007f6cb8660186854
# Reproducibility: fixed to the 7.8 release date, not to build time.
ENV SOURCE_DATE_EPOCH=1793318400

WORKDIR /build
RUN apk add --no-cache build-base autoconf automake libtool linux-headers openssl-dev pkgconf curl

RUN set -eux; \
    curl -fsSLo squid.tar.gz "https://github.com/squid-cache/squid/archive/refs/tags/SQUID_${VERSION//./_}.tar.gz"; \
    echo "${SQUID_SHA512}  squid.tar.gz" | sha512sum -c -; \
    mkdir squid; \
    tar -xzf squid.tar.gz -C squid --strip-components=1; \
    rm squid.tar.gz

WORKDIR /build/squid
# The release archive carries no generated configure script.
RUN autoreconf -fiv

# Feature set: a forward proxy with caching and TLS libraries, and nothing that
# executes another program. Every helper family is compiled out, so no mounted
# configuration can turn into command execution. See README.md for the full
# in/out list and the rationale.
#
# Two upstream quirks are worked around here, both verified against the 7.8
# source rather than assumed:
#   * OpenSSL is OFF by default. SQUID_OPTIONAL_LIB sets with_openssl=no unless
#     --with-openssl is given, and detection needs pkgconf, hence both below.
#   * --enable-storeio=<list> and --enable-disk-io=<list> do not restrict the
#     build: SQUID_LOOK_FOR_MODULES() resets the candidate list and enumerates
#     every directory, so all four store modules and all DiskIO modules are
#     always compiled in. The flags below state the intent and will start
#     working if upstream fixes the macro. The only executable that results is
#     the diskd daemon, which is removed below with the rest of /usr/lib/squid.
RUN set -euxo pipefail; \
    CFLAGS="-O2 -pipe -fstack-protector-strong -fstack-clash-protection -D_FORTIFY_SOURCE=2 -fPIE" \
    CXXFLAGS="-O2 -pipe -fstack-protector-strong -fstack-clash-protection -D_FORTIFY_SOURCE=2 -fPIE" \
    LDFLAGS="-Wl,-z,relro,-z,now -pie" \
    ./configure \
      --prefix=/usr \
      --sysconfdir=/etc/squid \
      --datadir=/usr/share/squid \
      --libexecdir=/usr/lib/squid \
      --localstatedir=/var \
      --with-default-user=squid \
      --with-openssl \
      --enable-storeio=ufs \
      --enable-disk-io=Blocking \
      --without-nettle \
      --disable-auth \
      --disable-auth-basic \
      --disable-auth-digest \
      --disable-auth-negotiate \
      --disable-auth-ntlm \
      --disable-icap-client \
      --disable-ecap \
      --disable-wccp \
      --disable-wccpv2 \
      --disable-snmp \
      --disable-htcp \
      --disable-eui \
      --disable-delay-pools \
      --disable-cache-digests \
      --disable-forw-via-db \
      --disable-ipfw-transparent \
      --disable-ipf-transparent \
      --disable-pf-transparent \
      --disable-linux-netfilter \
      --disable-log-daemon-helpers \
      --disable-external-acl-helpers \
      --disable-url-rewrite-helpers \
      --disable-storeid-rewrite-helpers \
      --disable-security-cert-validators \
      --disable-security-cert-generators \
      --disable-ident-lookups \
      --disable-unlinkd \
      --disable-arch-native \
      --disable-strict-error-checking \
      --disable-translation \
      --disable-auto-locale \
      --disable-x-accelerator-vary \
      2>&1 | tee /tmp/configure.log; \
    if grep -q "unrecognized options" /tmp/configure.log; then \
      echo "ERROR: configure rejected an option; fix the Dockerfile" >&2; \
      exit 1; \
    fi; \
    make -j"$(nproc)"; \
    make install DESTDIR=/out

# Health probe: the runtime has no shell, so the check is a static binary that
# connects to the listener, sends one minimal HTTP request and expects any
# answer (403 or 503 under a deny-by-default policy is healthy).
#
# `make install` here produces exactly two executables in /usr/lib/squid:
# `helper-mux` (the launcher for external helpers; there are none to launch) and
# `diskd` (the DiskDaemon store helper, which upstream compiles in regardless of
# --enable-storeio). Both are listed explicitly, anything else fails the build,
# and the whole directory is then removed so the runtime has no helper to exec.
COPY probe.c /build/probe.c
RUN set -eux; \
    if find /out/usr/lib/squid -type f -perm -u+x \
         ! -name helper-mux ! -name diskd | grep -q .; then \
      echo "ERROR: unexpected helper binaries were built" >&2; \
      find /out/usr/lib/squid -type f -perm -u+x >&2; \
      exit 1; \
    fi; \
    rm -rf /out/usr/lib/squid; \
    mkdir -p /out/usr/local/bin; \
    cc -O2 -static -s -o /out/usr/local/bin/squid-probe /build/probe.c

FROM docker.io/library/alpine:3.24.4@sha256:f59abe656b692d901e184be3445e084786602108599d2a51d229c0f5a48c71bf AS runtime
ARG VERSION

LABEL \
    org.opencontainers.image.source="https://github.com/aris1009/images" \
    org.opencontainers.image.title="squid-hardened" \
    org.opencontainers.image.description="Hardened Squid forward proxy: shell-less, non-root, no helper binaries, no interception or transparent modes. Configure by mounting /etc/squid/squid.conf or drop-ins in /etc/squid/conf.d/; the shipped default denies everything." \
    org.opencontainers.image.version=$VERSION \
    org.opencontainers.image.licenses="GPL-2.0-or-later"

RUN set -eux; \
    apk add --no-cache libssl3 libcrypto3 libstdc++ libltdl; \
    addgroup -S -g 1000 squid; \
    adduser -S -D -H -u 1000 -G squid -s /sbin/nologin squid; \
    rm -rf /var/cache/apk /etc/apk /lib/apk /var/lib/apk

COPY --from=builder /out/usr/sbin/squid /usr/sbin/squid
COPY --from=builder /out/usr/share/squid /usr/share/squid
COPY --from=builder /out/usr/local/bin/squid-probe /usr/local/bin/squid-probe
# mime.conf is mandatory (Squid exits FATAL without it); errorpage.css is what
# the generated error pages reference. The .default/.documented copies are left
# behind: the configuration reference lives upstream.
COPY --from=builder /out/etc/squid/mime.conf /etc/squid/mime.conf
COPY --from=builder /out/etc/squid/errorpage.css /etc/squid/errorpage.css
COPY squid.conf /etc/squid/squid.conf
# The include glob in squid.conf is fatal when it matches nothing, so the image
# ships conf.d/10-recommended.conf: upstream's deny-only access guards. It also
# gives the deployer a numbered reference for their own drop-ins.
COPY conf.d/ /etc/squid/conf.d/
COPY COPYING /usr/share/licenses/squid-hardened/COPYING

# No shell and no package manager: after code execution there is no interpreter
# to pivot to. Must stay the last RUN, because every later instruction is
# exec-form or metadata only.
RUN set -eux; \
    /bin/busybox rm -f /sbin/apk /usr/sbin/apk; \
    /bin/busybox find /bin /sbin /usr/bin /usr/sbin -type l -delete; \
    /bin/busybox rm -f /bin/busybox; \
    test ! -e /bin/sh

USER 1000:1000
EXPOSE 3128
STOPSIGNAL SIGTERM
# No HEALTHCHECK instruction: this pipeline publishes OCI manifests, which have
# no field for it (podman warns and drops it). The probe binary is shipped
# instead, and the runtime configures it: see "Health check" in README.md.
CMD ["/usr/sbin/squid","-N","-f","/etc/squid/squid.conf"]
