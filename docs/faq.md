# FAQ

**Do I need to know Rust?** No — about eight pasted commands.

**Can I run it at home?** Yes, if you can forward TCP 9944 and your connection is
stable. An outage costs rewards, not stake.

**Can I run two validators?** Yes — two machines, two different keys. Never one key twice.

**What if I lose my key?** The stake is gone. Back up `validator.env` offline before
bonding anything.

**Can I unstake whenever?** Yes; spendable after 300 blocks (~2 min).

**Is my stake at risk if I'm just offline?** No. From block 1,400,000 downtime no
longer jails or burns — like Ethereum, you only miss the rewards for the slots you
were offline for, and your validator resumes automatically when it is back.

**Do I need a domain or TLS?** Only for public RPC. A validator needs neither.

**Cost?** A suitable VPS is roughly $10-25/month.
