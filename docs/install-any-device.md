# Install on any device

Same node, four ways in. Pick the row that matches your machine.

| Device | Command | Service used | Good for |
| --- | --- | --- | --- |
| Linux (Ubuntu 22.04 / Debian 12) | `curl -sSf .../install-validator.sh \| bash` | systemd | **production validators** |
| macOS (Intel + Apple Silicon) | `curl -sSf .../install-validator-mac.sh \| bash` | launchd | dev, replicas |
| Windows 10/11 | `irm .../install-validator.ps1 \| iex` | Scheduled Task | dev, replicas |
| Anything with Docker | `docker compose up -d --build` | Docker restart policy | dev, replicas, quick trials |

`...` = `https://raw.githubusercontent.com/inazuma-network/inazuma-validator/main/scripts`

Every installer does the same seven things: check the machine, install the toolchain,
build the binary, create (or reuse) your key with tight file permissions, fetch genesis
and initialise the data dir, install an auto-restarting service, then print your address
and the exact bond command.

All of them accept the same environment variables:

| Variable | Default | Meaning |
| --- | --- | --- |
| `INAZ_ROLE` | `validator` | `replica` = no key, no stake, no slashing risk |
| `INAZ_PEERS` | `rpc.inazuma.network:9944` | seed node to join through |
| `INAZ_KEY` | — | reuse an existing secret instead of generating one |
| `INAZ_REPO` | inazuma-core on GitHub | build from a fork or mirror |

---

## Linux — the production path

```bash
curl -sSf https://raw.githubusercontent.com/inazuma-network/inazuma-validator/main/scripts/install-validator.sh | bash
```

Installs to `/usr/local/bin/inazuma`, data in `/var/lib/inazuma`, key in
`/etc/inazuma/validator.env` (mode 600), service `inazuma.service`.

```bash
journalctl -u inazuma -f
sudo systemctl restart inazuma
```

## macOS

```bash
curl -sSf https://raw.githubusercontent.com/inazuma-network/inazuma-validator/main/scripts/install-validator-mac.sh | bash
```

No `sudo` and no admin password: binary, data, key and logs all live under
`~/.inazuma`, and a launchd agent (`~/Library/LaunchAgents/network.inazuma.node.plist`)
keeps it running.

```bash
tail -f ~/.inazuma/logs/node.log
~/.inazuma/bin/inazuma status
launchctl unload ~/Library/LaunchAgents/network.inazuma.node.plist   # stop
launchctl load   ~/Library/LaunchAgents/network.inazuma.node.plist   # start
```

A laptop sleeps, switches Wi-Fi and reboots for updates. Each of those is a missed-slot
streak, and 50 in a row is a jailing. Keep real stake on Linux; disable sleep
(System Settings → Lock Screen) if you insist on staking from a Mac.

## Windows 10/11

```powershell
irm https://raw.githubusercontent.com/inazuma-network/inazuma-validator/main/scripts/install-validator.ps1 | iex
```

Everything under `%USERPROFILE%\.inazuma`; a Scheduled Task called `InazumaNode` starts
it at logon and restarts it on failure. If the build fails with `link.exe not found`,
install the Visual Studio Build Tools "Desktop development with C++" workload and re-run.

```powershell
& "$env:USERPROFILE\.inazuma\bin\inazuma.exe" status
Stop-ScheduledTask  -TaskName InazumaNode
Start-ScheduledTask -TaskName InazumaNode
New-NetFirewallRule -DisplayName "Inazuma P2P" -Direction Inbound -Protocol TCP -LocalPort 9944 -Action Allow
```

WSL2 is not an improvement here — it puts NAT in front of the P2P port.

## Docker — one command, any OS

```bash
git clone https://github.com/inazuma-network/inazuma-validator.git
cd inazuma-validator/docker
echo "INAZ_KEY=<SECRET_HEX>" > .env      # omit for a keyless replica
docker compose up -d --build
```

```bash
docker compose logs -f
docker compose exec inazuma inazuma status
docker compose pull && docker compose up -d --build    # upgrade
```

Chain data lives in the `inazuma-data` volume, so rebuilds never resync from zero.
P2P 9944 is published; RPC 9933 is bound to 127.0.0.1 only.

---

## Why there is no single "one click" button

Building your own key on your own machine is the whole point of a validator — a hosted
button would mean somebody else holds the key that signs your blocks. The three things
that genuinely cannot be automated away:

1. **You must hold the key.** The installer generates it locally and never transmits it.
2. **You must own the machine.** A validator needs a stable IP and no sleep.
3. **You must bond stake.** That is a signed transaction from your account.

Everything else is already one command. If you want zero setup, run a **replica**
(`INAZ_ROLE=replica`) — no key, no stake, no slashing risk — or delegate to an existing
validator instead of running one.
