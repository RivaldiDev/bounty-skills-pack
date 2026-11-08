# SCRIPTS

Helpers for a new harness. All are PowerShell. Each one is safe to read before you run it.

| Script | What it does |
|---|---|
| install-skills.ps1 | Copies skills/ into ~/.agents/skills and ~/.claude/skills |
| verify-pack.ps1 | Checks every skill folder has a SKILL.md and prints counts |
| new-hunt.ps1 | Creates a new <project>-bounty folder from the house layout |
| fetch-contract-source.ps1 | Pulls verified source from Sourcify for a chain id and address |

## new-hunt.ps1

    .\new-hunt.ps1 -Project acme

Creates ./acme-bounty with README, SCOPE, recon, analysis, findings, notes, repos, poc and
report, plus the finding template. It does not overwrite an existing folder.

## fetch-contract-source.ps1

    .\fetch-contract-source.ps1 -ChainId 1 -Address 0xdAC17F958D2ee523a2206206994597C13D831ec7

Writes the verified sources to ./repos/<address>/ and prints the compiler version and the
optimizer setting. That is the input you need before a bytecode compare.
