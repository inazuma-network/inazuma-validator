# Security policy

Report anything that could steal funds, halt the chain or forge state **privately**
through GitHub Security Advisories on
[inazuma-core](https://github.com/inazuma-network/inazuma-core/security/advisories/new) —
never as a public issue here.

This repository holds operator tooling. In scope: the installer, systemd units and
health scripts (privilege escalation, key exposure, unsafe defaults). Consensus, P2P,
RPC and crypto issues belong in inazuma-core.

## Operator hardening

- Keep the key in a root-only `EnvironmentFile`, mode 600 — never in the unit file.
- Bind `--rpc` to `127.0.0.1` unless you intend to serve public traffic.
- Pin peers with `--peer-ids` and set `--require-encrypted-p2p`.
- One validator key, one machine. Always.
