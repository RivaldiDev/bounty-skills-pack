# Hunt log — Tether

All times are Asia/Jakarta (UTC+7).

## 2026-11-08

- 18:06 Intake. Operator sent https://tether.to/en/bug-bounty/.
- 18:07 Program page fetched. Scope captured: tether.to, app.tether.to, Tether Tokens Smart Contracts. Out of scope: tether.recruitee.com, tether.statuspage.io.
- 18:08 Reference pass. Read altnero-bounty, proton-bounty and acepyr-bb-hunt. House layout, severity model and finding template mirrored.
- 18:09 Folder created: tether-bounty/ with README.md, SCOPE.md, findings/FINDING-TEMPLATE.md.
- 18:10 Batch 01 plan authored. Six angles. Deploy pending.
- 18:09 Batch 01 deployed. Six agents, one angle each.
- 18:10 Operator track started in parallel: app.tether.to surface, USDT contract.
- 18:12 app.tether.to mapped. Angular build, 28 lazy chunks, full endpoint inventory.
- 18:13 Unauthenticated probe. /api/v1/int/vasps returns 2,159 counterparty records with no session.
- 18:15 A4 returned. Email posture clean. DMARC p=reject with strict alignment.
- 18:15 A2 returned. No secrets in 33 bundles. Bounty form posts to app.tether.to/bounty.
- 18:15 A3 returned. Full route and endpoint map. Two auth filters observed.
- 18:16 USDT source pulled from Sourcify. Rebuild with solc 0.4.18 is byte-identical to mainnet.
- 18:20 A6 returned. TLS strong. CSP is frame-ancestors only.
- 18:23 A5 returned. Both sites closed source. Route oracle confirmed.
- 18:24 Foundry fork harness built. 7 of 7 tests pass against live USDT.
- 18:26 CORS tested on app.tether.to. Correct allowlist. No finding.
- 18:28 Geo-block header trust tested. No bypass. Control is not header driven.
- 18:30 A1 returned. Zero CNAMEs to claimable SaaS. No takeover.
- 18:31 Batch 01 complete. One candidate (C1) and a large set of dead ends.
- 18:32 Batch 02 plan authored from batch 01 output.
- 18:33 Batch 02 deployed. Six agents: API oracle, bounty form, unauth differential, XAUt, cross-chain USDT, Gatsby data.
- 18:34 Operator track: XAUt pulled. It is a TransparentUpgradeableProxy (2,141 bytes) with implementation 0x4c0d2c74... and proxy admin 0x856fcc08...
- 18:35 XAUt implementation source verified exact_match on Sourcify, solc 0.8.4, TetherToken by Will Harborne.
- 18:36 XAUt permit domain separator recomputed by hand and matches on chain. EIP-712 domain is correct.
- 18:37 FINDING CANDIDATE C2: the XAUt implementation contract is directly callable and has its own live state. owner() on the implementation returns 0x7224BEef47a6A7B414a0d0AdADf3f691C2691005, which is not the proxy owner. totalSupply() on the implementation returns 1. The implementation owner is an EIP-7702 delegated EOA with nonce 107.
- 18:38 C2 triage opened. Question: can any unprivileged caller use the implementation state to affect the proxy or user funds?
