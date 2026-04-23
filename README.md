# images

Public container images built with signed, reproducible CI.

Every image is built by GitHub Actions, signed with
[cosign](https://github.com/sigstore/cosign) (keyless OIDC), and published
with [SLSA build provenance](https://slsa.dev/) + SBOM to
`ghcr.io/aris1009/<image>`.

## Images

| Image | Contents |
| --- | --- |
| `caddy` | Caddy with `caddy-dns/cloudflare` and `mholt/caddy-ratelimit` plugins baked in. |
| `claude-runner` | `node:22-slim` + `@anthropic-ai/claude-code` CLI; non-root `node` user; `ENTRYPOINT ["claude"]`. |
| `file-scanner` | Alpine + `clamav` (clamdscan client) + `inotify-tools` + generic watcher script; pairs with a separate `clamd` container. |
| `gluetun` | VPN client rebuilt from pinned `qdm12/gluetun` source; mirrors upstream runtime verbatim (alpine + openvpn 2.5/2.6 dual install). |
| `spiderfoot` | OSINT scanner rebuilt from pinned `smicallef/spiderfoot` source (no official registry image). |

## Tags

- `<upstream-version>` — floating; tracks the most recent build on `main` for that upstream version.
- `<upstream-version>-r<N>` — immutable per build; `N` is `github.run_number`, monotonic across the whole repo. Shared across matrix jobs in a run, so `caddy:2.11.2-r150` and `gluetun:3.41.1-r150` were built together.
- `sha-<short>` — immutable; for forensics.
- `latest` — most recent build on `main` (convenience only; pin by digest for production).

Images are multi-arch (`linux/amd64`, `linux/arm64`); the tag resolves to a manifest list. `cosign sign --recursive` signs both the index and the per-platform sub-manifests.

## Pinning

Always consume images by digest:

```
ghcr.io/aris1009/<image>:<tag>@sha256:<digest>
```

[Renovate](https://docs.renovatebot.com/) can track and auto-bump these pins.

## Build cadence

- On push to `main` when files under `<image>/` change (path-filtered matrix).
- Weekly cron (base-image + CVE refresh).
- On demand via `workflow_dispatch` (choose image or `all`).

## Layout

```
<image>/
  Dockerfile
  VERSION       # Renovate-tracked upstream version (also passed as --build-arg VERSION)
```

## Build locally

```sh
VERSION=$(grep -v '^\s*#' <image>/VERSION | tr -d ' \n')
podman build --build-arg VERSION="$VERSION" -t <image>:dev <image>/
```

## Verify a pulled image

```sh
cosign verify ghcr.io/aris1009/<image>@sha256:<digest> \
  --certificate-identity-regexp 'https://github.com/aris1009/images/.+' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
```
