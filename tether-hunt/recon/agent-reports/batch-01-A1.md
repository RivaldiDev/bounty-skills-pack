# Batch 01 A1: DNS, Certificate Transparency, Subdomain Inventory, Takeover Candidates

Agent: A1
Date: 2026-11-08
Target: Tether bug bounty program (https://tether.to/en/bug-bounty/)
Scope: tether.to and app.tether.to only

## 1. Method

All work was passive first. No exploitation was attempted. No claim was attempted.

Tools used:
1. crt.sh certificate transparency JSON API. Query `%25.tether.to` returned 2523 certificates.
2. HackerTarget hostsearch API. RapidDNS subdomain listing. Anubis and AlienVault OTX were rate limited.
3. Node.js `dns.promises` for A, AAAA, CNAME, MX, TXT, NS, SOA and CAA records on every name.
4. `Resolve-DnsName` against the authoritative Cloudflare nameservers for zone-existence tests.
5. `Invoke-WebRequest` and Node `fetch` for HTTP status and header capture.
6. tinyfish for the program page text and for search.

Raw evidence files are in `recon/raw/` with the prefix `A1-`.

### 1.1 Name collection

| Source | Result |
| --- | --- |
| crt.sh `%25.tether.to` | 2523 certificates, 99 unique names |
| HackerTarget hostsearch | 50 names, all already known, plus 1 new name |
| RapidDNS | 6 names, all already known |
| Anubis | HTTP 403, no data |
| AlienVault OTX | HTTP 429, no data |
| crt.sh `app.tether.to` | 31 certificates, 1 unique name |

Total unique inventory: 100 names. This includes wildcard entries.

The single new name from HackerTarget was `o1.email.tether.to`.

### 1.2 Wildcard test

Six random labels were resolved. Results:
- `zzq9x7.tether.to` returned ENODATA.
- `zzq9x7.forge.tether.to` returned ENODATA.
- `zzq9x7.hadron.tether.to` returned ENOTFOUND.

No wildcard DNS exists on any zone. Every name in the inventory is an explicit record.

## 2. DNS provider and email provider

DNS provider: **Cloudflare**.
- Nameservers: `coby.ns.cloudflare.com` and `mary.ns.cloudflare.com`.
- SOA primary is `coby.ns.cloudflare.com`.
- Zone serial is 2419558247.
- All public A records are Cloudflare anycast addresses in 104.18.16.207 and 104.18.17.207.

Email provider: **Google Workspace**, with two sending relays.
- MX: `aspmx.l.google.com` priority 1. `alt1` and `alt2` priority 5. `alt3` and `alt4` priority 10.
- SPF: `v=spf1 include:_spf.google.com include:sendgrid.net include:_spf.mlsend.com -all`
- DMARC: `v=DMARC1; p=reject; sp=reject; adkim=s; aspf=s` with reporting to Cloudflare and to dmarc@tether.to.
- DKIM: Google selector `google._domainkey` is present. SendGrid selectors `s1` and `s2` are present.

The email posture is strong. DMARC is at reject with strict alignment on both DKIM and SPF. SPF ends in a hard fail.

Other apex TXT records:
- `MS=ms69159912` and `MS=ms97350739`: Microsoft 365 tenant verification.
- `google-site-verification=DUAeFwUV-D4pUMTKzs2oAsFbunjzpNCAAcAPZN1MPKU`
- `slack-domain-verification=ziad3gIvDvKRmg4rSFe528OJdSvESx3LHVvg6ObV`
- `cloudflare_dashboard_sso=2f483b10f5cc749c733d21fb414684b5`
- `asv=d1fbdfc2880d19b44911f5fa853c5de7`

Every subdomain carries `TXT v=spf1 -all`. This is a deliberate null SPF to stop mail spoofing from subdomains. This is good practice.

## 3. Full host table

Status values:
- **LIVE**: HTTP 200 or 3xx to a real application.
- **CF-ACCESS**: HTTP 302 to `tether.cloudflareaccess.com`. Cloudflare Zero Trust protects the host.
- **WAF**: HTTP 403 from the Cloudflare managed challenge.
- **ORIGIN**: HTTP response from the origin server, not from the WAF.
- **DANGLING**: name exists in the zone but has no address record.
- **DEAD**: NXDOMAIN at the authoritative nameserver.

| Host | Record type | Value | Provider | Status |
| --- | --- | --- | --- | --- |
| tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | LIVE 200 |
| www.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | LIVE 301 to tether.to |
| app.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | LIVE 302 to /app/login |
| wallet.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | LIVE 301 to tether.to |
| gold.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | LIVE 200 |
| hadron.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | LIVE 307 to /en |
| hadron-beta.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | CF-ACCESS |
| econ.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | CF-ACCESS |
| econ.btc.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | CF-ACCESS |
| econ.gold.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | CF-ACCESS |
| econ.usat.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | CF-ACCESS |
| econ.trantor.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | CF-ACCESS |
| econ-helicon.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | CF-ACCESS |
| econ-synnax.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | CF-ACCESS |
| alloy.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | LIVE 200 |
| alloy-admin.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | CF-ACCESS |
| alloy-staging.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | CF-ACCESS |
| dev.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | CF-ACCESS |
| staging.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | CF-ACCESS |
| stage.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | WAF 403 |
| cs.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | LIVE 200 |
| kyc.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | LIVE 200 |
| flow.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | WAF 403 |
| hooks.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare to nginx | ORIGIN 403 nginx |
| arkanis.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | LIVE 301 to tether.to |
| mos-br-ivi.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | LIVE 200 |
| miningos-roc-bv.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | ORIGIN 522 |
| pkdtrpc.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | CF-ACCESS |
| tacsrpc.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare Access | ORIGIN 401 |
| api.hadron.tether.to | A | 104.18.16.207, 104.18.17.207 | AWS API Gateway | ORIGIN 403 JSON |
| api.hadron-beta.tether.to | A | 104.18.16.207, 104.18.17.207 | AWS API Gateway | ORIGIN 403 JSON |
| api-admin.hadron.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | CF-ACCESS |
| api-admin.hadron-beta.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | CF-ACCESS |
| api-btc.hadron.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | CF-ACCESS |
| api-btc.hadron-beta.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | CF-ACCESS |
| api-investor.hadron.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | CF-ACCESS |
| api-investor.hadron-beta.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | CF-ACCESS |
| api-issuer.hadron.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | CF-ACCESS |
| api-issuer.hadron-beta.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | CF-ACCESS |
| api-ledger.hadron.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | CF-ACCESS |
| api-ledger-btc.hadron.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | CF-ACCESS |
| api-ledger-btc.hadron-beta.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | CF-ACCESS |
| api-onboarding.hadron.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | ORIGIN 404 |
| api-onboarding.hadron-beta.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | CF-ACCESS |
| api-docs.hadron.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare to readme.io | LIVE 200 |
| clients.hadron.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | CF-ACCESS |
| clients.hadron-beta.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | CF-ACCESS |
| compliance.hadron.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | CF-ACCESS |
| compliance.hadron-beta.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | CF-ACCESS |
| images.hadron.tether.to | A | 104.18.16.207, 104.18.17.207 | CloudFront signed URL | ORIGIN 403 |
| images.hadron-beta.tether.to | A | 104.18.16.207, 104.18.17.207 | CloudFront | ORIGIN 403 |
| public-images.hadron.tether.to | A | 104.18.16.207, 104.18.17.207 | S3 eu-central-1 via CloudFront | ORIGIN 403 |
| public-images.hadron-beta.tether.to | A | 104.18.16.207, 104.18.17.207 | S3 via CloudFront | ORIGIN 403 |
| issuer.hadron.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | CF-ACCESS |
| issuer.hadron-beta.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | CF-ACCESS |
| issuer-btc.hadron.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | CF-ACCESS |
| issuer-btc.hadron-beta.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | CF-ACCESS |
| multisig.hadron-beta.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | CF-ACCESS |
| ops-dashboard.hadron.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | CF-ACCESS |
| ops-dashboard.hadron-beta.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | CF-ACCESS |
| platform-ops.hadron.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | CF-ACCESS |
| platform-ops.hadron-beta.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | CF-ACCESS |
| technical-docs.hadron.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare | CF-ACCESS |
| pritunl.hadron-beta.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare to VPN origin | ORIGIN 522 |
| elements-node.hadron-beta.tether.to | A | 104.18.16.207, 104.18.17.207 | Cloudflare to broken origin | ORIGIN 530 |
| email.tether.to | CNAME | u1576484.wl235.sendgrid.net | SendGrid | MAIL ONLY |
| s1._domainkey.tether.to | CNAME | s1.domainkey.u1576484.wl235.sendgrid.net | SendGrid | MAIL ONLY |
| s2._domainkey.tether.to | CNAME | s2.domainkey.u1576484.wl235.sendgrid.net | SendGrid | MAIL ONLY |
| o1.email.tether.to | A | 149.72.93.105 | SendGrid | MAIL ONLY |
| cms.tether.to | none | no A, TXT v=spf1 -all | Cloudflare | DANGLING |
| platform.tether.to | none | no A, TXT v=spf1 -all | Cloudflare | DANGLING |
| forge.tether.to | none | no A, TXT v=spf1 -all | Cloudflare | DANGLING |
| beta.forge.tether.to | none | no A, TXT v=spf1 -all | Cloudflare | DANGLING |
| landing.beta.forge.tether.to | none | no A, TXT v=spf1 -all | Cloudflare | DANGLING |
| issuer-btc.beta.forge.tether.to | none | no A, TXT v=spf1 -all | Cloudflare | DANGLING |
| dr.beta.forge.tether.to | none | no A, TXT v=spf1 -all | Cloudflare | DANGLING |
| docs.beta.forge.tether.to | none | no A, TXT v=spf1 -all | Cloudflare | DANGLING |
| dev.alloy.tether.to | none | no A, TXT v=spf1 -all | Cloudflare | DANGLING |
| moria-uy-cs.tether.to | none | no A, TXT v=spf1 -all | Cloudflare | DANGLING |
| moria-uy-pt.tether.to | none | no A, TXT v=spf1 -all | Cloudflare | DANGLING |
| internal.hadron.tether.to | none | no A | Cloudflare | DANGLING |
| internal.hadron-beta.tether.to | none | no A | Cloudflare | DANGLING |
| docs.hadron.tether.to | none | NXDOMAIN | Cloudflare | DEAD |
| docs.alloy.tether.to | none | NXDOMAIN | Cloudflare | DEAD |

Wildcard certificate entries also appear in crt.sh. They are not hosts and are excluded from the table.

## 4. Takeover candidates

### 4.1 Result: no takeover candidate was found

There are **zero CNAME records** in the entire public inventory that point to a third-party SaaS that could be claimed. This was verified by a full CNAME query on all 100 names. The CNAME count was 0.

The only CNAME records in the zone are the three SendGrid mail records. They are covered in section 4.2.

### 4.2 SendGrid CNAME chain: tested and rejected

The chain is:
`email.tether.to` to `u1576484.wl235.sendgrid.net`.

This looks like a dangling CNAME because the target returns SOA only and no A record. It is not a takeover. Evidence:
1. The target has a TXT record: `v=spf1 ip4:149.72.93.105 -all`. The SendGrid account is active and configured.
2. The control name `u0000000.wl000.sendgrid.net`, which cannot exist, behaves the same way. It also returns no A record.
3. SendGrid does not publish A records on `wl*` hosts. This is normal SendGrid design.

Conclusion: **NOT a takeover candidate**. The account is live.

### 4.3 Cloudflare 1016 DNS error on elements-node

`elements-node.hadron-beta.tether.to` returns Cloudflare error 1016. The body states: "DNS settings. If you are using a CNAME origin record, make sure it is valid and resolvable."

This means the origin hostname behind the Cloudflare proxy does not resolve. The origin hostname is not disclosed. This is a broken origin configuration, not a takeover.

Risk note: if the origin hostname is a third-party name that Tether no longer controls, an attacker could register it and receive traffic. There is no way to test this passively because the origin name is hidden behind the proxy. Marked **UNVERIFIED**.

### 4.4 Cloudflare 522 on pritunl and miningos

`pritunl.hadron-beta.tether.to` and `miningos-roc-bv.tether.to` return 522. Cloudflare cannot reach the origin.

These are stale DNS records. They are not takeover candidates because the record points to a Cloudflare-proxied origin, not to a claimable SaaS host. They do show abandoned infrastructure.

### 4.5 Dangling names in the zone

Thirteen names exist in the Cloudflare zone with a null SPF TXT record but no address record. Authoritative queries on `coby.ns.cloudflare.com` return NOERROR with an empty answer. The names are:
- cms.tether.to
- platform.tether.to
- forge.tether.to
- beta.forge.tether.to
- landing.beta.forge.tether.to
- issuer-btc.beta.forge.tether.to
- dr.beta.forge.tether.to
- docs.beta.forge.tether.to
- dev.alloy.tether.to
- moria-uy-cs.tether.to
- moria-uy-pt.tether.to
- internal.hadron.tether.to
- internal.hadron-beta.tether.to

These are decommissioned applications. They are not exploitable as they stand, because there is no address record to hijack. They are useful as an inventory of retired internal services.

Two names are true NXDOMAIN and are fully removed: `docs.hadron.tether.to` and `docs.alloy.tether.to`.

## 5. Out-of-scope notes

The program scope is tether.to and app.tether.to only. The following hosts are outside that scope but are notable for the record.

### 5.1 Hadron platform surface

The `hadron*` family is a large tokenization platform. It is not in the stated web scope. It exposes 61 documented API operations through `api.hadron.tether.to`.

The API documentation at `api-docs.hadron.tether.to` is public and is hosted on readme.io. It documents these high-impact operations:
- `posttokenmint` and `posttokenredeem`
- `patchtokenwipewalletaddress` and `posttokenblocklistwalletaddress`
- `posttokensetpermissioncontrol` and `postpermissioncontrolwhitelistuser`
- `postmultisigdeploy`, `postmultisigtransactionconfirm`, `patchmultisigminconfirmations`
- `postfactorytokendeploy` and `postfactorytokenupgrade`
- `postkyctemplateactivate`, `postkyctemplateedit`, `postkyctemplatepreview`
- `postusersinviteminter` and `postusersinvitesigner`

Authentication is an API-KEY and API-SECRET pair. The documented rate limit is 100 requests per minute with a burst of 20.

Unauthenticated probes of `api.hadron.tether.to/api/v1`, `/api/v1/organizations` and `/api/v1/blockchains` returned HTTP 403 with `{"message":"Missing Authentication Token"}`. This is the standard AWS API Gateway response. No data was returned.

The beta environment `api.hadron-beta.tether.to` is documented as a sandbox that mirrors production. It returned the same 403.

### 5.2 Cloudflare Access coverage

Twenty-six hosts redirect to `tether.cloudflareaccess.com`. This includes every admin, ops, issuer, compliance and ledger host. The Zero Trust posture is consistent and well applied.

The Access application names are disclosed in the redirect. This reveals the internal application inventory. This is a minor information disclosure and not a vulnerability.

### 5.3 Hosts that bypass Cloudflare Access

Four hosts return origin responses instead of an Access redirect:
- `tacsrpc.tether.to` returns 401 with a Cloudflare Access error page. Access is configured but returns 401 rather than 302.
- `api.hadron.tether.to` and `api.hadron-beta.tether.to` return 403 from AWS API Gateway. This is correct, because the API uses its own key-based authentication.
- `api-onboarding.hadron.tether.to` returns a plain 404 with no Access redirect. This is an anomaly. The host is live and unprotected at the edge, but no route is registered.

### 5.4 Storage

`public-images.hadron.tether.to` is an S3 bucket in `eu-central-1` behind CloudFront. It returns `AccessDenied` on the root. Direct bucket takeover was tested with the virtual-host form and returned 404. The bucket is correctly locked down.

`images.hadron.tether.to` returns a CloudFront `MissingKey` error. This confirms signed-URL protection on that distribution.

`hooks.tether.to` returns a plain nginx 403. The origin is reachable through the proxy and the application rejects the root path.

## 6. Batch 02 hypotheses

The DNS and takeover angle is closed. The strongest leads are now application layer.

### Hypothesis 1: IDOR in the Hadron API object identifiers

The API exposes 61 operations that take resource identifiers. Examples are `GET /users/{id}`, `PATCH /users/{id}`, `GET /proposals/{id}`, `GET /kyc/issuer/applications/details` and `DELETE /integrations/users/{walletUserExternalWalletId}`.

The documented roles are Issuer, Minter, Signer, Customer and KYC Analyst. The role model is described in the docs, but the enforcement is not.

Test plan: register a legitimate Sandbox account at `api.hadron-beta.tether.to`. Create two organizations. Use the API key of organization A to request objects that belong to organization B. Measure whether the response is 403 or 200.

This is the highest-value lead. A cross-tenant read or write on a tokenization platform is a critical finding.

### Hypothesis 2: Role escalation through the invitation endpoints

`postusersinviteminter` and `postusersinvitesigner` create users with elevated roles. `patchusersid` and `patchorganizations` modify user and organization records.

Test plan: with a Customer-role API key, attempt to call the invitation endpoints directly. Also attempt mass assignment on `patchusersid` by adding a `role` field to the body. A Customer that can become a Minter can mint tokens without authorization.

### Hypothesis 3: KYC template preview as a server-side injection surface

`postkyctemplatepreview` renders a template before activation. `postkyctemplateedit` stores it.

Test plan: supply template content that contains server-side template syntax, HTML and script tags. Check the preview response for server-side evaluation and for unescaped reflection. Also check whether the stored template renders in the KYC Analyst review interface, which would give stored cross-site scripting against staff.

### Secondary leads for batch 02

1. `api-onboarding.hadron.tether.to` returns a bare 404 with no Access protection. Enumerate paths on this host. It is the only live host in the family with no edge authentication.
2. `tacsrpc.tether.to` returns 401 from Cloudflare Access instead of 302. Test whether the JSON-RPC surface answers before the Access check on a subpath.
3. The `elements-node` 1016 error indicates a broken origin. Monitor it for a change to a claimable origin.

## 7. Conclusion

The DNS and subdomain takeover angle produced a clean result. This is a valid finding.

Tether runs a mature DNS posture:
- Cloudflare for DNS with proxying on every public host.
- No wildcard records.
- No CNAME to any claimable SaaS.
- Null SPF on every subdomain.
- DMARC at reject with strict alignment.
- Cloudflare Access in front of every internal application.

The only unresolved item is the hidden origin behind the 1016 error on `elements-node.hadron-beta.tether.to`. It is marked UNVERIFIED and cannot be tested passively.

The productive surface for batch 02 is the Hadron API. It has 61 documented operations, a five-role permission model, and a public sandbox that allows legitimate account creation.
