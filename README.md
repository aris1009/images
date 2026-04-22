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

## Tags

- `<upstream-version>` — e.g. `caddy:2.11.2`, `claude-runner:2.1.117`.
- `<upstream-version>-<commit-sha>` — immutable per build.
- `latest` — most recent build on `main` (convenience only; pin by digest for production).

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
