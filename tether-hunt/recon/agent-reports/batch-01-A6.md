# Batch 01 A6: TLS, transport, mixed content and third-party script inventory

Agent: A6
Date: 2026-11-08
Targets: tether.to and app.tether.to
Scope: in scope web assets only
Method: passive first, low request volume, human rates

All results in this file come from real tool output. Raw evidence is in recon/raw/ with the prefix A6-.
Anything not proven is marked UNVERIFIED.

## 1. Executive result

The transport layer of both hosts is strong. TLS 1.0 and TLS 1.1 are refused. TLS 1.3 is the default. HSTS is present with a one year max-age and includeSubDomains. Plain HTTP always redirects to HTTPS and never serves content.

No mixed content exists on either host. No dangling DNS exists. No third-party CNAME exists.

Two real configuration weaknesses exist and neither is a reportable vulnerability by itself:

1. The Content-Security-Policy is a frame-ancestors only policy. It has no script-src, no object-src and no default-src. The site is therefore open to script injection if any injection point is found. This raises the value of every XSS lead in later batches.
2. The root path of tether.to serves two different header sets from one URL, depending on the Cloudflare cache state. The cached copy is more permissive.

The certificate transparency data gave the largest lead: 74 resolving hosts and 25 certificate names that do not resolve. These hosts are outside the named scope but are valuable leads for A1 and for the program owner.

## 2. TLS table per host

| Item | tether.to | app.tether.to |
|---|---|---|
| Default negotiated protocol | TLSv1.3 | TLSv1.3 |
| Default cipher | TLS_AES_256_GCM_SHA384 | TLS_AES_256_GCM_SHA384 |
| Key exchange group | X25519MLKEM768 | X25519MLKEM768 |
| ALPN result | h2 | h2 |
| Certificate subject | CN=tether.to | CN=app.tether.to |
| Certificate issuer | C=US, O=Google Trust Services, CN=WE1 | C=US, O=Google Trust Services, CN=WE1 |
| Root of chain | GTS Root R4, cross signed by GlobalSign Root CA | GTS Root R4, cross signed by GlobalSign Root CA |
| Public key | EC P-256 | EC P-256 |
| Signature algorithm | ecdsa-with-SHA256 | ecdsa-with-SHA256 |
| Not Before | Sep 12 12:44:04 2026 GMT | Sep 29 11:07:56 2026 GMT |
| Not After | Dec 11 13:43:48 2026 GMT | Dec 28 12:07:54 2026 GMT |
| Days to expiry at test time | 33 | 50 |
| SAN list | DNS:tether.to, DNS:*.tether.to | DNS:app.tether.to |
| Certificate policies | 2.23.140.1.2.1 (domain validated) | 2.23.140.1.2.1 (domain validated) |
| CT SCTs | 2 | 2 |
| OCSP stapling | no responses sent | no responses sent |
| Chain verification by curl | ssl_verify_result=0 | ssl_verify_result=0 |
| Edge network | Cloudflare (104.18.16.207, 104.18.17.207 and 2606:4700::6812:10cf, 2606:4700::6812:11cf) | same |

Note on openssl verify code 20: the local OpenSSL build does not have the GTS Root R4 trust anchor. curl uses the Windows trust store and reports a fully verified chain. The chain itself is complete and correct. This is a local trust store difference and not a server defect.

Note on certificate scope: the tether.to certificate uses a wildcard, DNS:*.tether.to. One wildcard certificate therefore covers every first level name under tether.to. app.tether.to uses a separate single name certificate. The wildcard is a normal commercial practice. It does widen the blast radius of any single certificate key compromise.

## 3. Protocol acceptance

| Protocol | tether.to | app.tether.to | Evidence |
|---|---|---|---|
| TLS 1.0 | REFUSED | REFUSED | SSL alert number 70, protocol_version. no peer certificate available |
| TLS 1.1 | REFUSED | REFUSED | SSL alert number 70, protocol_version. no peer certificate available |
| TLS 1.2 | ACCEPTED | ACCEPTED | Protocol TLSv1.2, default cipher ECDHE-ECDSA-CHACHA20-POLY1305 |
| TLS 1.3 | ACCEPTED | ACCEPTED | Protocol TLSv1.3, cipher TLS_AES_256_GCM_SHA384 |

Important method note: a first run of openssl with only `-tls1` printed "no protocols available". That message is a local OpenSSL 3.6 policy error and it does not prove a server refusal. The test was repeated with `-cipher DEFAULT:@SECLEVEL=0`. In that run the server sent a real TLS alert 70. The refusal above is therefore a true server side refusal.

### TLS 1.2 cipher suite acceptance

Each suite was tested alone with `-tls1_2 -cipher <suite>:@SECLEVEL=0`. Results are the same on both hosts.

| Cipher suite | Result | Class |
|---|---|---|
| ECDHE-ECDSA-AES128-GCM-SHA256 | ACCEPTED | AEAD, forward secret |
| ECDHE-ECDSA-AES256-GCM-SHA384 | ACCEPTED | AEAD, forward secret |
| ECDHE-RSA-AES128-GCM-SHA256 | ACCEPTED | AEAD, forward secret |
| ECDHE-RSA-AES256-GCM-SHA384 | ACCEPTED | AEAD, forward secret |
| ECDHE-RSA-CHACHA20-POLY1305 | ACCEPTED | AEAD, forward secret |
| ECDHE-ECDSA-AES128-SHA | ACCEPTED | CBC, forward secret |
| ECDHE-ECDSA-AES256-SHA | ACCEPTED | CBC, forward secret |
| ECDHE-RSA-AES128-SHA | ACCEPTED | CBC, forward secret |
| ECDHE-RSA-AES256-SHA | ACCEPTED | CBC, forward secret |
| ECDHE-RSA-AES128-SHA256 | ACCEPTED | CBC, forward secret |
| AES128-SHA | ACCEPTED | CBC, no forward secrecy |
| AES256-SHA | ACCEPTED | CBC, no forward secrecy |
| DES-CBC3-SHA | REFUSED | 3DES |
| ECDHE-RSA-AES128-CBC-SHA | REFUSED | alias, not a real suite name |

Facts about the accepted list:

- Twelve suites are accepted. Six of them use CBC mode.
- Two suites, AES128-SHA and AES256-SHA, do not use ECDHE. A client that offers only these suites gets no forward secrecy.
- 3DES is refused. RC4, NULL and EXPORT suites were not tested.

These suites are legacy but they are not proof of a vulnerability. CBC mode has known padding oracle attack classes (Lucky13, and the Zombie POODLE family). Those attacks need a measurable timing signal and a chosen ciphertext path. No such signal was measured in this batch. This is a hardening observation, not a finding.

## 4. HSTS

| Item | tether.to | app.tether.to |
|---|---|---|
| Header present on HTTPS | yes | yes |
| Value | max-age=31536000; includeSubdomains; | max-age=31536000; includeSubdomains; |
| max-age in seconds | 31536000 (one year) | 31536000 (one year) |
| includeSubDomains | yes | yes |
| preload directive | absent | absent |
| Header on the plain HTTP 301 | ABSENT | ABSENT |
| Status at hstspreload.org API | unknown (not preloaded) | unknown (not preloaded) |

Facts:

- The max-age is one year. This is a good value.
- The preload token is absent from the header. The hstspreload.org API also returns status unknown for tether.to, app.tether.to, gold.tether.to, cs.tether.to, alloy.tether.to and wallet.tether.to. The domain is not on the HSTS preload list.
- The plain HTTP 301 response does not carry the HSTS header. This is normal for many CDN setups and browsers ignore HSTS on plain HTTP anyway. It is recorded as a fact only.

HSTS without preload leaves the very first visit open to a downgrade if the attacker can intercept the first request. This is a known limitation and not a reportable bug on its own.

## 5. HTTP to HTTPS behaviour

Every plain HTTP request returns a 301 to the HTTPS equivalent. No content is served over HTTP on either host.

| Host | Path | HTTP status | Location |
|---|---|---|---|
| tether.to | / | 301 | https://tether.to/ |
| tether.to | /en/ | 301 | https://tether.to/en/ |
| tether.to | /en/bug-bounty/ | 301 | https://tether.to/en/bug-bounty/ |
| tether.to | /app/login | 301 | https://tether.to/app/login |
| tether.to | /robots.txt | 301 | https://tether.to/robots.txt |
| tether.to | /app/main.386d6f3a79ed309c.js | 301 | https://tether.to/app/main.386d6f3a79ed309c.js |
| app.tether.to | / | 301 | https://app.tether.to/ |
| app.tether.to | /en/ | 301 | https://app.tether.to/en/ |
| app.tether.to | /app/login | 301 | https://app.tether.to/app/login |
| app.tether.to | /robots.txt | 301 | https://app.tether.to/robots.txt |

The response body on port 80 is a 162 byte nginx default 301 page. It holds no site content.

Fact worth recording: the plain HTTP 301 from app.tether.to carries `X-Frame-Options: allow-from http://app.tether.to` and `Content-Security-Policy: frame-ancestors http://app.tether.to;`. These headers are on the redirect response only. The redirect has no frameable content, so this has no exploit path. It is a sign that the header template uses the request scheme instead of a fixed https value. This is recorded as a fact.

## 6. Third-party script table

### tether.to

The static HTML of https://tether.to/ has no third-party script, no iframe and no font.

| Resource | Origin | Vendor | Scheme | SRI |
|---|---|---|---|---|
| app-4bc839447fea90b649be.js | tether.to | first party (Gatsby 4.25.9) | https | none |
| framework-ce62815d8e0ce7a4fc32.js | tether.to | first party | https | none |
| webpack-runtime-969fc153af0b295d6a85.js | tether.to | first party | https | none |
| /cdn-cgi/challenge-platform/scripts/jsd/main.js | tether.to | Cloudflare bot management | https | none |

The Cloudflare challenge script is injected by a small inline script. It builds an iframe of 1x1 pixels and loads the script inside it. This is normal Cloudflare behaviour.

The language sub pages add a Google Analytics tag. This was found on /en/bug-bounty/, /en/legal/ and /en/.

| Resource | Origin | Vendor | Scheme | SRI |
|---|---|---|---|---|
| https://www.googletagmanager.com/gtag/js?id=G-T7R11WDPY5 | googletagmanager.com | Google Analytics 4 | https | none |

The marketing pages also contain outbound links to exchange sites and social sites. These are hyperlinks and not loaded resources. Examples are binance.com, kraken.com, coinbase.com, okx.com, x.com, youtube.com and linkedin.com. They are not third-party script.

The /en/ page also loads images from images.ctfassets.net (Contentful CDN). This is an image origin and not a script origin.

### app.tether.to

| Resource | Origin | Vendor | Scheme | SRI |
|---|---|---|---|---|
| https://www.googletagmanager.com/gtag/js?id=G-3HRVQ9CSXD | googletagmanager.com | Google Analytics 4 | https | none |
| runtime.f44bccf5ac8f9f10.js | app.tether.to | first party (Angular) | https | none |
| polyfills.a702f1a7ab473eaf.js | app.tether.to | first party | https | none |
| main.386d6f3a79ed309c.js | app.tether.to | first party | https | none |
| https://fonts.gstatic.com/s/inter/... woff2 (7 files) | fonts.gstatic.com | Google Fonts | https | n/a |
| https://fonts.gstatic.com/s/materialicons/v145/... woff2 | fonts.gstatic.com | Google Fonts | https | n/a |
| preconnect to https://fonts.gstatic.com | fonts.gstatic.com | Google Fonts | https | n/a |

The app has no iframe in the static HTML.

### Third-party inventory summary

| Vendor | Origin | tether.to | app.tether.to | Loaded over HTTPS |
|---|---|---|---|---|
| Google Analytics 4 | www.googletagmanager.com | yes, on language pages | yes | yes |
| Google Fonts | fonts.gstatic.com | no | yes | yes |
| Contentful image CDN | images.ctfassets.net | yes, images on /en/ | no | yes |
| Cloudflare bot management | tether.to/cdn-cgi | yes | UNVERIFIED | yes |

Only two third-party script origins exist: googletagmanager.com and the Cloudflare challenge platform. This is a small and well controlled third-party script surface.

No third-party script carries an integrity (SRI) attribute. This is a fact. It is not a reportable bug because the scripts come from Google and Cloudflare with strong origin control.

## 7. Mixed content result

Result: NO mixed content found.

Method: a regex search for `http://` across the full HTML of both hosts, the login page, the bug-bounty page, the legal page, the main JS bundles and the CSS.

| File | http:// found | Real resource load |
|---|---|---|
| tether.to / (cached and dynamic) | none | none |
| tether.to /en/bug-bounty/ | http://schema.org, http://www.w3.org/2000/svg | no, XML namespace and schema identifiers |
| tether.to /en/legal/ | http://schema.org, http://www.w3.org/2000/svg | no |
| app.tether.to / and /app/login | none | none |
| app.tether.to main.js | json-schema.org, localhost, www.w3.org namespaces | no |
| app.tether.to styles.css | www.w3.org/2000/svg, www.w3.org/1999/xlink | no |
| tether.to framework.js | fb.me, www.w3.org namespaces | no |

Every http:// string found is an XML namespace URI, a JSON schema identifier or a React error URL string. None of them is a fetch target. No active mixed content exists and no passive mixed content exists.

## 8. CSP summary

Both hosts send a Content-Security-Policy that has only one directive: frame-ancestors.

| Host and path | CSP value | Report-Only | unsafe-inline | wildcard |
|---|---|---|---|---|
| tether.to / (cached copy) | frame-ancestors https://tether.to; | no | not present | not present |
| tether.to / (fresh copy) | frame-ancestors 'none'; | no | not present | not present |
| tether.to /en/ and all /en/* paths | frame-ancestors 'none'; | no | not present | not present |
| app.tether.to / | frame-ancestors https://app.tether.to; | no | not present | not present |
| app.tether.to /app/login | frame-ancestors https://app.tether.to; | no | not present | not present |
| app.tether.to /app/ and /app/signup | frame-ancestors https://app.tether.to; | no | not present | not present |
| gold.tether.to / | frame-ancestors 'none'; | no | not present | not present |
| cs.tether.to / | frame-ancestors 'none'; | no | not present | not present |

Facts:

- The policy is enforced. It is not report-only.
- The policy has no script-src, no object-src, no base-uri and no default-src.
- The policy has no unsafe-inline and no wildcard. It also has no script control at all.
- The policy protects only against framing. It gives no protection against XSS.
- X-Frame-Options is also sent. It uses the obsolete allow-from form on tether.to /, app.tether.to and the app.tether.to HTTP 301.

### Root path header inconsistency on tether.to

This is reproducible and it is the most concrete configuration defect found in this batch.

A request to https://tether.to/ returns one of two header sets. The set depends on whether Cloudflare serves the request from its cache.

| Condition | cf-cache-status | Cache-Control | X-Frame-Options | CSP frame-ancestors | Last-Modified |
|---|---|---|---|---|---|
| Cached copy | HIT | public, max-age=14400 | allow-from https://tether.to | https://tether.to | Fri, 30 Oct 2026 16:42:02 GMT |
| Fresh copy | DYNAMIC | public, no-cache, must-revalidate | deny | 'none' | Fri, 30 Oct 2026 16:42:03 GMT |

Reproduction:

1. Request https://tether.to/ with no query string. The response is the cached copy with the permissive header set. This was stable across 5 consecutive requests and 3 different User-Agent strings.
2. Request https://tether.to/?x=zz1. The response is the fresh copy with the strict header set.
3. The HTML body is byte identical in both cases. Only the headers differ.

Impact assessment: LOW and not reportable.

- The cached copy allows framing only from https://tether.to itself.
- Browsers ignore the allow-from form of X-Frame-Options. They fall back to same-origin.
- Modern browsers enforce CSP frame-ancestors and it overrides X-Frame-Options.
- The net effect is that only tether.to can frame the page in both cases.
- No attacker origin gains framing ability.
- The defect shows that a stale edge object holds an older, weaker header policy. It is a caching hygiene issue.

## 9. Leads

These leads are for A1 and for later batches. Most of them are outside the named scope. They are listed here as leads and not as targets.

### 9.1 Certificate transparency names that do not resolve

Source: crt.sh query for %.tether.to. 2523 certificate entries gave 99 unique names.

These names appear in certificates but have no A record. Some return SOA only and some return NXDOMAIN.

| Name | DNS state | Note |
|---|---|---|
| cms.tether.to | SOA only, no A | content management system |
| platform.tether.to | SOA only, no A | platform console |
| forge.tether.to | SOA only, no A | forge product |
| beta.forge.tether.to | SOA only, no A | forge beta |
| dr.beta.forge.tether.to | SOA only, no A | disaster recovery |
| landing.beta.forge.tether.to | SOA only, no A | landing page |
| issuer-btc.beta.forge.tether.to | SOA only, no A | BTC issuer |
| docs.beta.forge.tether.to | SOA only, no A | docs |
| dev.alloy.tether.to | SOA only, no A | alloy dev |
| internal.hadron.tether.to | SOA only, no A | internal hadron |
| internal.hadron-beta.tether.to | SOA only, no A | internal hadron beta |
| moria-uy-cs.tether.to | SOA only, no A | regional |
| moria-uy-pt.tether.to | SOA only, no A | regional |
| docs.alloy.tether.to | NXDOMAIN | docs |
| docs.hadron.tether.to | NXDOMAIN | docs |

No CNAME record exists for any of these names. There is therefore no dangling DNS takeover surface. A name with only SOA and no A record cannot be taken over.

### 9.2 Certificate names that do resolve, and are not in the named scope

74 names resolve. All of them point to the same two Cloudflare IPv4 addresses and two IPv6 addresses. A wildcard DNS test with three random names returned no A record, so these are explicit records and not a catch-all.

High value names from a security review view:

| Name | Observed state |
|---|---|
| staging.tether.to | 302 to tether.cloudflareaccess.com, Cloudflare Access protected |
| dev.tether.to | 302 to tether.cloudflareaccess.com, Cloudflare Access protected |
| pritunl.hadron-beta.tether.to | certificate serves, HTTP returned 000 (no response) |
| api.hadron.tether.to | HTTP 403 |
| api-admin.hadron.tether.to | UNVERIFIED |
| multisig.hadron-beta.tether.to | UNVERIFIED |
| ops-dashboard.hadron.tether.to | UNVERIFIED |
| platform-ops.hadron.tether.to | UNVERIFIED |
| pkdtrpc.tether.to | UNVERIFIED |
| tacsrpc.tether.to | UNVERIFIED |
| wallet.tether.to | 301 to https://tether.to/ |
| gold.tether.to | 200, live application |
| cs.tether.to | 200, live support site |
| alloy.tether.to | UNVERIFIED |
| alloy-admin.tether.to | UNVERIFIED |
| alloy-staging.tether.to | UNVERIFIED |
| kyc.tether.to | UNVERIFIED |
| econ.tether.to | UNVERIFIED |

The full resolving list is in recon/raw/A6-ct-resolving.txt. The non resolving list is in recon/raw/A6-ct-not-resolving.txt.

A note on the Cloudflare Access redirect: the 302 to tether.cloudflareaccess.com contains a signed meta JWT. The JWT payload shows the hostname, the audience, the redirect URL, the auth status and the client country. It is a normal Cloudflare Access artefact and it is not a finding. It does confirm that staging.tether.to and dev.tether.to sit behind an identity aware proxy.

### 9.3 Hosts named in the app bundle that are not in the public DNS list

The app.tether.to main bundle names two hosts that are not in the batch 01 public DNS list:

- cs.tether.to, used as the SUPPORT link
- gold.tether.to, used as the Tether Gold information link and as the legal link base

Both resolve and both serve live content. Both are outside the named scope.

### 9.4 Out of scope hosts seen in page content

These hosts appear in the tether.to page content but they are explicitly out of scope:

- tether.recruitee.com
- tether.statuspage.io

They were not tested.

### 9.5 Missing CAA records

No CAA record exists for tether.to, app.tether.to, cs.tether.to or gold.tether.to. The DoH query returned the SOA in the Authority section and no Answer section. Any public certificate authority can issue a certificate for any name under tether.to. This is a fact. It is a hardening point and not a reportable bug. The certificate transparency monitoring that Tether already does is the compensating control.

## 10. Batch 02 hypotheses

These hypotheses follow from what this batch proved. Each one names the test and the expected proof.

### H1. XSS has full impact because the CSP gives no script control

Why this is strong: the CSP on both hosts has only frame-ancestors. There is no script-src, no object-src and no default-src. A successful injection therefore runs unrestricted. There is no CSP mitigation to bypass.

Test: take every reflection and injection lead from A2 (tether.to marketing site) and A3 (app.tether.to). Confirm whether an injected script executes in a real browser.

Proof needed: a browser screenshot of the payload executing, plus the request and response pair.

Scope note: only tether.to and app.tether.to are valid hosts for this test.

### H2. The app.tether.to analytics path rewrite can leak a secret token

Why this is strong: the app has an inline function named replaceGoogleAnalyticsPath. It rewrites /password/<token> to /password/secret_token and /secure_upload/<token> to /secure_upload/secret_token before the value goes to Google Analytics as page_location. The presence of this function shows that the team knows a secret can appear in the URL path. The rewrite is a blocklist of two patterns.

Test: find other routes that carry a secret in the path, for example a reset token, an invite token, a KYC session, a 2FA enrolment token or a payment reference. Confirm whether the raw value reaches page_location.

Proof needed: a captured gtag request that shows the unredacted secret in the page_location parameter.

Constraint: this test needs an authenticated account. It must not touch another user's data. Stop if the test needs another user's token.

### H3. The root path cache variant can be forced to serve the weaker header set

Why this is strong: one URL returns two different header sets. The cached copy is the weaker one. The Cache-Control on the fresh copy is no-cache, must-revalidate. The cached copy has max-age=14400.

Test: measure how long the cached object lives and whether a request with a different Accept-Encoding or a different method can seed a new cached object. Check whether any other path has the same split.

Proof needed: a reproducible sequence that shows a chosen response header set on a URL that should have the other one.

Value note: this is a low severity path. It is worth a short test only. Do not spend a full batch on it.

### Lower value directions, listed so they are not repeated

- CBC cipher suites: no timing oracle was measured. Do not test padding oracle attacks without a chosen ciphertext path and a measurable signal.
- HSTS preload: a missing preload token is a hardening point. It is ineligible as a best practice item.
- Missing SRI: both third-party scripts come from Google and Cloudflare. This is ineligible as a best practice item.
- Missing CAA: a hardening point. It is ineligible on its own.
- Dangling DNS: no CNAME exists. This direction is dead.

## 11. Scope and rules compliance

- Only tether.to and app.tether.to were requested as targets.
- gold.tether.to, cs.tether.to, wallet.tether.to, staging.tether.to, dev.tether.to, pritunl.hadron-beta.tether.to and api.hadron.tether.to received one HEAD or GET request each for TLS and status confirmation. They are outside the named scope and no further testing was done on them.
- No denial of service was attempted.
- No fuzzing was done.
- No credential attack was done.
- No user data was accessed.
- Every request rate was low and human.

## 12. Raw evidence index

All files are in recon/raw/ with the prefix A6-.

| File | Contents |
|---|---|
| A6-tether.to-sclient-default.txt | full openssl s_client output, chain and session |
| A6-app.tether.to-sclient-default.txt | full openssl s_client output, chain and session |
| A6-tether.to-cert.txt | full X.509 text for the leaf certificate |
| A6-app.tether.to-cert.txt | full X.509 text for the leaf certificate |
| A6-*-tls1.txt, A6-*-tls1_1.txt | first run, local policy error |
| A6-*-tls1-seclevel0.txt, A6-*-tls1_1-seclevel0.txt | real server refusal, alert 70 |
| A6-*-tls1_2.txt, A6-*-tls1_3.txt | accepted protocol runs |
| A6-*-tls12-ciphers.txt | TLS 1.2 cipher negotiation |
| A6-*-http80-root.txt | plain HTTP 301 response |
| A6-*-https-head.txt | HTTPS response headers |
| A6-*-https-body.html | full HTML of each host |
| A6-app.tether.to-login-head.txt | login page headers |
| A6-app.tether.to-login-body.html | login page body |
| A6-tether.to-bug-bounty-page.html | bug bounty page with the GA tag |
| A6-tether.to-root-cached.html | root body from the cached copy |
| A6-tether.to-root-dynamic.html | root body from the fresh copy |
| A6-app.tether.to-main.js | app main bundle, 1.4 MB |
| A6-app.tether.to-styles.css | app stylesheet |
| A6-app.tether.to-runtime.js | app runtime bundle |
| A6-app.tether.to-polyfills.js | app polyfills bundle |
| A6-tether.to-app.js | marketing site app bundle |
| A6-tether.to-framework.js | marketing site framework bundle |
| A6-crtsh-tether.to.json | crt.sh certificate transparency export |
| A6-ct-resolving.txt | 74 certificate names that resolve |
| A6-ct-not-resolving.txt | 25 certificate names that do not resolve |
