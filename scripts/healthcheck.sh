#!/usr/bin/env bash
# Node health in one screen. Exits non-zero if the service is down.
#   bash scripts/healthcheck.sh
#   * * * * * /usr/local/bin/bash /root/inazuma-validator/scripts/healthcheck.sh >> /var/log/inazuma-health.log 2>&1
set -uo pipefail

DATA_DIR="${INAZ_DATA:-/var/lib/inazuma}"
RPC="${INAZ_RPC:-http://127.0.0.1:9933}"

printf '== %s ==\n' "$(date -u '+%Y-%m-%d %H:%M:%SZ')"

if systemctl is-active --quiet inazuma; then
  echo "service   active"
else
  echo "service   DOWN — journalctl -u inazuma -n 50"
  exit 1
fi

inazuma status 2>/dev/null | grep -Ei 'height|sync|missed' || \
  curl -s "$RPC" -d '{"jsonrpc":"2.0","id":1,"method":"inaz_nodeStatus"}'

curl -s "$RPC" -d '{"jsonrpc":"2.0","id":1,"method":"inaz_netInfo"}' | head -c 400; echo
df -h "$DATA_DIR" | tail -1
