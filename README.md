<h1 align="center">Inazuma Validator</h1>
<p align="center">
  Everything you need to run a node on the Inazuma network — installer, systemd units,
  health checks and the full operator guide.
</p>
<p align="center">
  <a href="docs/quickstart.md">Quickstart</a> ·
  <a href="docs/operations.md">Operations</a> ·
  <a href="docs/slashing.md">Slashing</a> ·
  <a href="docs/troubleshooting.md">Troubleshooting</a> ·
  <a href="docs/faq.md">FAQ</a>
</p>

---

Node source code lives in [inazuma-core](https://github.com/inazuma-network/inazuma-core).
This repository is operator-facing only: nothing here changes consensus.

## One command

```bash
curl -sSf https://raw.githubusercontent.com/inazuma-network/inazuma-validator/main/scripts/install-validator.sh | bash
```

Installs build tools and Rust, builds the node, creates your key, initialises from
genesis, installs a systemd service and starts it. Re-run any time to upgrade — it
never overwrites a key or a data directory.

```bash
INAZ_ROLE=replica  bash install-validator.sh       # read-only node, no key, no stake
INAZ_PEERS=1.2.3.4:9944 bash install-validator.sh  # join via a different seed
```

Then bond:

```bash
inazuma status                                  # must say in sync first
source /etc/inazuma/validator.env && inazuma stake --key $INAZ_KEY --amount 1000
inazuma validators
```

## Hardware

| Setup | vCPU | RAM | Disk |
| --- | --- | --- | --- |
| Minimum | 2 | 4 GB | 50 GB NVMe |
| Recommended | 4 | 8 GB | 100 GB NVMe |
| Heavy RPC / replica | 8 | 16 GB | 200 GB NVMe |

Ubuntu 22.04 or Debian 12, static public IP, inbound TCP 9944 open, local NVMe.
Burstable/shared CPU plans throttle and cause missed slots — use dedicated cores.

## What's in here

```
scripts/install-validator.sh   one-command install and upgrade
scripts/healthcheck.sh         cron-able status / lag / disk check
systemd/inazuma.service        validator unit template
systemd/inazuma-replica.service replica unit template
docs/                          quickstart, operations, slashing, troubleshooting, FAQ
```

## Two rules

1. **Back up `/etc/inazuma/validator.env` offline.** It is the only copy of your key.
2. **Never run one key on two machines.** Double-signing is tombstoned permanently.

Security disclosure: see [SECURITY.md](SECURITY.md). Stuck? Open a
[validator support issue](../../issues/new/choose).
