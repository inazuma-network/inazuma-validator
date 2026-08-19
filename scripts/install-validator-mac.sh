#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Inazuma validator installer — macOS (Intel + Apple Silicon)
#
#   curl -sSf https://raw.githubusercontent.com/inazuma-network/inazuma-validator/main/scripts/install-validator-mac.sh | bash
#
# Everything lives under $HOME, so no sudo and no admin password is needed.
#   binary  ~/.inazuma/bin/inazuma
#   data    ~/.inazuma/data
#   config  ~/.inazuma/genesis.json, ~/.inazuma/validator.env (mode 600)
#   service ~/Library/LaunchAgents/network.inazuma.node.plist (launchd)
#
# NOTE: a laptop sleeps and changes networks. Missed slots get you jailed.
# Use this for development and read-replicas; run production validators on a
# Linux server with a static IP.
# ---------------------------------------------------------------------------
set -euo pipefail

SEED="${INAZ_PEERS:-rpc.inazuma.network:9944}"
ROLE="${INAZ_ROLE:-validator}"          # validator | replica
REPO_URL="${INAZ_REPO:-https://github.com/inazuma-network/inazuma-core.git}"
GENESIS_URL="${INAZ_GENESIS_URL:-https://raw.githubusercontent.com/inazuma-network/inazuma-core/main/genesis.json}"
HOME_DIR="$HOME/.inazuma"
SRC_DIR="${INAZ_SRC:-$HOME/inazuma-core}"
BIN="$HOME_DIR/bin/inazuma"
PLIST="$HOME/Library/LaunchAgents/network.inazuma.node.plist"

c()  { printf '\033[38;5;205m%s\033[0m\n' "$*"; }
ok() { printf '  \033[38;5;205m✓\033[0m %s\n' "$*"; }
die(){ printf '\033[31m✗ %s\033[0m\n' "$*" >&2; exit 1; }
step(){ printf '\n'; c "── $* ────────────────────────────────────────"; }

[ "$(uname -s)" = "Darwin" ] || die "This installer is for macOS. On Linux use install-validator.sh."
mkdir -p "$HOME_DIR/bin" "$HOME_DIR/logs" "$HOME/Library/LaunchAgents"

c ""
c "  INAZUMA VALIDATOR INSTALLER — macOS"
c "  role=$ROLE  seed=$SEED"
c ""

step "1/6  Checking this Mac"
CPUS=$(sysctl -n hw.ncpu)
RAM_GB=$(( $(sysctl -n hw.memsize) / 1024 / 1024 / 1024 ))
echo "  cpu ${CPUS} cores · ram ${RAM_GB} GB · $(uname -m)"
[ "$CPUS" -ge 2 ] || echo "  ! 2 cores is the minimum."
[ "$RAM_GB" -ge 4 ] || echo "  ! 8 GB RAM recommended."
ok "machine looks usable"

step "2/6  Toolchain"
xcode-select -p >/dev/null 2>&1 || { echo "  installing Command Line Tools (a dialog may appear)…"; xcode-select --install || true; }
if ! command -v cargo >/dev/null; then
  curl -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal >/dev/null
fi
# shellcheck disable=SC1091
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
command -v cargo >/dev/null || die "Rust did not install. Open a new terminal and re-run."
ok "rust $(rustc --version | awk '{print $2}')"

step "3/6  Building the node (5–15 minutes the first time)"
if [ -d "$SRC_DIR/.git" ]; then git -C "$SRC_DIR" pull --ff-only -q; else git clone -q "$REPO_URL" "$SRC_DIR"; fi
( cd "$SRC_DIR" && cargo build --release -q )
install -m755 "$SRC_DIR/target/release/inazuma" "$BIN"
ok "installed $("$BIN" --version 2>/dev/null || echo inazuma)"

step "4/6  Key and genesis"
if [ -f "$HOME_DIR/validator.env" ]; then
  ok "existing key kept (~/.inazuma/validator.env)"
else
  if [ "$ROLE" = "replica" ]; then
    : > "$HOME_DIR/validator.env"
    ok "replica — no key created, no slashing risk"
  else
    OUT=$("$BIN" keygen)
    SECRET=$(echo "$OUT" | grep -iEo '[0-9a-f]{64,}' | head -1)
    ADDR=$(echo "$OUT" | grep -iEo '[1-9A-HJ-NP-Za-km-z]{32,48}' | head -1)
    printf 'INAZ_KEY=%s\nINAZ_ADDRESS=%s\n' "$SECRET" "$ADDR" > "$HOME_DIR/validator.env"
    chmod 600 "$HOME_DIR/validator.env"
    ok "key created — back up ~/.inazuma/validator.env offline NOW"
  fi
fi
[ -f "$HOME_DIR/genesis.json" ] || { [ -f "$SRC_DIR/genesis.json" ] && cp "$SRC_DIR/genesis.json" "$HOME_DIR/genesis.json" || curl -sSfo "$HOME_DIR/genesis.json" "$GENESIS_URL"; }
[ -d "$HOME_DIR/data" ] || "$BIN" init --data "$HOME_DIR/data" --genesis "$HOME_DIR/genesis.json"
ok "data dir ready"

step "5/6  launchd service (auto-start at login, restart on crash)"
# shellcheck disable=SC1091
. "$HOME_DIR/validator.env" 2>/dev/null || true
KEY_ARGS=""
[ -n "${INAZ_KEY:-}" ] && KEY_ARGS="<string>--key</string><string>${INAZ_KEY}</string>"
cat > "$PLIST" <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>network.inazuma.node</string>
  <key>ProgramArguments</key><array>
    <string>${BIN}</string><string>run</string>
    <string>--data</string><string>${HOME_DIR}/data</string>
    <string>--genesis</string><string>${HOME_DIR}/genesis.json</string>
    ${KEY_ARGS}
    <string>--peers</string><string>${SEED}</string>
    <string>--rpc</string><string>127.0.0.1:9933</string>
  </array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>StandardOutPath</key><string>${HOME_DIR}/logs/node.log</string>
  <key>StandardErrorPath</key><string>${HOME_DIR}/logs/node.err.log</string>
</dict></plist>
PL
chmod 600 "$PLIST"
launchctl unload "$PLIST" 2>/dev/null || true
launchctl load "$PLIST"
ok "service loaded"

step "6/6  Done"
c ""
[ -n "${INAZ_ADDRESS:-}" ] && c "  your address:  ${INAZ_ADDRESS}"
cat <<TXT

  logs      tail -f ~/.inazuma/logs/node.log      # geth-style: INFO [MM-DD|HH:MM:SS] ...
  errors    grep -E "WARN|ERROR" ~/.inazuma/logs/node.log
  hud       $BIN run --data ~/.inazuma/data --ui hud  # animated HUD instead of logs
  status    $BIN status
  stop      launchctl unload $PLIST
  start     launchctl load $PLIST

  Next: fund your address, wait until 'status' says in sync, then bond:
    $BIN stake --key \$INAZ_KEY --amount 1000

  Track your node at https://inazuma.network/validators
  Reminder: keep the Mac awake (System Settings -> Lock Screen -> never sleep)
  or you will miss slots and get jailed.
TXT
