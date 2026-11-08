# Batch 01 A5: Public code and archive mining

Agent: A5. Date: 2026-11-08.
Scope honoured: tether.to and app.tether.to only. All other hosts are leads, not targets.
Method: passive. GitHub API at low rate. Wayback CDX. Sourcify. TinyFish search. Single GET per path.

## 1. GitHub organisation and repository table

### Organisations checked

| Org | Result |
|---|---|
| tetherto | FOUND. Name "Tether". 168 public repos. Blog http://tether.to/. Created 2015-01-16. |
| tether | FOUND but unrelated. Name "Tether.id". A place-based communication platform. Not Tether. |
| Tether-Transparency | FOUND. 0 public repos. |
| Tether-io | 404. Does not exist. |
| tether-operations | 404. Does not exist. |
| TetherUS | 404. Does not exist. |
| TetherLimited | 404. Does not exist. |
| tether-tokens | 404. Does not exist. |

Full repo list saved at `recon/raw/A5-gh-repos-all.json` (168 rows).

### Repos that relate to tether.to or app.tether.to

| Repo | Relation | Verdict |
|---|---|---|
| tetherto/tether-io-bug-bounty-scope | Official scope list. WDK SDK, QVAC SDK, QVAC Workbench, Tether Wallet. | Key. See section 2. |
| tetherto/tether-api-client-ruby | Ruby client. Hardcodes `https://wallet.tether.to/api/v1`. | Key. Full API map recovered. |
| tetherto/tether-wallet-app-releases | Releases for Tether Wallet. No source. No SECURITY.md. | Low. |
| tetherto/wdk-docs | Docs for docs.wdk.tether.io. Contains `.env.example`. | Low. No secrets. |
| tetherto/tether-dev-docs | Developer docs. | Low. |
| tetherto/docs-template | Shared docs template. | Low. |
| tetherto/svc-facs-auth | Auth facade library. | Low. Test data only. |
| tetherto/svc-facs-httpd-oauth2 | OAuth2 HTTP facade. | Low. |
| tetherto/wdk-backup-cloud | Cloud backup SDK. | Low. |
| tetherto/wdk-indexer-http | Client for wdk-api.tether.io. | Medium. Names a live API host. |

**No public repo builds tether.to or app.tether.to.** The marketing site (Gatsby) and
the app (Angular) are closed source. This is a clean negative result.

The remaining ~158 repos are WDK wallet modules, QVAC local AI SDK, MDK mining kit,
PearPass password manager and MiningOS. None maps to the two in-scope web hosts.

## 2. Cloned repos and findings

Cloned into `recon/../repos/` (depth 1): tether-io-bug-bounty-scope, tether-dev-docs,
tether-api-client-ruby, tether-wallet-app-releases, wdk-docs, docs-template,
svc-facs-httpd-oauth2, svc-facs-auth, wdk-backup-cloud, wdk-indexer-http.

Secret scan: 829 files, 9 pattern families (AWS, private key, Slack, GitHub PAT,
Google API, JWT, Stripe, generic assign, Infura/Alchemy, Bitfinex key).

**Result: no live secret found.** All 55 "generic assign" hits are test fixtures or
placeholders such as `'securepassword'`, `'test_access_token'`, `'<your_token>'`.

`wdk-docs/.env.example` holds only a placeholder Inkeep key and a public GTM container
id (`GTM-M8RR2ZBL`). A GTM id is public by design. Not a finding.

### The one high-value artefact: tether-api-client-ruby

`lib/tether.rb` line 9 hardcodes `BASE_URI = 'https://wallet.tether.to/api/v1'`.
It exposes 12 API paths and the full request signing scheme. Full map at
`recon/raw/A5-tether-api-map.txt`.

Two design points matter for later batches:

1. The invoice callback signature is `md5(id + deposit_address + invoiced_amount +
   received_amount + currency + status + api_secret)`. There is no timestamp and no
   nonce. A captured callback body replays forever. The comparison uses `==`, which is
   not constant time.
2. The request signature is HMAC-SHA1 over `Content-Type,Content-MD5,path,Date`. The
   path is included. A path change breaks the signature. The Date has no skew window
   check in the client.

**Live status: wallet.tether.to is decommissioned.** Every path returns 301 to
https://tether.to/. Verified 2026-11-08. The API map is historical only.

## 3. Archived URL inventory

Wayback CDX, `collapse=urlkey`, wildcard `*.tether.to`, limit 20000. 20000 rows parsed.
Full list at `recon/raw/A5-wayback-clean.csv` (4521 rows after removing cdn-cgi and
page-data noise).

### Highlights

| Path | Note |
|---|---|
| /.well-known/security.txt | Archived 2023-05-31. **Live now returns the SPA shell, not the file.** |
| /.well-known/openid-configuration | Archived 2023-05-31. Same SPA shell. |
| /.well-known/ai-plugin.json | Archived 2023-05-31. Same SPA shell. |
| /.well-known/gpc.json, trust.txt, nodeinfo | Same SPA shell. |
| /api-documentation/ | Archived 2021-03-07. Old API docs page. |
| /balances.json | Archived 2022-05-12. Returns SPA shell. |
| /bridges.json | Archived 2025-03-20. Returns SPA shell. |
| /llms.txt, /llms-full.txt | Archived 2026-07-11. Return SPA shell. |
| /files/logos.zip, /logos.zip | Public brand assets. Benign. |
| /app/uploads/2016/06/TetherWhitePaper.pdf | Public PDF. |
| /author/admin/ | WordPress author archive from the old CMS. |
| /elementor_library-sitemap.xml | Old WordPress/Elementor site fingerprint. |
| /cdn-cgi/challenge-platform/... | Cloudflare bot management. 6629 rows. Noise. |

Status mix: 18415 x 200, 1123 x 301, 238 x 404, 115 x 204, 29 x 302, 3 x 401, 3 x 403.

### Subdomain archive probe

Probed 71 candidate subdomains against CDX. Only these returned rows:

| Host | Archive row | Live DNS today |
|---|---|---|
| app.tether.to | 2020-06-13, 301 | Live. Cloudflare. |
| platform.tether.to | 2015-03-20, 200 | No A record. |
| sandbox.tether.to | 2015-01-25, 200 | No A record. |
| dev.tether.to | 2026-02-03, 301 | Live. Cloudflare Access. |
| wallet.tether.to | 2015-05-19, 302 | Live. 301 to tether.to. |
| admin.tether.to, api.tether.to | Returned the wallet.tether.to row only. No own content. | No A record. |

## 4. New host discovery (from app.tether.to JavaScript)

I fetched `https://app.tether.to/main.386d6f3a79ed309c.js` (1.44 MB). It contains
string literals for two hosts that batch 01 did not know about:

| Host | Live check 2026-11-08 |
|---|---|
| cs.tether.to | 200. Title "Tether Support \| 24/7 Customer Support". |
| gold.tether.to | 200. XAUT gold site. |

Both resolve to the same Cloudflare IPs as tether.to. Both are subdomains of an
in-scope host. **They are NOT explicitly named in the program scope. Confirm with the
parent before any active test.** Report them as leads only.

`dev.tether.to` is fully gated. Every path returns 302 to
`tether.cloudflareaccess.com`. The redirect carries a signed JWT meta blob. No bypass
observed. This is good posture, not a finding.

## 5. Known and disclosed issues

Searched TinyFish for disclosed Tether web reports, writeups and CVEs.

**Result: no publicly disclosed web vulnerability report exists for tether.to or
app.tether.to.** Nothing on HackerOne hacktivity. Nothing on pentester.land. Nothing
on GitHub advisories for the tetherto org.

Related public material, for context only:

| Item | Class | Status |
|---|---|---|
| BlockSec, "Public transfer vulnerability of the Tether Gold smart contract" | Contract. XAUt transferFrom. | Fixed in 2020. Known. Do not duplicate. |
| Hindenburg Research $1M Tether bounty (2021) | Reserve transparency, not code. | Out of scope. |
| protos.com, "Circle and Tether bug bounties aren't enough" | Opinion. | Not a finding. |
| Tether bug bounty page itself | Program terms. | Reference. |

**Batch 02 must not re-report:** XAUt public transfer, missing security headers,
rate-limit complaints without a bypass, and scanner output.

## 6. Contract source leads

Question: does any public source match the deployed Tether bytecode exactly?

**Answer: yes for USDT on Ethereum, via Sourcify, not via GitHub.**

| Address | Contract | Compiler | Match |
|---|---|---|---|
| 0xdAC17F958D2ee523a2206206994597C13D831ec7 | TetherToken.sol:TetherToken | solc 0.4.18, optimizer OFF | **full match** (creation and runtime) |
| 0xC6CDE7C39eB2f0F0095F41570af89eFC2C1Ea828 | MultiSigWallet.sol | solc 0.4.16, optimizer ON runs=200 | full match |

The USDT proxy address itself is verified as the full TetherToken source. Verified
2024-08-08. This is the exact deployed bytecode.

**GitHub side: no `tetherto` repo contains a `.sol` file.** GitHub code search needs
authentication and returned an error page. That part is UNVERIFIED for non-tetherto
repos.

Other addresses seen in tetherto repos: XAUt `0x68749665ff8d2d112fa859aa293f07a622782f38`,
USDT Arbitrum `0xfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9`, WETH
`0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2`.

## 7. Live observations on the two in-scope hosts

### tether.to: SPA catch-all returns 200 for every path

Tested 2026-11-08, one GET each:

| Path | Status | Content type | Body |
|---|---|---|---|
| /this-path-does-not-exist-a5test | 200 | text/html | Gatsby SPA, 5875 bytes |
| /llms.txt | 200 | text/html | Gatsby SPA, 4761 bytes |
| /.well-known/security.txt | 200 | text/html | Gatsby SPA, 4761 bytes |
| /balances.json | 200 | text/html | Gatsby SPA, 5875 bytes |

**This is a soft-404 condition, not a vulnerability on its own.** It is ineligible
under the program rules (no reproducible exploit path). It matters for two reasons.
First, it hides the true 404 surface from scanners. Second, it means
`/.well-known/security.txt` is not served even though the archive shows it existed
in 2023. That is an information/process gap, not a security bug.

### app.tether.to: API route oracle

A real API route returns **200 with `{"code":401,"error":"Unauthorized"}`**.
A non-route returns **302 to `https://app.tether.to/app/login`**.

Real routes found (40 paths tested):

| Route | Response |
|---|---|
| /api/v1/balances.json | 200 `{"code":401,"error":"Unauthorized"}` |
| /api/v1/transactions.json | 200 401 JSON |
| /api/v1/transactions/1.json | 200 401 JSON |
| /api/v1/transactions/prepare.json | 200 401 JSON |

All other tested paths fell through to the SPA redirect, including admin, debug,
metrics, swagger, docs, users, me, kyc, 2fa and register.

**Assessment: the auth gate is consistent. No bypass observed.** The route oracle
itself is a useful enumeration primitive for batch 02. It is not a finding.

app.tether.to front end: Angular (`ng-app="tetherApp"`), bundles
`main.386d6f3a79ed309c.js`, `polyfills.a702f1a7ab473eaf.js`,
`runtime.f44bccf5ac8f9f10.js`. GTM `G-3HRVQ9CSXD`. robots.txt is `Disallow: /`.

### dev.tether.to

Every path 302 to `tether.cloudflareaccess.com/cdn-cgi/access/login/dev.tether.to`.
Cloudflare Access is enforced at the edge. No content leaked. Good posture.

## 8. Batch 02 hypotheses

Ranked by expected value. All are passive-first and low volume.

**H1. API route enumeration on app.tether.to via the 401 oracle.**
The oracle cleanly separates real routes from SPA fallback. Batch 02 can expand the
wordlist against `/api/v1/` and build a complete route map without touching auth.
This is the highest-value next step because it turns a black box into a map.
Risk: low. One GET per path, slow rate. Stop at 401. Do not send credentials.

**H2. Auth boundary differential on the confirmed routes.**
Four routes are confirmed. Test each with: no auth header, empty bearer,
malformed bearer, expired bearer, and a bearer for a second throwaway account.
Look for a route that returns data instead of 401. Focus on
`/api/v1/transactions/prepare.json`, because a prepare endpoint often leaks
fee, rate or address data before the auth check completes.
Risk: low if the test account is ours. Never use another user's id.

**H3. Legacy callback signature replay against any surviving invoice endpoint.**
The Ruby client shows an MD5 signature with no timestamp and no nonce. If any invoice
callback endpoint still exists on app.tether.to or a sibling host, a captured body
replays. This needs a real callback body first, so it is a conditional hypothesis.
Mark UNVERIFIED until a live endpoint is found.

**H4 (lower). cs.tether.to and gold.tether.to scope question.**
Both are live subdomains of an in-scope host and both are new to batch 01. They are
not named in the program scope. Ask the parent to decide before any test.

## 9. Honest negative results

- No public repo builds tether.to or app.tether.to.
- No live secret in any cloned repo.
- No publicly disclosed web vulnerability report for either host.
- wallet.tether.to is decommissioned. The API map is historical.
- dev.tether.to is fully gated. No bypass.
- No SQL, backup, .env or .git file recovered from the archive.
- GitHub code search is UNVERIFIED because it needs authentication.

## 10. Raw evidence index

| File | Contents |
|---|---|
| recon/raw/A5-gh-repos-all.json | 168 tetherto repos with metadata |
| recon/raw/A5-gh-repos-p1.json, p2.json | Raw GitHub API pages |
| recon/raw/A5-bb-scope-README.md | Official scope repo README |
| recon/raw/A5-wayback-tether-to-wild.json | 20000 CDX rows |
| recon/raw/A5-wayback-wild-parsed.csv | Parsed host/path/status |
| recon/raw/A5-wayback-clean.csv | 4521 rows, noise removed |
| recon/raw/A5-cdx-*.json | Per-subdomain CDX hits |
| recon/raw/A5-tether-api-map.txt | 12 API paths and signing scheme |
| recon/raw/A5-app-tether-to-api-oracle.txt | Route oracle results |
| recon/raw/A5-host-discovery.txt | DNS and HTTPS for every host |
| recon/raw/A5-contract-source-leads.txt | Sourcify match details |
| recon/raw/A5-sourcify-v2.json | Sourcify v2 response for MultiSigWallet |
| recon/raw/A5-sourcify-0xdac17f95.json | Sourcify v2 response for USDT |
| recon/raw/A5-app-login.html | app.tether.to login page |
| recon/raw/A5-app-main.js | app.tether.to main bundle (1.44 MB) |
