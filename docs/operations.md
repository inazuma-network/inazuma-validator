# Day-to-day operation

```bash
inazuma status         # height, sync state, missed-slot streak
inazuma validators     # active set, stake shares, next leader
inazuma slashing       # params, jail state, slash history
inazuma unstake --key <SECRET_HEX> --amount 1000
inazuma unjail  --key <SECRET_HEX>
```

Watch three things; the rest is noise:

1. **missed-slot streak** — should stay at 0-2
2. **lag vs network tip** — under a couple of blocks
3. **free disk** — top up long before it fills

```bash
bash scripts/healthcheck.sh     # or run it from cron every minute
```

## Upgrading

```bash
cd ~/inazuma-core && git pull && cargo build --release
sudo install -m755 target/release/inazuma /usr/local/bin/inazuma
sudo systemctl restart inazuma
```

Or just re-run the installer. Consensus changes ship behind an activation height, so
upgrading early is safe and upgrading late is what breaks you.

## Hardening

Encrypted, pinned P2P (INSC1: X25519 exchange, Ed25519 transcript signature,
ChaCha20-Poly1305 framing) stops an attacker surrounding you with fake peers:

```bash
inazuma run ... --peers rpc.inazuma.network:9944 \
  --peer-ids <PEER_NODE_KEY_HEX>,<PEER_NODE_KEY_HEX> --require-encrypted-p2p

curl -s localhost:9933 -d '{"jsonrpc":"2.0","id":1,"method":"inaz_netInfo"}'
```

Keep RPC on `127.0.0.1` unless you serve the public, and:

```bash
sudo apt install -y unattended-upgrades fail2ban
sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart ssh
```

Key file: mode 600, owned by root, never in a git repo, screenshot, support chat or
cloud sync folder.

## Read replicas (no stake)

Reads and consensus are different jobs. Put as many replicas behind a load balancer as
traffic needs without touching the validator set:

```bash
inazuma run --data /var/lib/inazuma-replica --genesis /etc/inazuma/genesis.json \
  --replica --peers rpc.inazuma.network:9944 --rpc 0.0.0.0:9933 --ws 0.0.0.0:9955
```

Or `INAZ_ROLE=replica bash install-validator.sh`, with
[`systemd/inazuma-replica.service`](../systemd/inazuma-replica.service).
