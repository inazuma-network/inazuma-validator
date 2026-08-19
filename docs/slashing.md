# Slashing (and why downtime no longer jails)

Enforcement activates at block **130,000**, so earlier history replays unchanged.
Downtime jailing was retired at block **1,400,000** — Ethereum-style liveness.

| Offence | Detection | Penalty |
| --- | --- | --- |
| **Equivocation** — two blocks or precommits at one height | evidence verified against your signatures | burn `max(5%, 3 x stake share)`, **permanent tombstone** |
| **Downtime** — missed leader slots (offline, sleeping laptop, behind) | counted on chain | **no jail, no burn** — you only lose the rewards for the slots you missed |
| **Invalid block / bad state root** | peers reject it, never finalises | no burn, slot counted as missed |

Since the 1,400,000 fork a validator keeps its seat while offline and starts
earning again the moment it is caught up. `inazuma unjail` is only relevant to
pre-fork history; downtime jails set before the fork are inert.

Example: a validator with 20% of stake double-signs. `3 x 20% = 60%`, above the 5%
floor, so 60% of its stake burns and the key is banned forever. A 1% validator loses
the 5% floor instead — the bigger you are, the more an attack costs you.

Reporting is permissionless and pays the reporter **10% of the burn**. Evidence stays
valid 100,000 blocks and unbonding takes 300, so stake cannot outrun a pending report.

```bash
inazuma report --evidence ./evidence.json
```

Downtime never burns on a first offence: the realistic worst case for an honest
operator is one lost hour of rewards. The only way to lose real money is running one
key twice.
