# images

Public container images for [aris1009](https://github.com/aris1009)'s homelab.

Images are built by GitHub Actions and published to
[`ghcr.io/aris1009/<image>`](https://github.com/aris1009?tab=packages).

## Layout

Each image lives in its own top-level directory:

```
<image>/
  Dockerfile
  assets/       # optional: files COPYed into the image
```

Current images:

| Image | Source | Purpose |
| --- | --- | --- |
| `caddy` | `caddy/Dockerfile` | Caddy with `caddy-dns/cloudflare` + `mholt/caddy-ratelimit` plugins |

## Build locally

```sh
podman build -t <image>:dev <image>/
```

## Publishing

Images are published on merge to `main` (for paths under the image's
directory), on a weekly schedule (CVE refresh), and on demand via
`workflow_dispatch`. Downstream consumers pin by digest.
