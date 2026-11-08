---
name: bug-bounty-router
description: Master router for the installed bug-bounty skill suite (from shuvonsec/claude-bug-bounty + awesome-web3 testing tools). Use when a task involves bug bounty, web3 smart-contract auditing, token audits, recon, vulnerability hunting, reverse engineering of client-side signing, report writing, or when unsure which of the new skills (web3-audit, web3-playbook, meme-coin-audit, web2-recon, web2-vuln-classes, argus, graphql-audit, cicd-security, credential-attack, mobile-pentest, security-arsenal, triage-validation, report-writing, bb-methodology, bug-bounty, client-reverse) applies. Routes each task to the right skill and points to the toolchain in C:\Users\rival\Tools. Use as the entry point for any hunting/audit request.
---

# Bug Bounty Router

Single entry point that routes any hunting/audit request to the correct installed
skill, including the reverse-engineering family, and points at the installed
toolchain. Always start here when a request is ambiguous or spans categories.

## Routing table

| If the task is… | Route to |
|---|---|
| Start of session / lost / "what next" / phase planning | `bb-methodology` (5-phase orchestrator) |
| Full end-to-end hunting workflow (recon → hunt → report) | `bug-bounty` |
| Smart-contract audit (Solidity/Rust, DeFi bug classes, Foundry PoC) | `web3-audit` |
| Learning web3 methodology / case studies (zkSync, Solana, DEX LP) | `web3-playbook` |
| Meme coin / token / rug-pull / SPL / Token-2022 audit | `meme-coin-audit` |
| Subdomain enum, asset discovery, JS analysis, monitoring | `web2-recon` |
| A specific web2 bug class (IDOR, SSRF, SQLi, auth, SSTI…) | `web2-vuln-classes` |
| Automated scanning: CORS, CRLF, NoSQLi, JWT, blind SSRF/XXE, LLM red-team | `argus` |
| GraphQL endpoint testing | `graphql-audit` |
| CI/CD, GitHub Actions, supply-chain poisoning | `cicd-security` |
| Password spray / credential attacks (assess first!) | `credential-attack` |
| Android/iOS app pentest (traffic-first, then Frida/decompile) | `mobile-pentest` |
| Payloads, bypass tables, wordlists, "what NOT to submit" | `security-arsenal` |
| Validate a finding before reporting (7-Question Gate) | `triage-validation` |
| Writing / submitting a report (H1/BC/Intigriti/Immunefi) | `report-writing` |
| Client-side request signing / anti-bot token recovery | `client-reverse` |
| Replay a signed request, trace signer in JS bundles | `js-reverse` (then `client-reverse`) |
| Binary/APK/firmware/protocol reverse engineering | `reverse-skill-router` (specialist router) |
| Reverse engineering, exploitation, malware, mobile, firmware | `reverse-engineering` + specialist via `reverse-skill-router` |

### Reverse-skill sync

The reverse family (`reverse-engineering`, `js-reverse`, `client-reverse`,
`ida-reverse`, `ghidra-reverse`, `radare2`, `apk-reverse`, `mobile-reverse`,
`browser-extension-reverse`, `protocol-reverse`, `binary-diff`, `patch-diff-exploit`,
`pwn-chain`) works together with the web2/web3 suite: use `client-reverse` /
`js-reverse` when a web target signs requests, `apk-reverse`/`mobile-reverse`
when an app pins TLS, and `reverse-skill-router` as the reverse-side entry point.
`web3-audit` + `client-reverse` covers full-stack web3 targets (contracts + dApp frontend).

## Toolchain (installed at C:\Users\rival\Tools)

- `claude-bug-bounty/` — repo source: `tools/`, `scripts/`, `mcp/`, `wordlists/`, `rules/`, `commands/`, `agents/` (web3-auditor, token-auditor, recon-agent), `engine.py`/`brain.py`/`agent.py`
- Solidity testing (awesome-web3 Testing section): `mock-contract/`, `openzeppelin-test-helpers/`, `solidity-coverage/`, `waffle/`, `prb-test/`, `robot-framework-solidity-testing/`
- Pre-existing: `ghidra/`, `radare2/`, `jadx/`, `apktool/`, `SecLists/`, `ProxyCat/`, `bkcrack/`, `bin/`

## Ops master (single source of truth)

This router is the catalog-level entry for the new bug-bounty suite. The ops-level
master routing contract lives at `skills/MASTER-ROUTING.md`, its machine-readable
rules at `skills/config/routing.json` (single source of truth, read by
`scripts/master-route.ps1`), and the full matrix at `skills/routing.md` /
`routing_zh.md`. New-suite routes are registered there as **R41–R56**; RE/security
routes are **R0–R40**. For case management use `scripts/case-init.ps1` +
`ops/scope-contract.md` before ACT, evidence per `ops/evidence-finding-path.md`.

## Workflow

1. Classify the request with the routing table above.
2. Load the target skill (exact name from the table).
3. For ops-level routing, run `powershell -File skills\scripts\master-route.ps1 -Hint "<task>"` or read `MASTER-ROUTING.md`.
4. For web3 targets, check the candidate index at `bounty-candidate/README.md` (workspace) for scope/reward context.
5. Only report after `triage-validation` and write with `report-writing`.
