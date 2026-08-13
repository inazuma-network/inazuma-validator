# Slashing & jailing

Enforcement activates at block **130,000**, so earlier history replays unchanged.

| Offence | Detection | Penalty |
| --- | --- | --- |
| **Equivocation** — two blocks or precommits at one height | evidence verified against your signatures | burn `max(5%, 3 x stake share)`, **permanent tombstone** |
| **Downtime** — 50 consecutive missed leader slots | counted on chain | jailed 10,000 blocks (~1 h), no burn; repeats burn 0.1% |
| **Invalid block / bad state root** | peers reject it, never finalises | no burn, slot counted as missed |

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
