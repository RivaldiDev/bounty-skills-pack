# MANIFEST

Every file in this pack, and where it came from.

## skills/ (34 skill folders)

Copied from `~/.agents/skills` unless marked.

### Core bounty skills

| Skill | Files | Bytes | Use |
|---|---|---|---|
| bug-bounty | 1 | 79,742 | Full workflow. Recon, hunting, reporting. |
| bug-bounty-router | 1 | 4,850 | Routes to the right skill when unsure |
| bb-methodology | 1 | 18,958 | Master orchestrator. "What next". |
| web2-recon | 1 | 25,760 | Subdomain, crawl, JS, directory recon |
| web2-vuln-classes | 1 | 98,728 | 26 bug classes with bypass tables |
| web3-audit | 1 | 18,030 | 10 DeFi bug classes, Foundry PoC |
| web3-playbook | 16 | 293,660 | Numbered training modules |
| meme-coin-audit | 1 | 9,612 | Rug pull, SPL, Token-2022 |
| triage-validation | 1 | 13,531 | 7 question gate before reporting |
| report-writing | 1 | 15,629 | Report templates, CVSS, title formula |
| security-arsenal | 3 | 73,427 | Payloads, bypass tables, wordlists |
| argus | 1 | 6,892 | Six automated scanners |
| graphql-audit | 1 | 16,882 | Introspection, batching, IDOR |
| cicd-security | 1 | 12,395 | Actions injection, OIDC, runners |
| credential-attack | 1 | 19,049 | Spray methodology and guardrails |
| client-reverse | 2 | 25,944 | Signed requests and anti bot |
| api-security | 3 | 12,085 | REST, GraphQL, WebSocket authz |
| attack-chain | 4 | 28,423 | Multi stage path planning |
| code-audit | 2 | 2,533 | Semgrep and CodeQL patterns |
| llm-security | 5 | 29,086 | Prompt injection, tool abuse |
| mobile-pentest | 1 | 18,791 | APK and IPA runtime first |
| cloud-k8s | 2 | 3,216 | Metadata SSRF, RBAC, escape |
| identity-federation | 2 | 1,872 | SAML, OIDC, OAuth |
| email-security | 2 | 1,784 | SPF, DKIM, DMARC, BEC |
| supply-chain-security | 3 | 11,400 | SBOM, SCA, provenance |
| use-tinyfish | 1 | 8,036 | The search and read path |
| browser-automation | 3 | 20,162 | camofox-browser PoC evidence |
| orchestration | 1 | 17,578 | Multi agent coordination |
| case-review | 3 | 34,255 | Review a case package |
| threat-hunting | 2 | 2,265 | Sigma, YARA, detection |
| database-security | 2 | 1,759 | DB exposure and authz |

### Heavy payload skills

| Skill | Files | Bytes | Note |
|---|---|---|---|
| pentest-tools | 114 | 3,763,222 | Payloader library, playbooks, WAF bypass |
| reverse-skill-router | 358 | 5,608,275 | Router plus a full copy of the skill suite |

Note: `reverse-skill-router` contains its own copy of many skills, including a second copy
of `pentest-tools`. That duplication is why the pack is large. Remove
`skills/reverse-skill-router/pentest-tools` if you want to save about 3.7 MB.

### Copied from `~/.claude/skills`

| Skill | Files | Bytes | Note |
|---|---|---|---|
| bountyforge | 58 | 814,011 | Full autonomous engine. 20 hacking agents, 22 tools. |

## workflows/

| File | Source |
|---|---|
| sc-workflow-0xkonde.md | Operator supplied. Smart contract doctrine. |
| bugbounty-workflow-0xkonde.md | Operator supplied. Web bounty doctrine. |

## hunt-method/

| File | Contents |
|---|---|
| HUNT-LOOP.md | The 8 step loop and the batch model |
| TOOL-POLICY.md | Search, read, contract and proof tool order |
| LESSONS-TETHER.md | Real results from the Tether run |

## docs/

| File | Source |
|---|---|
| AGENTS.md | The operator agent doctrine |

## tether-hunt/

A complete worked example. Use it as a template for the folder layout and the report
standard.

| Path | Contents |
|---|---|
| README.md | Program, reward table, focus, layout, rules of engagement |
| SCOPE.md | Scope contract, severity model, eligibility traps |
| batch-01-consolidated.md | Six angle batch with a kill list |
| batch-02-plan.md | How the next batch was authored from the first |
| analysis/ | Four deep dives including two contract audits |
| notes/hunt-log.md | Timestamped log |
| findings/FINDING-TEMPLATE.md | The finding template |
| recon/agent-reports/ | The raw per agent batch outputs |
| poc/ | Foundry harnesses for USDT and XAuT |

## scripts/

Helper scripts for a new harness. See scripts/README.md.

## Total

See the counts printed by `scripts/verify-pack.ps1`.
