# Bounty Skills Pack

A portable bundle of bug bounty skills, workflows and method. 34 skills covering web, smart
contracts, mobile, LLM and infrastructure. Drop it into any agent harness and start hunting.

**34 skills · 630 documents · 10.7 MB**

## Quick start

Clone the repo, then point your harness at the `skills/` folder.

    git clone https://github.com/RivaldiDev/bounty-skills-pack.git
    cd bounty-skills-pack

Each skill is a self contained folder with a `SKILL.md`:

    skills/bug-bounty/SKILL.md
    skills/web3-audit/SKILL.md
    skills/triage-validation/SKILL.md

The `SKILL.md` starts with YAML front matter:

    ---
    name: web3-audit
    description: Smart contract security audit. Use for Solidity or Rust.
    ---

Load the body when the task matches the description. If the body links to `references/` or
`scripts/`, keep those folders next to it.

## Install

| Harness | Where skills go |
|---|---|
| DeepSeek Harness | `~/.agents/skills/<name>/SKILL.md` |
| Claude Code | `~/.claude/skills/<name>/SKILL.md` |
| Any harness with a skill folder | Copy the folder |

PowerShell:

    .\scripts\install-skills.ps1 -Force

See [docs/INSTALL.md](docs/INSTALL.md) for the manual steps.

## What is inside

| Folder | What it is |
|---|---|
| [skills/](skills/) | 34 skill folders. Core bounty, web, web3, mobile, LLM, payload libraries. |
| [workflows/](workflows/) | Two operator doctrines. One for smart contracts, one for web. |
| [hunt-method/](hunt-method/) | The loop, the tool policy, and lessons from a real hunt. |
| [docs/](docs/) | The agent doctrine and the install guide. |
| [tether-hunt/](tether-hunt/) | A complete worked example. Scope, batches, analysis, PoC, log. |
| [scripts/](scripts/) | Install, verify, new-hunt and contract-source helpers. |
| [site-tools/](site-tools/) | Build a static site from this repo. Serve it over HTTP. |

### Skills

**Core bounty:** bug-bounty, bug-bounty-router, bb-methodology, web2-recon, web2-vuln-classes,
web3-audit, web3-playbook, meme-coin-audit, triage-validation, report-writing, security-arsenal,
argus, graphql-audit, cicd-security, credential-attack, client-reverse, api-security,
attack-chain, code-audit, llm-security, mobile-pentest, cloud-k8s, identity-federation,
email-security, supply-chain-security, use-tinyfish, browser-automation, orchestration,
case-review, threat-hunting, database-security

**Payload libraries:** pentest-tools (3.7 MB payloader library and playbooks),
reverse-skill-router (router plus a full copy of the suite), bountyforge (autonomous engine,
20 hacking agents, 22 tools)

## Read the method first

1. [hunt-method/HUNT-LOOP.md](hunt-method/HUNT-LOOP.md) — the 8 step loop and the batch model
2. [hunt-method/TOOL-POLICY.md](hunt-method/TOOL-POLICY.md) — search, read, contract and proof tools
3. [hunt-method/LESSONS-TETHER.md](hunt-method/LESSONS-TETHER.md) — real results from a live hunt

The lessons file is the fastest way to save hours. It covers the 401 oracle trick, why a
clean target is a real outcome, how to verify contract source before auditing it, and why a
callable proxy implementation is usually not a bug.

## Worked example

[tether-hunt/](tether-hunt/) is a complete hunt folder. Use it as the template for a new
target.

    tether-hunt/
    ├── README.md              program, reward table, rules of engagement
    ├── SCOPE.md               scope contract and eligibility traps
    ├── batch-01-consolidated.md
    ├── analysis/              four deep dives, including two contract audits
    ├── notes/hunt-log.md
    ├── findings/FINDING-TEMPLATE.md
    ├── recon/agent-reports/   raw per agent outputs
    └── poc/                   Foundry harnesses for USDT and XAuT

## Static site

[site-tools/](site-tools/) builds a browsable site from this repo.

    cd site-tools
    node build-site-data.js                      # reads ../ and writes ./data/
    python -m http.server 8080                   # serve it

The site is an `index.html` with a file tree, a viewer and search. It is plain files with
no server side code. Use it when a harness cannot read a repo but can fetch a URL.

To rebuild the repo from a running site:

    python site-tools/rebuild-skills.py --base http://localhost:8080 --out ./out

## Rules that travel with this pack

- Only test assets the program names. A discovered host is a lead, not a target.
- No denial of service. No social engineering. No access to other users' data.
- Prove or drop. "Could potentially" is not a finding.
- Write down negative results. They are worth as much as findings.
- Never disclose before a fix.

## Provenance

Skills were collected from `~/.agents/skills` and `~/.claude/skills`. The workflows and
doctrine files are the operator's own. The `tether-hunt` folder is real output from a live
hunt.

## License

Skill content is provided as is for authorized security research. Check each program's rules
of engagement before you test. Many of these skills describe offensive technique. Use them
only where you have written permission.

## Full inventory

See [MANIFEST.md](MANIFEST.md) for every file and where it came from.
