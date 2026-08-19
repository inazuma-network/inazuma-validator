# Reading node logs

`inazuma run` prints Ethereum-client style structured logs — the same shape
geth and lighthouse operators already read, so existing dashboards, `grep`
habits and log shippers work unchanged.

```text
Inazuma/v0.1.1/linux-x86_64 — sovereign L1, INAZ native coin

INFO  [08-19|01:27:24.469] Starting Inazuma node                  chain=7777 datadir=/var/lib/inazuma validator=8cCbiPdq..Vw6u
INFO  [08-19|01:27:24.469] Initialised chain configuration        chain=inazuma-7777 blocktime=400ms engine=pos (min stake 1000 INAZ)
INFO  [08-19|01:27:24.469] Loaded local state database            height=1,402,318 finalized=1,402,286 root=118a94c7..28d8
INFO  [08-19|01:27:24.469] Started P2P networking                 self=b991d1a4..aa64 peers=2 transport=INSC1-required
INFO  [08-19|01:27:24.469] HTTP server started                    endpoint=http://127.0.0.1:9933
INFO  [08-19|01:27:24.470] Validator account ready                address=8cCbiPdq... stake=40000 INAZ state=bonded
INFO  [08-19|01:27:32.512] Syncing chain segment                  number=1,402,900 target=1,404,120 progress=99.91% peers=2
INFO  [08-19|01:27:40.104] Chain synchronisation finished          height=1,404,120 validators=3 netstake=140000 INAZ you=producing blocks
INFO  [08-19|01:27:40.507] Imported new chain segment             number=1,404,121 hash=9f2c81aa..a1c4 txs=3 peers=2 elapsed=6ms
INFO  [08-19|01:27:50.507] Sealed new block                       number=1,404,146 hash=1cab1b7c..8611 txs=0 peers=2 elapsed=1ms
WARN  [08-19|01:28:02.507] Looking for peers                      peercount=0
```

## Line format

```text
LEVEL [MM-DD|HH:MM:SS.mmm] Message                     key=value key=value
```

Levels are `INFO`, `WARN`, `ERROR`, `DEBUG`. Timestamps are UTC. Block numbers
use thousands separators; hashes and public keys are shortened to `abcdef01..1234`.

## Messages you will see

| Message | Meaning |
| --- | --- |
| `Starting Inazuma node` | Boot line: chain id, data directory, validator address |
| `Initialised chain configuration` | Genesis loaded, block time, consensus engine |
| `Loaded local state database` | Local height, finality and state root on disk |
| `Started P2P networking` | Node key, peer count, INSC1 transport mode |
| `HTTP server started` / `WebSocket server started` | RPC endpoints bound |
| `Validator account ready` | Your address, bonded stake, bonded/unbonded |
| `Starting chain synchronisation` | Node is behind and pulling blocks |
| `Syncing chain segment` | Sync progress every 8s while catching up |
| `Chain synchronisation finished` | Caught up; live validator set and total stake |
| `Imported new chain segment` | A block with transactions was produced/applied |
| `Sealed new block` | Empty block; logged at most once every 10s to stay quiet |
| `Chain head updated` | Heartbeat at the tip: height, finality, peers, your role |
| `Looking for peers` | No peers — check `--peers` and firewall on 9944 |
| `Block production failed` | Production error with the underlying reason |

## Filtering

```bash
# only the important stuff
journalctl -u inazuma -f | grep -E "WARN|ERROR|Imported|synchronisation"

# sync progress only
journalctl -u inazuma -f | grep "Syncing chain segment"
```

Colours are disabled automatically when stdout is not a terminal (systemd,
Docker, pipes). Force plain output with `INAZ_NO_COLOR=1`.

## The Inazuma HUD (optional)

The animated Inazuma terminal HUD — banner, boxed panels, progress bar, QR link
to your validator page — is still available:

```bash
inazuma run --data /var/lib/inazuma --ui hud
# or
INAZ_UI=hud inazuma run --data /var/lib/inazuma
```

Use the default log format for servers and the HUD when you want a live human
dashboard on your laptop.
