# squid-hardened

A hardened [Squid](http://www.squid-cache.org/) forward proxy, built from
upstream source and stripped of everything that can be used to run another
program.

Not affiliated with or endorsed by the Squid project. Upstream publishes no
container image; this one exists because the images built by distributions are
root-owned, shell-bearing and carry helper binaries that a forward proxy does
not need.

```
ghcr.io/aris1009/squid-hardened:<version>[@sha256:<digest>]
```

## Why this image exists

A proxy is a process that parses untrusted input from the network and is often
placed where it can reach everything. Two properties matter more than anything
else:

1. **No shell.** There is no `/bin/sh`, no busybox and no package manager in the
   runtime image. Code execution has no interpreter to pivot to.
2. **No helper binaries.** Squid can be configured to execute programs
   (authentication helpers, external ACL helpers, URL rewriters, store-id
   helpers, log daemons). None of them are built here, so no mounted
   configuration can turn into command execution. `--disable-...` on every
   helper family is enforced by a build-time assertion.

The rest is conventional: non-root, no capabilities, read-only filesystem
compatible, and only `/tmp` is writable.

## Contract

| Property | Value |
| --- | --- |
| User / group | `1000:1000` (`squid`) |
| Listening port | `3128/tcp` |
| Configuration | `/etc/squid/squid.conf` (replaceable by mount) |
| Drop-in directory | `/etc/squid/conf.d/*.conf` (shipped: the recommended deny guards; included before the final deny) |
| Writable paths | `/tmp` only (mount a tmpfs when using `--read-only`) |
| Cache | none by default; add a `cache_dir` on a volume (below) |
| Health check | `/usr/local/bin/squid-probe` (HTTP request through the proxy; any answer means healthy); configured by the runtime, not baked in |
| Signals | `SIGTERM` graceful shutdown, `SIGHUP` reconfigure |
| Entrypoint | none; the image runs `/usr/sbin/squid -N -f /etc/squid/squid.conf` |

The default configuration denies every request. The image is inert without a
mounted policy, which is deliberate: a container that starts with an open proxy
because a volume was forgotten is worse than one that starts closed.

## Quick start

```sh
podman run -d --name squid \
  --user 1000:1000 \
  --read-only --tmpfs /tmp \
  --cap-drop=all --security-opt=no-new-privileges \
  -p 127.0.0.1:3128:3128 \
  -v ./squid.conf:/etc/squid/squid.conf:ro,Z \
  ghcr.io/aris1009/squid-hardened:7.8
```

## Configuring

Two supported patterns; both are plain Squid configuration.

**Replace the file.** Mount a complete `squid.conf`. You inherit nothing, which
is the simplest thing to reason about:

```sh
-v ./squid.conf:/etc/squid/squid.conf:ro,Z
```

**Add drop-ins.** Keep the shipped defaults and mount files into
`/etc/squid/conf.d/`. They are included *before* `http_access deny all`, so
allow rules work as expected:

```sh
-v ./policy.conf:/etc/squid/conf.d/20-policy.conf:ro,Z
```

The image ships `10-recommended.conf`, the deny-only guards from upstream's
"Recommended minimum Access Permission configuration": no access is granted by
it, but it denies unsafe ports, `CONNECT` to ports other than 443, and requests
to loopback and link-local addresses. Number your own files `20` and above so
they are read after those guards.

Two consequences worth knowing:

- `Safe_ports` is `80 443`. To proxy anything else, add the port in your own
  file (`acl Safe_ports port 8080`, and `acl SSL_ports port …` for `CONNECT`),
  because the guard denies first.
- The include is a glob, and Squid treats a pattern that matches nothing as a
  fatal error. Do not mount over `/etc/squid/conf.d/` with an empty directory:
  keep the shipped file or supply one of your own.

Both mounts must be readable by uid 1000 and should be `:ro`.

### Example: deny-by-default egress allowlist

```squid
acl allowed_domains dstdomain "/etc/squid/allowed_domains.txt"
acl SSL_ports port 443
acl CONNECT method CONNECT

http_access allow CONNECT allowed_domains SSL_ports
# http_access deny all  is already in the shipped default, after this include
```

`allowed_domains.txt` holds one domain per line. Prefix an entry with `.` to
match subdomains (`.example.com` matches `example.com` and every subdomain).

## Caching

Caching is off until you add a `cache_dir`. Do that in a drop-in, then create
the swap directories once:

```squid
cache_dir ufs /var/spool/squid 4096 16 256
```

```sh
podman volume create squid-cache

# A fresh volume is owned by container root. Give it to the runtime uid so the
# proxy (and the -z step) can write to it.
podman unshare chown -R 1000:1000 \
  "$(podman volume inspect -f '{{.Mountpoint}}' squid-cache)"

# -N keeps the process in the foreground so the output is visible; -z creates
# the swap directories and exits.
podman run --rm --user 1000:1000 \
  --entrypoint /usr/sbin/squid \
  -v squid-cache:/var/spool/squid \
  -v ./cache.conf:/etc/squid/conf.d/20-cache.conf:ro \
  ghcr.io/aris1009/squid-hardened:7.8 -N -z -f /etc/squid/squid.conf
```

Mount the same volume when running the proxy. `--user 0:0` does not help here:
the shipped `cache_effective_user squid` drops the `-z` step to uid 1000 before
it creates anything, so the volume must already be writable by that uid.

## Operations without a shell

There is no shell to `exec` into. Everything below runs a binary directly, so
no interpreter is involved:

```sh
podman exec <container> /usr/sbin/squid -k parse       # validate the config
podman exec <container> /usr/sbin/squid -k reconfigure # apply a changed config
podman kill --signal HUP <container>                   # same thing
podman exec <container> /usr/local/bin/squid-probe     # exit 0 = listening
podman kill --signal TERM <container>                  # graceful stop
```

Logs are on stdout/stderr (`podman logs`). There is no log file to rotate, and
`logfile_rotate 0` keeps Squid from trying.

## What is compiled in and out

**In:** HTTP/HTTPS proxying (`CONNECT`), the `ufs` cache store, OpenSSL (TLS
listener and peer TLS), IPv6, `dstdomain` and `dst`/`port` ACLs, standard access
logging.

**Out, with the reason:**

| Removed | Why |
| --- | --- |
| All authentication mechanisms | Each one is a helper binary that the configuration executes. Proxy auth needs a build with those helpers; this image cannot do it. |
| External ACL, URL-rewrite, store-id and log-daemon helpers | Same reason: configuration-triggered program execution. |
| Certificate validator/generator helpers | Removes `ssl_bump bump` (TLS decryption). `peek`/`splice` still compile in and do not decrypt. |
| ICAP and ECAP | Request/response modification against an external server; large parser surface, not needed for proxying. |
| WCCP, WCCPv2, SNMP, HTCP, EUI, ARP ACL | Router-, switch- and cache-hierarchy protocols. None belong in a container. |
| Transparent/interception modes (ipfw, ipf, pf, netfilter) | Requires `CAP_NET_ADMIN` and turns the proxy into a network device it is not. |
| Ident lookups, cache digests, `forw-via-db` | Information disclosure and cache-hierarchy features with no forward-proxy use. |
| Translation / locale machinery | English error pages only. Keeps the image free of `po4a` build dependencies. |
| `unlinkd` | A helper process for a job the main process does itself. |

The runtime image also has no shell, no busybox, no `apk`, no compiler and no
build headers; those exist only in the discarded builder stage.

## Health check

The image ships `/usr/local/bin/squid-probe`, a static binary that connects to
`127.0.0.1:3128`, sends one minimal HTTP request and exits 0 when the proxy
answers with anything at all — a 403 under the shipped deny-by-default policy
counts as healthy. A connection that is accepted but never answered is treated
as unhealthy. It exists because the runtime has no shell, so a shell-based check
is impossible.

It is deliberately **not** baked in as a `HEALTHCHECK`: this pipeline publishes
OCI manifests, which have no field for one (podman warns and drops it). Point
your runtime at the probe instead:

```ini
# Quadlet
HealthCmd=["/usr/local/bin/squid-probe"]
```

```yaml
# docker compose
healthcheck:
  test: ["CMD", "/usr/local/bin/squid-probe"]
```

```yaml
# kubernetes
livenessProbe:
  exec:
    command: ["/usr/local/bin/squid-probe"]
```

`SQUID_PROBE_PORT` overrides the port if you change `http_port`. Without a
runtime health check, a plain `curl` through the proxy is enough to tell
whether it is serving.

## Verifying a published image

Every image is built by GitHub Actions from this repository, signed keyless
with cosign, and published with SLSA provenance and an SBOM.

```sh
cosign verify ghcr.io/aris1009/squid-hardened@sha256:<digest> \
  --certificate-identity-regexp 'https://github.com/aris1009/images/.+' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com

cosign verify-attestation ghcr.io/aris1009/squid-hardened@sha256:<digest> \
  --type slsaprovenance \
  --certificate-identity-regexp 'https://github.com/aris1009/images/.+' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
```

## Source and reproducibility

The binary is built from the upstream `SQUID_7.8` release archive, verified
against sha512 `db2a9490f8313062f1cbcdac8c225686027c43d9810a8cb02fab46be18e44b2fedbd3b2cfab1ece00e26727629f02c97a4810a1d3145edd007f6cb8660186854`
before compilation. That is the same hash Alpine's `main/squid` recipe
publishes, so two independent packaging recipes agree on the bytes. Upstream
does not sign GitHub archive tarballs; the hash plus the build provenance is
what you get, and it is stated plainly here rather than implied.

Build with the base image pinned, the source hash pinned, and
`SOURCE_DATE_EPOCH` fixed to the release date rather than to build time.

`VERSION` and `SQUID_SHA512` track the same upstream tag: when Renovate bumps
the version, the pull request must also replace the sha512 (take it from
Alpine's `main/squid` recipe for the same release). The build stops on a
mismatch, so the two cannot drift silently. `--build-arg SQUID_SHA512=…` can
override the pin for a one-off build.

```sh
VERSION=$(grep -v '^\s*#' squid-hardened/VERSION | tr -d ' \n')
podman build --build-arg VERSION="$VERSION" -t squid-hardened:dev squid-hardened/
```

## Licence

Squid is GPL-2.0-or-later. The licence text ships in the image at
`/usr/share/licenses/squid-hardened/COPYING`, and the corresponding source is
the upstream archive named above.
