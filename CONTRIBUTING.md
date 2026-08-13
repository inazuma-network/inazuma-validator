# Contributing

Operator tooling only — node changes go to
[inazuma-core](https://github.com/inazuma-network/inazuma-core).

- Shell must pass `shellcheck scripts/*.sh` and stay POSIX-ish bash with `set -euo pipefail`.
- Scripts must be idempotent: safe to re-run, never overwriting keys or data.
- Never print, log or echo a secret key.
- Test on a fresh Ubuntu 22.04 box and say so in the PR description.
- Docs: short sentences, copy-pasteable commands, no unexplained jargon.
