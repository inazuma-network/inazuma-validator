<h1 align="center">Inazuma Validator</h1>

<p align="center">
  <b>Everything needed to run a node on Inazuma</b> — a sovereign Layer 1 built from
  scratch in Rust for memes, NFTs, games and communities: 400 ms blocks, sub-cent fees.
</p>

<p align="center">
  <a href="docs/quickstart.md">Quickstart</a> ·
  <a href="docs/install-any-device.md">Install on any device</a> ·
  <a href="docs/operations.md">Operations</a> ·
  <a href="docs/logs.md">Logs</a> ·
  <a href="docs/slashing.md">Slashing</a> ·
  <a href="docs/troubleshooting.md">Troubleshooting</a> ·
  <a href="docs/faq.md">FAQ</a>
</p>

---

## Table of contents

1. [What Inazuma is, and why we need validators](#1-what-inazuma-is-and-why-we-need-validators)
2. [Is running a validator right for you?](#2-is-running-a-validator-right-for-you)
3. [Vocabulary — every term used in this repo](#3-vocabulary--every-term-used-in-this-repo)
4. [Requirements, in full](#4-requirements-in-full)
5. [Choosing and preparing a server](#5-choosing-and-preparing-a-server)
6. [Install path A — one command](#6-install-path-a--one-command) · [Mac / Windows / Docker](docs/install-any-device.md)
7. [Install path B — manual, step by step](#7-install-path-b--manual-step-by-step)
8. [Getting INAZ and bonding stake](#8-getting-inaz-and-bonding-stake)
9. [Rewards — how you get paid](#9-rewards--how-you-get-paid)
10. [Running it forever: monitoring and upkeep](#10-running-it-forever-monitoring-and-upkeep)
11. [Security and key handling](#11-security-and-key-handling)
12. [Penalties: jailing and slashing](#12-penalties-jailing-and-slashing)
13. [Leaving the validator set](#13-leaving-the-validator-set)
14. [Replicas and public RPC](#14-replicas-and-public-rpc)
15. [Command reference](#15-command-reference)
16. [Files this repo installs](#16-files-this-repo-installs)
17. [Troubleshooting and support](#17-troubleshooting-and-support)
18. [The Inazuma repos](#18-the-inazuma-repos)

---

## 1. What Inazuma is, and why we need validators

Inazuma is its own Layer 1 — not a rollup, not a fork, not a chain running on someone
else's settlement layer. The node in
[inazuma-core](https://github.com/inazuma-network/inazuma-core) is roughly 20k lines of
Rust: proof-of-stake consensus, its own P2P transport, its own state tree, a WASM
contract VM, JSON-RPC and WebSocket.

**What we are building toward:** the home chain for memes, NFTs, collectibles, games and
communities. That use case is unusual in one specific way — it is *high volume and low
value per transaction*. Someone minting a 500-piece collection, or a game writing a move
per second, cannot pay dollars in fees or wait seconds for a confirmation. So the design
targets are blunt:

| Target | Where it is today |
| --- | --- |
| Block time | 400 ms, finalised in the same block |
| Fee for a transfer | ~0.000001 INAZ (fractions of a cent) |
| Throughput | ~2,500 tx/s ingest, 20k-36k tx/s execution in bench |
| Native tokens & NFTs | first-class chain records, no contract needed |
| Contracts | WASM VM, gas-metered |
| Light clients | sparse Merkle state proofs (from block 200,000) |

**Validators are what make that real.** Every 400 ms someone must build a block and
everyone else must agree it is valid. A validator is a small server that:

1. keeps a full copy of the chain,
2. is elected in turn to produce blocks (more stake = more turns),
3. votes on other validators' blocks,
4. earns the fees and rewards for the blocks it produces.

More independent validators, in more places, run by more people = a chain nobody can
stop or censor. That is the whole reason this repo exists.

## 2. Is running a validator right for you?

Read this honestly before spending money.

**Run a validator if:** you can rent a small server, paste commands into a terminal,
hold 1,000 INAZ, and keep the machine online. That is genuinely the whole list — no Rust,
no DevOps career, no Kubernetes.

**Run a replica instead if:** you want to serve RPC to an app, index the chain, or just
have your own trusted endpoint. No stake, no key, no penalties. See
[section 14](#14-replicas-and-public-rpc).

**Don't run either if:** the machine is a laptop that sleeps, a shared/burstable VPS, or
a connection that drops daily. Downtime costs rewards, and a badly-run node hurts the
network's block times.

**Cost:** roughly **$10-25/month** for a suitable VPS, plus 1,000 INAZ locked (returned
when you unbond, unless you double-sign).

**Effort after setup:** minutes per week. The service restarts itself; you watch three
numbers.

## 3. Vocabulary — every term used in this repo

| Term | Plain English |
| --- | --- |
| **Node** | The `inazuma` program running on your server |
| **Validator** | A node that stakes, produces blocks and votes |
| **Replica** | A node that syncs and answers queries but never produces or votes |
| **Stake / bond** | INAZ you lock so the network can punish you if you cheat |
| **Slot** | Your turn to produce a block |
| **Missed slot** | Your turn came and your node didn't produce — offline or behind |
| **Jailed** | Temporarily benched after too many missed slots. **No stake burned.** |
| **Slashed** | Stake burned for provable cheating (signing twice at one height) |
| **Tombstoned** | That key is banned forever. Double-signing only. |
| **Equivocation** | Signing two different blocks/votes at the same height |
| **Unbonding** | The 300-block (~2 min) wait before withdrawn stake is spendable |
| **Genesis** | Block 0. Every node must use the byte-identical `genesis.json` |
| **Seed / peer** | A node you connect to in order to find the rest of the network |
| **Finality** | The point a block can never be reverted — same block, on Inazuma |
| **INAZ** | The native token: pays fees, is what you stake |
| **Address** | Your base58 Ed25519 account, e.g. `HmnqtkFg2F5…` |
| **Node key** | Separate identity used for encrypted P2P (not your validator key) |
| **Activation height** | The block a consensus change turns on, so old history still replays |

## 4. Requirements, in full

**You need, before you start:**

- [ ] A server you control: rented VPS, dedicated box, or a machine at home
- [ ] Ubuntu 22.04 / 24.04 or Debian 12, 64-bit, with root or `sudo`
- [ ] An SSH client (Terminal on macOS/Linux, PowerShell or PuTTY on Windows)
- [ ] A **static public IP** and inbound **TCP 9944** open (P2P)
- [ ] **Local NVMe SSD** — not HDD, not network/cloud volume
- [ ] Unmetered bandwidth or ≥ 2 TB/month (gossip is constant)
- [ ] **1,000 INAZ** in the address you will validate with
- [ ] A safe offline place to store one small file (your key backup)

**You do not need:** a domain, TLS certificates, Docker, Rust knowledge, a static
website, an open RPC port, or approval from anyone. There is no allowlist and no
application form — bond and you are in on the next block.

**Hardware sizing:**

| Setup | vCPU | RAM | Disk | Good for |
| --- | --- | --- | --- | --- |
| Minimum | 2 dedicated | 4 GB | 50 GB NVMe | works, little headroom |
| **Recommended** | 4 dedicated | 8 GB | 100 GB NVMe | what we run in production |
| Heavy RPC / replica | 8 | 16 GB | 200 GB NVMe | if you also serve public traffic |

Why these numbers: 400 ms blocks mean **disk latency hurts far more than CPU**. Signature
verification is parallel, so extra cores help under load; RAM holds the mempool and state
cache; disk grows with history, so leave headroom.

## 5. Choosing and preparing a server

Hard-won rules:

- **1 vCPU is replica-only.** Never validate on it.
- **Avoid burstable/shared CPU tiers** (the cheapest plan at most hosts). They throttle
  at exactly the wrong moment and produce missed-slot streaks.
- **Different data centres** for your validator and any backup. Two boxes in one rack
  fail together.
- Any provider works. The node has zero cloud dependencies.

First login, before anything else:

```bash
ssh root@YOUR_SERVER_IP
adduser inaz && usermod -aG sudo inaz      # optional but recommended
timedatectl set-ntp true                    # clock must be accurate for 400 ms slots
nproc && free -g && df -h /                 # confirm you got what you paid for
```

Open P2P and keep everything else closed:

```bash
sudo apt update
sudo ufw allow 22/tcp && sudo ufw allow 9944/tcp && sudo ufw --force enable
```

## 6. Install path A — one command

This installs build tools and Rust, builds the node, creates your key, initialises from
genesis, installs a systemd service and starts it:

```bash
curl -sSf https://raw.githubusercontent.com/inazuma-network/inazuma-validator/main/scripts/install-validator.sh | bash
```

Read it first — you should:

```bash
curl -sSfO https://raw.githubusercontent.com/inazuma-network/inazuma-validator/main/scripts/install-validator.sh
less install-validator.sh
bash install-validator.sh
```

Options, as environment variables:

```bash
INAZ_ROLE=replica bash install-validator.sh          # read-only node, no key, no stake
INAZ_PEERS=1.2.3.4:9944 bash install-validator.sh    # join via a different seed
INAZ_SRC=/opt/inazuma-core bash install-validator.sh # build in a custom directory
```

What it does, in order: checks the machine is big enough → installs deps and Rust →
builds and installs the binary → creates or reuses your key → writes
`/etc/inazuma/genesis.json` and initialises the data dir → opens 9944 → installs and
starts `inazuma.service` → prints your address.

It is **idempotent**: re-run it any time to upgrade the binary. It never overwrites an
existing key or data directory, and it never prints your secret into the terminal log —
the key is written to `/etc/inazuma/validator.env`, mode 600.

Takes 5-10 minutes on 2 cores, most of it compiling. Then go to
[section 8](#8-getting-inaz-and-bonding-stake).

## 7. Install path B — manual, step by step

Do this to understand every moving part, or if you are not on Debian/Ubuntu.

**7.1 Dependencies**

```bash
sudo apt update && sudo apt install -y build-essential curl git pkg-config
curl https://sh.rustup.rs -sSf | sh -s -- -y && . "$HOME/.cargo/env"
rustc --version      # 1.80 or newer
```

**7.2 Build the node** — one binary, no framework, no external VM:

```bash
git clone https://github.com/inazuma-network/inazuma-core.git
cd inazuma-core && cargo build --release
sudo install -m755 target/release/inazuma /usr/local/bin/inazuma
inazuma --version
```

> Building on a 2 GB box can be killed while linking. Add 2 GB swap, or build elsewhere
> and copy the binary across.

**7.3 Create your validator key**

```bash
inazuma keygen | tee ~/validator.txt && chmod 600 ~/validator.txt
```

The base58 address printed is both your account and your validator identity.
**Back the secret up offline right now.** Lose it and you can neither sign blocks nor
ever withdraw your stake — nobody can recover it for you.

**7.4 Initialise from genesis**, byte for byte. A different file means a different state
root at block 1 and every peer rejects you:

```bash
sudo mkdir -p /etc/inazuma /var/lib/inazuma
sudo cp genesis.json /etc/inazuma/genesis.json
inazuma init --data /var/lib/inazuma --genesis /etc/inazuma/genesis.json
```

**7.5 Sync before you stake.** A validator elected while still syncing misses slots and
gets jailed:

```bash
inazuma run --data /var/lib/inazuma --genesis /etc/inazuma/genesis.json \
  --key <SECRET_HEX> --peers rpc.inazuma.network:9944 --rpc 127.0.0.1:9933

inazuma status      # in a second shell — wait until it says in sync
```

When it starts you get Ethereum-client style logs (geth/lighthouse format) — one
line per event, `key=value` fields, greppable in `journalctl`:

```text
INFO  [08-19|01:27:24.469] Starting Inazuma node                  chain=7777 datadir=/var/lib/inazuma validator=8cCbiPdq..Vw6u
INFO  [08-19|01:27:32.512] Syncing chain segment                  number=1,402,900 target=1,404,120 progress=99.91% peers=2
INFO  [08-19|01:27:40.507] Imported new chain segment             number=1,404,121 hash=9f2c81aa..a1c4 txs=3 peers=2 elapsed=6ms
INFO  [08-19|01:27:48.507] Chain head updated                     number=1,404,141 finalized=1,404,109 peers=2 stake=40000 INAZ role=validator
```

Every message, field and filter is documented in [logs](docs/logs.md). Prefer the
animated Inazuma HUD instead? Add `--ui hud`.

`INAZ_KEY` in the environment works instead of `--key`, so the secret never enters shell
history.

**7.6 Run it under systemd.** Downtime is punished — never leave the node in an SSH
session:

```bash
printf 'INAZ_KEY=<SECRET_HEX>\n' | sudo tee /etc/inazuma/validator.env >/dev/null
sudo chmod 600 /etc/inazuma/validator.env

sudo cp systemd/inazuma.service /etc/systemd/system/inazuma.service
sudo systemctl daemon-reload && sudo systemctl enable --now inazuma
journalctl -u inazuma -f
```

Unit templates: [`systemd/inazuma.service`](systemd/inazuma.service) and
[`systemd/inazuma-replica.service`](systemd/inazuma-replica.service).

## 8. Getting INAZ and bonding stake

1. Fund the address from [section 7.3](#7-install-path-b--manual-step-by-step) with at
   least **1,000 INAZ** (faucet for test amounts:
   [inazuma-faucet](https://github.com/inazuma-network/inazuma-faucet)).
2. Confirm you are synced — this is the step people skip and get jailed for.
3. Bond:

```bash
inazuma status                                            # must say in sync
source /etc/inazuma/validator.env
inazuma stake --key "$INAZ_KEY" --amount 1000
inazuma validators                                        # you should appear in the set
```

You are now in the leader rotation, starting from the next block.

## 9. Rewards — how you get paid

- The block's **leader keeps every transaction fee** in that block, plus **20%
  commission** on the block reward.
- The remaining **80% is split across the active set in proportion to stake**.
- Rewards are **credited immediately** — there is no claim transaction and nothing to
  compound manually.

Practical consequences: more stake means more turns as leader, so earnings scale with
stake; and a node that misses slots earns nothing for those slots. Uptime is the whole
game.

## 10. Running it forever: monitoring and upkeep

```bash
inazuma status         # height, sync state, missed-slot streak
inazuma validators     # active set, stake shares, next leader
inazuma slashing       # params, jail state, slash history
```

Watch exactly three things; everything else is noise:

1. **missed-slot streak** — should stay at 0-2
2. **lag vs the network tip** — under a couple of blocks
3. **free disk** — top up long before it fills

Cron the bundled check:

```bash
bash scripts/healthcheck.sh
# every minute, appending to a log:
* * * * * bash /root/inazuma-validator/scripts/healthcheck.sh >> /var/log/inazuma-health.log 2>&1
```

**Upgrading** (or just re-run the installer):

```bash
cd ~/inazuma-core && git pull && cargo build --release
sudo install -m755 target/release/inazuma /usr/local/bin/inazuma
sudo systemctl restart inazuma
```

Consensus changes always ship behind an **activation height**, so upgrading early is
safe and upgrading late is what breaks you. Watch releases in inazuma-core.

**Reboots and crashes** are handled: the unit is `Restart=always` and enabled at boot.

## 11. Security and key handling

**Encrypted, pinned P2P.** Every peer link is an INSC1 session: ephemeral X25519
exchange, an Ed25519 signature over the handshake transcript, then ChaCha20-Poly1305
framing. Pin the node keys you accept so nobody can surround you with fake peers (an
eclipse attack):

```bash
inazuma run ... --peers rpc.inazuma.network:9944 \
  --peer-ids <PEER_NODE_KEY_HEX>,<PEER_NODE_KEY_HEX> --require-encrypted-p2p

curl -s localhost:9933 -d '{"jsonrpc":"2.0","id":1,"method":"inaz_netInfo"}'
```

**Keep RPC private** — bind to `127.0.0.1` unless you intend to serve the public. If you
do, use API keys, per-method cost weighting and stake-weighted rate limits (see the RPC
docs in inazuma-core).

**Server hygiene:**

```bash
sudo apt install -y unattended-upgrades fail2ban
sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart ssh
```

**Key rules, non-negotiable:**

- Key file at mode 600, owned by root, in an `EnvironmentFile` — never inside the unit.
- Never in a git repo, screenshot, support chat, paste bin or cloud-sync folder.
- **Back up `/etc/inazuma/validator.env` offline.** It is the only copy.
- **One key, one machine. Always.** Two nodes signing at one height is indistinguishable
  from an attack and is tombstoned permanently.

Ed25519 today, with an optional ML-DSA-65 co-signature path for post-quantum safety —
see the architecture doc in inazuma-core.

## 12. Penalties: jailing and slashing

Enforcement activates at block **130,000**, so all earlier history replays unchanged.

| Offence | How it's detected | Penalty |
| --- | --- | --- |
| **Equivocation** — two blocks or precommits at one height | evidence verified against your own signatures | burn `max(5%, 3 x stake share)`, **permanent tombstone** |
| **Downtime** — 50 consecutive missed leader slots | counted on chain | jailed 10,000 blocks (~1 h), **no burn**; repeats burn 0.1% |
| **Invalid block / bad state root** | peers reject it; never finalises | no burn, slot counted as missed |

Worked example: a validator holding 20% of stake double-signs. `3 x 20% = 60%`, above the
5% floor, so **60% of its stake burns** and the key is banned forever. A 1% validator
loses the 5% floor instead. The bigger you are, the more an attack costs you — deliberate.

Reporting is permissionless and pays the reporter **10% of the burn**. Evidence stays
valid for 100,000 blocks and unbonding takes 300, so stake cannot outrun a pending report.

```bash
inazuma report --evidence ./evidence.json
inazuma unjail --key "$INAZ_KEY"     # after the jail height passes
```

**Downtime never burns stake on a first offence.** The realistic worst case for an honest
operator is one lost hour of rewards. The only way to lose real money is running one key
twice. Full detail: [docs/slashing.md](docs/slashing.md).

## 13. Leaving the validator set

```bash
inazuma unstake --key "$INAZ_KEY" --amount 1000   # spendable after 300 blocks (~2 min)
sudo systemctl disable --now inazuma              # stop the node once unbonded
```

Unbond **before** shutting down, or you will accumulate missed slots and get jailed while
still bonded. Keep the key backup even after leaving — it is the account that holds the
returned stake.

## 14. Replicas and public RPC

Reads and consensus are different jobs. A replica syncs every block but never produces
one and never votes, so you can put as many behind a load balancer as traffic needs
without touching the validator set. No stake, no key, no penalties.

```bash
inazuma run --data /var/lib/inazuma-replica --genesis /etc/inazuma/genesis.json \
  --replica --peers rpc.inazuma.network:9944 --rpc 0.0.0.0:9933 --ws 0.0.0.0:9955
```

Or `INAZ_ROLE=replica bash install-validator.sh`, with
[`systemd/inazuma-replica.service`](systemd/inazuma-replica.service).

## 15. Command reference

| Command | What it does |
| --- | --- |
| `inazuma keygen` | Create a keypair; prints address + secret |
| `inazuma init --data … --genesis …` | Initialise a data directory from genesis |
| `inazuma run …` | Run the node (validator or `--replica`) |
| `inazuma status` | Height, sync state, missed-slot streak |
| `inazuma validators` | Active set, stake shares, next leader |
| `inazuma stake --key … --amount …` | Bond stake and join the set |
| `inazuma unstake --key … --amount …` | Start unbonding |
| `inazuma unjail --key …` | Rejoin after a jail period ends |
| `inazuma slashing` | Params, jail state, slash history |
| `inazuma report --evidence …` | Submit slashing evidence (earns 10% of the burn) |
| `inazuma send --to … --amount …` | Transfer INAZ |
| `inazuma bench --key … --count …` | Local load test |

Useful `run` flags: `--peers`, `--peer-ids`, `--require-encrypted-p2p`, `--rpc`, `--ws`,
`--replica`, `--data`, `--genesis`, `--key` (or `INAZ_KEY`), `--ui hud` (animated HUD
instead of the default Ethereum-style logs).

## 16. Files this repo installs

```
scripts/install-validator.sh      one-command install and upgrade (idempotent)
scripts/healthcheck.sh            cron-able status / lag / disk check
systemd/inazuma.service           validator unit template
systemd/inazuma-replica.service   replica unit template
docs/quickstart.md                shortest path from empty server to bonded validator
docs/operations.md                monitoring, upgrades, hardening, replicas
docs/logs.md                      reading the Ethereum-style node logs
docs/slashing.md                  every penalty, with worked examples
docs/troubleshooting.md           symptom → cause → fix table
docs/faq.md                       the questions everyone asks
```

On the server, after install:

```
/usr/local/bin/inazuma              the node binary
/etc/inazuma/genesis.json           network genesis (must match exactly)
/etc/inazuma/validator.env          your key, mode 600 — BACK THIS UP
/var/lib/inazuma/                   chain data
/etc/systemd/system/inazuma.service the service
```

## 17. Troubleshooting and support

| What you see | Why | Fix |
| --- | --- | --- |
| `state root mismatch` at a low height | wrong `genesis.json` | re-`init` with network genesis into a **clean** data dir |
| no peers after 60 s | 9944 closed, or wrong `--peers` | `sudo ufw allow 9944/tcp`, check the seed address |
| missed-slot streak growing | node behind, or slow disk | check lag with `inazuma status`; move to local NVMe |
| jailed | 50 missed slots in a row | fix the node, wait out the jail height, `inazuma unjail` |
| `nonce too low` when sending | stale pending nonce | read `pendingNonce` from `inaz_getAccount` |
| service dies on boot | `EnvironmentFile` missing/unreadable | `sudo chmod 600 /etc/inazuma/validator.env`, `daemon-reload` |
| `cargo: command not found` | Rust env not sourced | `. "$HOME/.cargo/env"` or re-login |
| build killed on a 2 GB box | out of memory while linking | add 2 GB swap, or build elsewhere and copy the binary |

Still stuck? Open a [validator support issue](../../issues/new/choose) with the output of
`inazuma status` and the last 50 lines of `journalctl -u inazuma`.
**Never paste a private key or the contents of `validator.env`.**
Security disclosure policy: [SECURITY.md](SECURITY.md).

## 18. The Inazuma repos

| Repo | What's in it |
| --- | --- |
| [inazuma-core](https://github.com/inazuma-network/inazuma-core) | The Rust L1: consensus, state, staking, P2P, RPC, WASM VM |
| **inazuma-validator** (here) | Node operators: installer, units, health checks, guide |
| [inazuma-sdk](https://github.com/inazuma-network/inazuma-sdk) | Client libraries for building apps |
| [inazuma-wallet](https://github.com/inazuma-network/inazuma-wallet) | Browser extension, web and Android wallet |
| [inazuma-contracts](https://github.com/inazuma-network/inazuma-contracts) | WASM contract examples and tooling |
| [inazuma-faucet](https://github.com/inazuma-network/inazuma-faucet) | Test-token faucet service |
| [inazuma-docs](https://github.com/inazuma-network/inazuma-docs) | Protocol and developer documentation |
| [inazuma-improvement-proposals](https://github.com/inazuma-network/inazuma-improvement-proposals) | INAZIPs — how the chain changes |

Licensed under [Apache-2.0](LICENSE). Contributions welcome —
see [CONTRIBUTING.md](CONTRIBUTING.md).
