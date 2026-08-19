# Quickstart

**Time:** ~20 minutes, mostly waiting for a compile.
**Skills:** you can rent a server and paste commands. That's it.

## What a validator is

Inazuma produces a block every 400 ms. A validator is a small server that keeps a full
copy of the chain, gets picked in turn to produce blocks (more stake = picked more
often), votes on everyone else's blocks, and earns the fees and rewards for its own.

Bond **1,000 INAZ** and you are in the rotation on the next block. No allowlist, no
application.

| Term | Plain English |
| --- | --- |
| Stake / bond | INAZ you lock so the network can punish you |
| Slot | Your turn to produce a block |
| Missed slot | Your turn came and your node didn't produce |
| Jailed | Legacy state — downtime jailing was retired at block 1,400,000. Only double-signing removes a key. |
| Slashed | Stake burned for provable cheating |
| Tombstoned | Key banned forever — double-signing only |
| Unbonding | 300-block wait before withdrawn stake is spendable |
| Replica | Syncs and serves queries, never validates. No stake. |
| Genesis | Block 0. Every node needs the identical file. |

## 1. Install (easy)

```bash
curl -sSf https://raw.githubusercontent.com/inazuma-network/inazuma-validator/main/scripts/install-validator.sh | bash
```

Read it first if you prefer:

```bash
curl -sSfO https://raw.githubusercontent.com/inazuma-network/inazuma-validator/main/scripts/install-validator.sh
less install-validator.sh
bash install-validator.sh
```

It prints your address when done. Skip to step 3.

### Not on Linux?

| Device | Command |
| --- | --- |
| macOS | `curl -sSf https://raw.githubusercontent.com/inazuma-network/inazuma-validator/main/scripts/install-validator-mac.sh \| bash` |
| Windows (PowerShell) | `irm https://raw.githubusercontent.com/inazuma-network/inazuma-validator/main/scripts/install-validator.ps1 \| iex` |
| Docker (any OS) | `cd docker && docker compose up -d --build` |

Full per-device notes, service commands and caveats: [install-any-device.md](install-any-device.md).
Mac and Windows are for development and replicas — production stake belongs on a Linux
server with a static IP.

## 2. Install (manual)

```bash
sudo apt update && sudo apt install -y build-essential curl git pkg-config
curl https://sh.rustup.rs -sSf | sh -s -- -y && . "$HOME/.cargo/env"
sudo ufw allow 9944/tcp

git clone https://github.com/inazuma-network/inazuma-core.git
cd inazuma-core && cargo build --release
sudo install -m755 target/release/inazuma /usr/local/bin/inazuma

inazuma keygen | tee ~/validator.txt && chmod 600 ~/validator.txt
```

Back the secret up offline now, and never run one key on two machines.

Initialise from the network genesis, byte for byte:

```bash
sudo mkdir -p /etc/inazuma /var/lib/inazuma
sudo cp genesis.json /etc/inazuma/genesis.json
inazuma init --data /var/lib/inazuma --genesis /etc/inazuma/genesis.json
```

Sync before you stake — a validator elected while syncing just misses slots and earns nothing:

```bash
inazuma run --data /var/lib/inazuma --genesis /etc/inazuma/genesis.json \
  --key <SECRET_HEX> --peers rpc.inazuma.network:9944 --rpc 127.0.0.1:9933
inazuma status   # in another shell
```

When it starts you get Ethereum-client style logs (geth/lighthouse format) — one
line per event, `key=value` fields, greppable in `journalctl`:

```text
INFO  [08-19|01:27:24.469] Starting Inazuma node                  chain=7777 datadir=/var/lib/inazuma validator=8cCbiPdq..Vw6u
INFO  [08-19|01:27:32.512] Syncing chain segment                  number=1,402,900 target=1,404,120 progress=99.91% peers=2
INFO  [08-19|01:27:40.507] Imported new chain segment             number=1,404,121 hash=9f2c81aa..a1c4 txs=3 peers=2 elapsed=6ms
INFO  [08-19|01:27:48.507] Chain head updated                     number=1,404,141 finalized=1,404,109 peers=2 stake=40000 INAZ role=validator
```

Every message, field and filter is documented in [logs](logs.md). Prefer the
animated Inazuma HUD instead? Add `--ui hud`.

Then run it under systemd — see [`systemd/inazuma.service`](../systemd/inazuma.service):

```bash
printf 'INAZ_KEY=<SECRET_HEX>\n' | sudo tee /etc/inazuma/validator.env >/dev/null
sudo chmod 600 /etc/inazuma/validator.env
sudo cp systemd/inazuma.service /etc/systemd/system/inazuma.service
sudo systemctl daemon-reload && sudo systemctl enable --now inazuma
journalctl -u inazuma -f
```

## 3. Bond your stake

```bash
inazuma status                                  # must say in sync
inazuma stake --key <SECRET_HEX> --amount 1000
inazuma validators
```

The leader keeps every fee in its block plus 20% commission on the block reward; the
other 80% is split across the active set by stake and credited immediately — no claim
transaction.

Next: [operations](operations.md).
