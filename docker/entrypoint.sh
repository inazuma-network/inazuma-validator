#!/usr/bin/env sh
# Initialises on first boot, then runs the node. Key comes from INAZ_KEY.
set -eu
DATA=${INAZ_DATA:-/var/lib/inazuma}
GENESIS=${INAZ_GENESIS:-/etc/inazuma/genesis.json}
[ -d "$DATA/db" ] || inazuma init --data "$DATA" --genesis "$GENESIS"
set -- run --data "$DATA" --genesis "$GENESIS" --peers "${INAZ_PEERS}" --rpc 0.0.0.0:9933
[ "${INAZ_ROLE:-validator}" = "validator" ] && [ -n "${INAZ_KEY:-}" ] && set -- "$@" --key "$INAZ_KEY"
exec inazuma "$@"
