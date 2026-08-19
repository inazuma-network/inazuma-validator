# Troubleshooting

| What you see | Why | Fix |
| --- | --- | --- |
| `state root mismatch` at a low height | wrong `genesis.json` | re-`init` with network genesis into a **clean** data dir |
| no peers after 60 s | 9944 closed, or wrong `--peers` | `sudo ufw allow 9944/tcp`, check the seed address |
| missed-slot streak growing | node behind, or slow disk | check lag with `inazuma status`; move to local NVMe |
| missed slots, no rewards | node offline or behind — downtime stopped jailing at block 1,400,000 | bring the node back and let it sync; rewards resume by themselves |
| `nonce too low` when sending | stale pending nonce | read `pendingNonce` from `inaz_getAccount` |
| service dies on boot | `EnvironmentFile` missing/unreadable | `sudo chmod 600 /etc/inazuma/validator.env`, `daemon-reload` |
| `cargo: command not found` | Rust env not sourced | `. "$HOME/.cargo/env"` or re-login |
| build killed on a 2 GB box | out of memory while linking | add 2 GB swap, or build elsewhere and copy the binary |

Still stuck? Open a [validator support issue](../../issues/new/choose) with the output
of `inazuma status` and the last 50 lines of `journalctl -u inazuma`. Never paste a
private key or `validator.env`.
