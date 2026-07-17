#!/bin/sh
# Generate one SNI route + backend per allowlisted host, then run HAProxy.
#
# Reads /etc/haproxy/allowlist.txt (one host per line, '#' comments ok) and emits
# into the base config: an ACL + use_backend per host, and a `server host:443`
# backend that dials the real upstream. Non-allowlisted SNI falls through to
# be_denied (no server) and is dropped. Deny-by-default.
set -eu

BASE=/usr/local/etc/haproxy/haproxy.cfg.base
OUT=/tmp/haproxy.cfg     # writable by the non-root haproxy user
ALLOW=/etc/haproxy/allowlist.txt

routes=""   # ACL + use_backend lines for the frontend
backends="" # backend blocks
i=0
while IFS= read -r line || [ -n "$line" ]; do
    host=$(printf '%s' "$line" | sed 's/#.*//; s/[[:space:]]//g')
    [ -z "$host" ] && continue
    i=$((i + 1))
    be="be_${i}"
    # -m dom: an entry `example.com` also matches `api.example.com`.
    routes="${routes}    acl a_${i} req.ssl_sni -m dom ${host}\n    use_backend ${be} if a_${i}\n"
    backends="${backends}backend ${be}\n    server s ${host}:443 resolvers pubdns init-addr none\n\n"
done < "$ALLOW"

if [ "$i" -eq 0 ]; then
    echo "haproxy-sni: WARNING empty allowlist -> deny ALL egress" >&2
fi

# Inject generated blocks into the base config at the marker lines.
awk -v routes="$routes" -v backends="$backends" '
    /# --- BEGIN GENERATED ACLs\/ROUTES/ { print; printf routes; skip=1; next }
    /# --- END GENERATED ---/ && skip==1 { print; skip=0; next }
    /# --- BEGIN GENERATED BACKENDS/ { print; printf backends; skipb=1; next }
    /# --- END GENERATED ---/ && skipb==1 { print; skipb=0; next }
    skip==1 || skipb==1 { next }
    { print }
' "$BASE" > "$OUT"

echo "haproxy-sni: ${i} host(s) allowed"

# Fail loudly on a bad generated config instead of serving a broken policy.
haproxy -c -f "$OUT" >/dev/null

exec "$@"
