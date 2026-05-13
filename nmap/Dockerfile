ARG VERSION

# Static-build stage. Alpine on amd64 is a musl-native environment, so anything
# compiled here against musl + the static deps below produces a fully static
# binary with no dynamic loader required at runtime.
FROM docker.io/library/alpine:3.23@sha256:5b10f432ef3da1b8d4c7eb6c487f2f5a8f096bc91145e68878dd4a5019afde11 AS build
ARG VERSION

RUN apk add --no-cache \
    build-base \
    linux-headers \
    perl \
    pkgconf \
    file \
    bash \
    flex \
    bison \
    autoconf \
    automake \
    libtool \
    curl \
    ca-certificates

# All deps install into /opt/static. nmap's configure is pointed at this prefix
# so it finds our static libs instead of any system copy.
ENV PREFIX=/opt/static
ENV PATH=$PREFIX/bin:$PATH
ENV PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig
ENV CFLAGS="-Os -fPIC -I/opt/static/include"
ENV CXXFLAGS="-Os -fPIC -I/opt/static/include"
ENV CPPFLAGS="-I/opt/static/include"
ENV LDFLAGS="-L/opt/static/lib"

WORKDIR /build

# ---- zlib (static) ----
ARG ZLIB_VERSION=1.3.1
ARG ZLIB_SHA256=9a93b2b7dfdac77ceba5a558a580e74667dd6fede4585b91eefb60f03b72df23
RUN curl -fsSL -o zlib.tar.gz "https://zlib.net/fossils/zlib-${ZLIB_VERSION}.tar.gz" \
    && echo "${ZLIB_SHA256}  zlib.tar.gz" | sha256sum -c - \
    && tar xf zlib.tar.gz \
    && cd "zlib-${ZLIB_VERSION}" \
    && ./configure --prefix=$PREFIX --static \
    && make -j"$(nproc)" \
    && make install \
    && cd .. && rm -rf "zlib-${ZLIB_VERSION}" zlib.tar.gz

# ---- OpenSSL 3.0 (no-shared, no-dso, no-engine — pure static) ----
ARG OPENSSL_VERSION=3.0.16
ARG OPENSSL_SHA256=57e03c50feab5d31b152af2b764f10379aecd8ee92f16c985983ce4a99f7ef86
RUN curl -fsSL -o openssl.tar.gz "https://github.com/openssl/openssl/releases/download/openssl-${OPENSSL_VERSION}/openssl-${OPENSSL_VERSION}.tar.gz" \
    && echo "${OPENSSL_SHA256}  openssl.tar.gz" | sha256sum -c - \
    && tar xf openssl.tar.gz \
    && cd "openssl-${OPENSSL_VERSION}" \
    && ./Configure linux-x86_64 \
        --prefix=$PREFIX \
        --openssldir=$PREFIX/ssl \
        --libdir=lib \
        no-shared no-dso no-engine no-tests no-async \
    && make -j"$(nproc)" \
    && make install_sw install_ssldirs \
    && cd .. && rm -rf "openssl-${OPENSSL_VERSION}" openssl.tar.gz

# ---- libpcap (static, no rdma/dbus/usb/bluetooth to keep dep surface small) ----
ARG LIBPCAP_VERSION=1.10.5
ARG LIBPCAP_SHA256=37ced90a19a302a7f32e458224a00c365c117905c2cd35ac544b6880a81488f0
RUN curl -fsSL -o libpcap.tar.gz "https://www.tcpdump.org/release/libpcap-${LIBPCAP_VERSION}.tar.gz" \
    && echo "${LIBPCAP_SHA256}  libpcap.tar.gz" | sha256sum -c - \
    && tar xf libpcap.tar.gz \
    && cd "libpcap-${LIBPCAP_VERSION}" \
    && ./configure --prefix=$PREFIX \
        --disable-shared \
        --enable-static \
        --disable-rdma \
        --disable-dbus \
        --disable-bluetooth \
        --disable-usb \
        --without-libnl \
        --with-pcap=linux \
    && make -j"$(nproc)" \
    && make install \
    && cd .. && rm -rf "libpcap-${LIBPCAP_VERSION}" libpcap.tar.gz

# ---- PCRE2 (static) ----
ARG PCRE2_VERSION=10.45
ARG PCRE2_SHA256=0e138387df7835d7403b8351e2226c1377da804e0737db0e071b48f07c9d12ee
RUN curl -fsSL -o pcre2.tar.gz "https://github.com/PCRE2Project/pcre2/releases/download/pcre2-${PCRE2_VERSION}/pcre2-${PCRE2_VERSION}.tar.gz" \
    && echo "${PCRE2_SHA256}  pcre2.tar.gz" | sha256sum -c - \
    && tar xf pcre2.tar.gz \
    && cd "pcre2-${PCRE2_VERSION}" \
    && ./configure --prefix=$PREFIX \
        --enable-static \
        --disable-shared \
        --enable-pcre2-8 \
        --enable-pcre2-16 \
        --enable-pcre2-32 \
    && make -j"$(nproc)" \
    && make install \
    && cd .. && rm -rf "pcre2-${PCRE2_VERSION}" pcre2.tar.gz

# ---- libssh2 (static, linked against our static OpenSSL) ----
ARG LIBSSH2_VERSION=1.11.1
ARG LIBSSH2_SHA256=d9ec76cbe34db98eec3539fe2c899d26b0c837cb3eb466a56b0f109cabf658f7
RUN curl -fsSL -o libssh2.tar.gz "https://www.libssh2.org/download/libssh2-${LIBSSH2_VERSION}.tar.gz" \
    && echo "${LIBSSH2_SHA256}  libssh2.tar.gz" | sha256sum -c - \
    && tar xf libssh2.tar.gz \
    && cd "libssh2-${LIBSSH2_VERSION}" \
    && ./configure --prefix=$PREFIX \
        --disable-shared \
        --enable-static \
        --with-crypto=openssl \
        --disable-examples-build \
    && make -j"$(nproc)" \
    && make install \
    && cd .. && rm -rf "libssh2-${LIBSSH2_VERSION}" libssh2.tar.gz

# ---- nmap ----
ARG NMAP_SHA256=e14ab530e47b5afd88f1c8a2bac7f89cd8fe6b478e22d255c5b9bddb7a1c5778
RUN curl -fsSL -o nmap.tar.bz2 "https://nmap.org/dist/nmap-${VERSION}.tar.bz2" \
    && echo "${NMAP_SHA256}  nmap.tar.bz2" | sha256sum -c - \
    && tar xf nmap.tar.bz2 \
    && rm nmap.tar.bz2

WORKDIR /build/nmap-${VERSION}

# Force a fully static link for the final binary. nmap configure detects external
# libs via --with-X=DIR; anything not found falls back to its bundled copy, which
# we want to avoid for the deps we just built.
ENV LDFLAGS="-static -L/opt/static/lib"
RUN ./configure \
        --prefix=/usr/local \
        --with-openssl=$PREFIX \
        --with-libpcap=$PREFIX \
        --with-libssh2=$PREFIX \
        --with-libz=$PREFIX \
        --with-libpcre=$PREFIX \
        --without-zenmap \
        --without-ndiff \
        --without-ncat \
        --without-nmap-update \
        --without-nping \
    && make -j"$(nproc)" \
    && make install \
    && strip /usr/local/bin/nmap

# Static-link sanity check. Both "statically linked" and "static-pie linked"
# count as fully static — the latter just adds ASLR.
RUN file /usr/local/bin/nmap | tee /tmp/nmap-file.txt \
    && grep -Eq "statically linked|static-pie linked" /tmp/nmap-file.txt \
    && ! ldd /usr/local/bin/nmap 2>&1 | grep -q "=>"

# NSE self-test. Exercises the Lua engine, nselib (TLS parsing, URL parsing,
# unicode, ssh2 helpers, sslcert, zlib, ~700 assertions total), and datafile
# loading. Fully hermetic — runs as a pre-scan script with -sn -Pn so no
# network/raw-socket privs needed. Fails the build if any nselib regresses.
RUN /usr/local/bin/nmap -sn -Pn --script unittest --script-args unittest.run 127.0.0.1 \
        | tee /tmp/nmap-unittest.txt \
    && grep -q "All tests passed" /tmp/nmap-unittest.txt

# ---- final image ----
# scratch keeps the image to: one static binary + datafiles + NSE scripts.
# Users either run it directly (docker run ghcr.io/aris1009/nmap …) or extract
# the binary + share dir with docker cp.
FROM scratch
ARG VERSION

LABEL \
    org.opencontainers.image.source="https://github.com/aris1009/images" \
    org.opencontainers.image.documentation="https://nmap.org/book/" \
    org.opencontainers.image.title="nmap (static, built from source by aris1009/images)" \
    org.opencontainers.image.description="Statically-linked nmap built from pinned upstream source against static OpenSSL/libpcap/libssh2/pcre2/zlib. Includes datafiles + NSE scripts under /usr/local/share/nmap. Cosign keyless signed + SLSA provenance + SBOM." \
    org.opencontainers.image.version=$VERSION \
    org.opencontainers.image.licenses="NPSL-1.0"

COPY --from=build /usr/local/bin/nmap /usr/local/bin/nmap
COPY --from=build /usr/local/share/nmap /usr/local/share/nmap

ENTRYPOINT ["/usr/local/bin/nmap"]
