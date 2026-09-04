#!/bin/sh
# Generate one SNI route + backend per allowlisted host, then run HAProxy.
#
# Reads /etc/haproxy/allowlist.txt (one host per line, '#' comments ok) and emits
# into the base config an ACL + `use_backend be_allowed` per host. The backend
# itself is static in the base config: it dials the host named by the client's
# SNI, resolved at connect time, so one entry covers its whole subtree.
#
# Non-allowlisted SNI falls through to be_denied (no server) and is dropped.
# Deny-by-default: the ACLs are the whole policy.
set -eu

BASE=/usr/local/etc/haproxy/haproxy.cfg.base
OUT=/tmp/haproxy.cfg     # writable by the non-root haproxy user
ALLOW=/etc/haproxy/allowlist.txt

routes=""   # ACL + use_backend lines for the frontend
i=0
# The allowlist is mounted configuration. A missing mount and an empty file both
# fail closed the same way: no ACLs, so every SNI lands in be_denied.
if [ ! -f "$ALLOW" ]; then
    echo "haproxy-sni: ERROR no allowlist at $ALLOW -> denying ALL egress." >&2
    echo "haproxy-sni: mount one read-only, e.g. ./allowlist.txt:$ALLOW:ro" >&2
    : > /tmp/allowlist.empty
    ALLOW=/tmp/allowlist.empty
fi
while IFS= read -r line || [ -n "$line" ]; do
    host=$(printf '%s' "$line" | sed 's/#.*//; s/[[:space:]]//g')
    [ -z "$host" ] && continue
    i=$((i + 1))
    # -m dom: an entry `example.com` also matches `api.example.com`.
    routes="${routes}    acl a_${i} req.ssl_sni -m dom ${host}\n    use_backend be_allowed if a_${i}\n"
done < "$ALLOW"

if [ "$i" -eq 0 ]; then
    echo "haproxy-sni: WARNING empty allowlist -> deny ALL egress" >&2
fi

# Inject generated blocks into the base config at the marker lines.
awk -v routes="$routes" '
    /# --- BEGIN GENERATED ACLs\/ROUTES/ { print; printf routes; skip=1; next }
    /# --- END GENERATED ---/ && skip==1 { print; skip=0; next }
    skip==1 { next }
    { print }
' "$BASE" > "$OUT"

echo "haproxy-sni: ${i} host(s) allowed"

# Fail loudly on a bad generated config instead of serving a broken policy.
haproxy -c -f "$OUT" >/dev/null

exec "$@"
