ARG VERSION

FROM docker.io/library/alpine:3.23@sha256:5b10f432ef3da1b8d4c7eb6c487f2f5a8f096bc91145e68878dd4a5019afde11 AS build
ARG VERSION
RUN apk add --no-cache gcc git curl python3 python3-dev py3-pip swig tinyxml-dev \
    musl-dev openssl-dev libffi-dev libxslt-dev libxml2-dev jpeg-dev \
    openjpeg-dev zlib-dev cargo rust
RUN git clone --depth=1 --branch "${VERSION}" https://github.com/smicallef/spiderfoot /src
WORKDIR /src
# Upstream v4.0 pins pyyaml>=5.4.1,<6 — 5.x fails its Cython build on Python 3.10+.
# Bump to >=6.0.1 (first release with the Cython fix). spiderfoot only uses
# yaml.safe_load, which is unchanged between 5.x and 6.x, so behavior is preserved.
RUN sed -i 's/^pyyaml>=5\.4\.1,<6$/pyyaml>=6.0.1,<7/' requirements.txt
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip3 install -U pip && pip3 install -r requirements.txt

FROM docker.io/library/alpine:3.23@sha256:5b10f432ef3da1b8d4c7eb6c487f2f5a8f096bc91145e68878dd4a5019afde11
ARG VERSION

LABEL \
    org.opencontainers.image.source="https://github.com/aris1009/images" \
    org.opencontainers.image.documentation="https://github.com/smicallef/spiderfoot" \
    org.opencontainers.image.title="spiderfoot (built from smicallef/spiderfoot source)" \
    org.opencontainers.image.description="SpiderFoot OSINT scanner rebuilt from pinned smicallef/spiderfoot source; cosign keyless signed + SLSA provenance + SBOM." \
    org.opencontainers.image.version=$VERSION \
    org.opencontainers.image.licenses="MIT"

WORKDIR /home/spiderfoot

ENV SPIDERFOOT_DATA=/var/lib/spiderfoot \
    SPIDERFOOT_LOGS=/var/lib/spiderfoot/log \
    SPIDERFOOT_CACHE=/var/lib/spiderfoot/cache

# Runtime deps mirror upstream smicallef/spiderfoot Dockerfile verbatim so behavior stays identical.
RUN apk --update --no-cache add python3 musl openssl libxslt tinyxml libxml2 jpeg zlib openjpeg \
    && addgroup spiderfoot \
    && adduser -G spiderfoot -h /home/spiderfoot -s /sbin/nologin \
               -g "SpiderFoot User" -D spiderfoot \
    && rm -rf /var/cache/apk/* /lib/apk/db /root/.cache \
    && mkdir -p "$SPIDERFOOT_DATA" "$SPIDERFOOT_LOGS" "$SPIDERFOOT_CACHE" \
    && chown -R spiderfoot:spiderfoot /var/lib/spiderfoot

COPY --from=build /src /home/spiderfoot
COPY --from=build /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

USER spiderfoot

EXPOSE 5001

ENTRYPOINT ["/opt/venv/bin/python"]
CMD ["sf.py", "-l", "0.0.0.0:5001"]
