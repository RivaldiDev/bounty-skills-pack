# Batch 01 — consolidated output

Six angles. All six returned and are consolidated here.

All times are Asia/Jakarta (UTC+7). All requests were unauthenticated and at human rate.
No account was created. No state-changing request was sent. No email was sent.

## Result summary

| Angle | Agent | Outcome |
|---|---|---|
| DNS, certificate transparency, subdomain takeover | A1 | Clean. Zero CNAMEs to claimable SaaS. No takeover. |
| tether.to marketing site, bundles, secrets | A2 | No secrets. No source maps. CORS is a correct allowlist. |
| app.tether.to app, auth, API surface | A3 | Full route and endpoint map. One unauthenticated data endpoint. |
| Email posture (SPF, DMARC, DKIM) | A4 | Clean. DMARC p=reject with strict alignment. Paid spoofing class not met. |
| Public code and archive mining | A5 | Both sites are closed source. Route oracle found. Legacy API client reviewed. |
| TLS, transport, mixed content | A6 | Strong TLS. No mixed content. CSP is frame-ancestors only. |
| Operator track: contract audit | operator | USDT source verified byte-identical. 7 fork tests pass. No unprivileged path. |

## The one candidate that survived batch 01

### C1 — Unauthenticated counterparty VASP directory

`GET https://app.tether.to/api/v1/int/vasps` returns 2,159 counterparty records with no
session, no token and no referer. 2,136 records bind a business name to a did:ethr Ethereum
address. Response size 179,992 bytes.

The endpoint is a travel-rule directory. The question for triage is whether the pairing of a
legal business name with an Ethereum address is non-public data. See analysis/C1-vasps.md.

## What batch 01 killed

| Lead | Why it died |
|---|---|
| Email spoofing through SPF or DMARC | DMARC p=reject, sp=reject, strict alignment, SPF 4 lookups ending -all |
| CORS misconfiguration | Allowlist reflects only https://tether.to. No credentials header. |
| Mixed content | None on either host |
| Dangling DNS and subdomain takeover | No CNAMEs in the zone. No wildcard DNS. |
| Secret in JS bundles | Zero hits across 33 tether.to bundles and 31 app bundles |
| Source map disclosure | No sourceMappingURL. .map requests return the SPA 404 page. |
| SSRF through the channel verifier | The verifier makes zero network calls. It is a client side allowlist. |
| GraphQL surface | No GraphQL string in any bundle |
| Weak TLS | TLS 1.0 and 1.1 refused. TLS 1.3 default. |
| Missing security headers | Ineligible by program rules |
| Contentful delivery token | Public by design |
| hCaptcha site key | Public by design |
| USDT contract owner paths | onlyOwner guards hold. Fork tests T2 pass. |

## What batch 01 raised for batch 02

1. Route oracle on app.tether.to. A real route answers 200 with {"code":401,"error":"Unauthorized"}.
   A non-route answers 302 to /app/login. This turns the API into a map.
2. Two different auth filters. /account, /balance and /announcements redirect to the origin root.
   /account/states redirects to /app/login. Two code paths can mean one is weaker.
3. The bug bounty form itself posts to app.tether.to/bounty. It is in scope and it is a
   multipart upload with an hCaptcha gate.
4. The CSP is frame-ancestors only on both hosts. Any XSS would run with full effect.
5. The password is pre-hashed in the browser with PBKDF2-HMAC-SHA512 at 2,000 iterations.
   If the server stores that value, an offline crack is cheap.
6. Reset and secure-upload tokens travel in the URL path as base64 JSON.

## Scope decision recorded here

The program names only tether.to and app.tether.to. The following hosts are live and are
subdomains of tether.to, but they are not named in the program:

- cs.tether.to (support portal)
- gold.tether.to (Tether Gold)
- hadron.tether.to (Cloudflare Access protected)
- dev, staging, stage, kyc, alloy, api.hadron, ops-dashboard.hadron

Decision: these are leads only. They are not probed and they are not reported as targets.
A finding on one of them would be argued out of scope under the program text.

## Files

| File | Contents |
|---|---|
| recon/batch-01-A2.md | tether.to marketing site |
| recon/batch-01-A3.md | app.tether.to application |
| recon/batch-01-A4.md | email posture |
| recon/batch-01-A5.md | public code and archive |
| recon/batch-01-A6.md | TLS and transport |
| recon/batch-01-A1.md | DNS and certificate transparency |
| analysis/app-tether-to-surface.md | operator track, app surface |
| analysis/usdt-contract-audit.md | operator track, USDT contract |
| poc/usdt-contract/ | Foundry fork harness, 7 tests |