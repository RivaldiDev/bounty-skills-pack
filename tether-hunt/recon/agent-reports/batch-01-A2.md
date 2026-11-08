# Batch 01 - Agent A2 - tether.to Marketing Site Recon

Date: 2026-11-08
Agent ID: A2
Scope: https://tether.to and https://app.tether.to
Method: passive HTTP fetch, static bundle analysis, DNS and TLS inspection. Low request volume. No authentication attempted. No data modified.

---

## 1. Stack

Facts observed from response headers and static files.

| Item | Value | Evidence |
|---|---|---|
| Static site generator | Gatsby 4.25.9 | `<meta name="generator" content="Gatsby 4.25.9"/>` on every page |
| UI framework | React with MUI and emotion | `MuiListItem`, `data-emotion` style tags in bundles |
| CDN and WAF | Cloudflare | `server: cloudflare`, `cf-ray`, `cf-cache-status` |
| Origin web server | nginx | `/static/` returns a bare nginx 403 page |
| Edge IP addresses | 104.18.16.207, 104.18.17.207 | `Resolve-DnsName` for all tether.to hosts |
| TLS certificate | Google Trust Services WE1, CN=tether.to, SAN tether.to and *.tether.to, not after 2026-11-12 | Direct TLS handshake |
| Content source | Contentful CMS | `images.ctfassets.net/vyse88cgwfbl` asset host, `contentful` strings in bundles |
| Analytics | Google Analytics 4, tag G-T7R11WDPY5 | `https://www.googletagmanager.com/gtag/js?id=G-T7R11WDPY5` |
| Captcha | hCaptcha | `https://js.hcaptcha.com` in bug-bounty chunk |
| App backend | Ruby on Rails | `XSRF-TOKEN` cookie and `authenticity_token` form field |
| App session | Rails signed cookie `_tether_sid` | `set-cookie` on app.tether.to |
| Locales | en, ru, es | `x-locale-prefix` header, sitemap |

The marketing site is a fully static Gatsby build. It has no server side rendering at request time and no database.

---

## 2. Headers and security posture (facts only)

### 2.1 https://tether.to/ (cached shell)

Status 200. `cf-cache-status: HIT`, `age: 1763`.

Headers: `server: cloudflare`, `content-type: text/html`, `cache-control: public, max-age=14400`, `x-frame-options: allow-from https://tether.to`, `x-xss-protection: 1; mode=block`, `referrer-policy: same-origin`, `x-download-options: noopen`, `strict-transport-security: max-age=31536000; includeSubdomains;`, `x-content-type-options: nosniff`, `x-permitted-cross-domain-policies: none`, `content-security-policy: frame-ancestors https://tether.to;`.

### 2.2 https://tether.to/en/ (full page)

Status 200. `cf-cache-status: DYNAMIC`. Body length 109446 bytes.

Headers: `x-locale-prefix: /en`, `x-frame-options: deny`, `content-security-policy: frame-ancestors 'none';`, `cache-control: public, no-cache, must-revalidate`.

### 2.3 https://app.tether.to/ and /bounty

Status 302. `location: https://app.tether.to/app/login`. `cache-control: no-store`.

Cookies set:

- `XSRF-TOKEN=<43 char>` with `path=/`. No HttpOnly flag. No Secure flag. No SameSite flag.
- `_tether_sid=<long signed value>` with `domain=.app.tether.to`, `path=/`, `secure`, `HttpOnly`, expiry 3 days.

`content-security-policy: frame-ancestors https://app.tether.to;` and `x-frame-options: allow-from https://app.tether.to`.

`/app/login` also returns `content-security-policy-report-only` and `report-to` headers that point to `csp-reporting.cloudflare.com`.

### 2.4 CORS (tested)

Request to `https://app.tether.to/bounty` with `Origin: https://tether.to` returns `access-control-allow-origin: https://tether.to`.

Request with `Origin: https://evil.example` returns no `access-control-allow-origin` header.

`access-control-allow-credentials` is absent in both cases. The preflight OPTIONS request returns 204.

Conclusion: CORS is an explicit allowlist. No misconfiguration found.

### 2.5 Posture summary

- A strict `Content-Security-Policy` is absent on tether.to. Only `frame-ancestors` is set. This is a best practice item and is out of scope by program rules.
- `X-XSS-Protection` is a deprecated legacy header.
- `XSRF-TOKEN` on app.tether.to has no `Secure` and no `SameSite` attribute. The cookie is not HttpOnly by design, because JavaScript must read it.

---

## 3. Route inventory

### 3.1 robots.txt

`https://tether.to/robots.txt` returns 200, `content-type: text/plain`, 62 bytes.

Exact content:

```
#
# Default robots.txt file for tether.to
#
User-agent: *
```

The file has a `User-agent: *` line and no `Disallow` directive. It does not reference the sitemap.

### 3.2 Sitemap chain

- `/sitemap.xml` returns 200 with `content-type: text/html`. It is the Gatsby 404 page. This path is not a valid sitemap.
- `/sitemap/sitemap-index.xml` returns 200, `content-type: text/xml`, 188 bytes. It lists one child: `https://tether.to/sitemap/sitemap-0.xml`.
- `/sitemap/sitemap-0.xml` returns 200, 15339 bytes, 130 `<loc>` entries.

### 3.3 Page routes (from sitemap, 130 URLs)

The same 22 paths exist under each of three locale prefixes: none, `/en`, `/ru`, `/es`.

| Path | Notes |
|---|---|
| `/` | Home |
| `/about-us/` | |
| `/bug-bounty/` | Program page, contains the submission form |
| `/channels/` | Channel verifier, client side only |
| `/faqs/` | |
| `/fees/` | |
| `/how-it-works/` | |
| `/knowledge-base/` | Index |
| `/legal/` | |
| `/media/` | |
| `/security/` | |
| `/tether-for-exchanges/` | |
| `/tether-for-individuals/` | |
| `/tether-for-merchants/` | |
| `/transparency/` | |
| `/why-tether/` | |
| `/geo/eu/` | |
| `/supported-protocols/` | |
| `/verify-your-account/` | |
| `/deposit-tethers-to-your-account/` | |
| `/api-documentation/` | Links to app.tether.to/api/v1 |
| `/temporary-disable-transactions-tether/` | |
| `/us-residents/` | |
| `/tether-token-recoveries/` | |
| `/how-to-add-bank-info-to-your-tether-to-account/` | |
| `/deposits-of-unsupported-tokens-to-tether-to/` | |
| `/how-to-acquire-tether-tokens/` | |
| `/redeem-tethers-to-fiat-currency/` | |
| `/in-what-countries-and-states-does-tether-have-limited-functionality/` | |
| `/whitepaper/` | |
| `/transactions-supported-in-tether/` | |
| `/404/` and `/404.html` | Error pages |

### 3.4 Gatsby data routes

- `/page-data/app-data.json` returns 200 `application/json`: `{"webpackCompilationHash":"ec3607dfc0e79d6a14a0"}`
- `/page-data/en/page-data.json` returns 200 with the page model.
- `/page-data/en/bug-bounty/page-data.json` returns 200, 20053 bytes. Content is i18n message strings and legal text only. No configuration and no secrets.
- Unknown page-data paths return the Gatsby 404 HTML with status 200. Status code is not a reliable signal on this host.

### 3.5 Locale segment behaviour (tested)

The first path segment is accepted as a locale without validation. Each request below returned status 200 with the empty Gatsby shell.

| Request | `x-locale-prefix` response header |
|---|---|
| `/xx/` | `/xx` |
| `/EN/` | `/EN` |
| `/zzz/bug-bounty/` | `/zzz` |
| `/en/../xx/` | `/xx` |
| `/../en/` | `/en` |

The value is not reflected into the HTML body. Test with `/zzmarker123/` returned `markerInBody=false`.

CRLF probes `/en%0d%0aX-Injected:%20A2test/` and `/en%0aX-Injected:%20A2test/` returned no `x-locale-prefix` header and no injected header. Response splitting is not possible.

---

## 4. JS bundle table

All chunks are served from the site root. There is no `/static` prefix.

| Chunk | Bytes | Purpose |
|---|---|---|
| `app-4bc839447fea90b649be.js` | 304260 | Gatsby app shell, router, i18n |
| `framework-ce62815d8e0ce7a4fc32.js` | 128608 | React runtime |
| `webpack-runtime-969fc153af0b295d6a85.js` | 6779 | Chunk map |
| `chunk-223.js` (commons-6065149bd3a57d39c498.js) | shared | Shared modules, contains endpoint constants |
| `component---src-pages-bug-bounty-js-8ee03582a382406b575f.js` | 123587 | Bug bounty form and hCaptcha |
| `component---src-pages-index-js-41323745bd8c894d6038.js` | 101903 | Home |
| `component---src-pages-transparency-js-e0e659f241603bd75174.js` | 90759 | Transparency |
| `component---src-pages-how-it-works-js-0029f6e91742ec736077.js` | 57985 | How it works |
| `component---src-pages-about-us-js-889e65938d5a3929a1db.js` | 52381 | About |
| `component---src-pages-why-tether-js-6062fcd2f73077dcf8d4.js` | 51655 | Why Tether |
| `component---src-pages-media-js-ac9a8153044d19bb8272.js` | 48176 | Media |
| `component---src-pages-fees-js-8069ec44a1a972583441.js` | 40148 | Fees |
| `component---src-pages-security-js-54361796a40e04e3ceee.js` | 27147 | Security |
| `component---src-pages-legal-js-b420a283ed13fa167eb9.js` | 23960 | Legal |
| `component---src-pages-404-js-a523219b783bb252b065.js` | 22187 | 404 |
| `component---src-pages-tether-for-individuals-js-*.js` | 18143 | |
| `component---src-pages-tether-for-merchants-js-*.js` | 17530 | |
| `component---src-pages-faqs-js-c8f8d71c583850dc105a.js` | 14877 | |
| `component---src-pages-tether-for-exchanges-js-*.js` | 12982 | |
| `component---src-pages-geo-eu-js-c9920ab511a252ec986b.js` | 13070 | |
| `component---src-pages-channels-js-bcb9a57391ba2a0b136e.js` | 10070 | |
| `component---src-pages-contentful-knowledge-base-slug-js-*.js` | 3045 | |
| `component---src-pages-knowledge-base-js-b6337f2b7cf79f2bdafe.js` | 2446 | |

Total downloaded: 33 files. Raw copies are in `recon/raw/A2-js/`.

---

## 5. Secret findings

### 5.1 Result: no private secrets found

The following patterns were searched across all 33 bundles. Each returned zero matches.

`api_key`, `apikey`, `secret_key`, `access_key`, `auth_token`, `bearer` with a value. Stripe `pk_live` and `sk_live`. Stripe `pk_test` and `sk_test`. Firebase config and `firebaseio`. Google API key `AIza[0-9A-Za-z_-]{35}`. Algolia. Mapbox `pk.eyJ`. Sentry DSN. Private IP ranges. Internal hostnames (`.internal`, `.corp`, `.local`, `.svc`). JWT triples. AWS `AKIA`. Private key blocks. Admin routes. GraphQL endpoints. Segment. Cloudinary. Email addresses.

### 5.2 Public values found (not secrets)

| Value | Location | Note |
|---|---|---|
| `G-T7R11WDPY5` | `/en/` HTML, gtag script | Google Analytics measurement ID. Public by design. |
| `f09cc5e8-39e7-4b54-ab7f-4eb7029507bf` | bug-bounty chunk, `sitekey:"..."` | hCaptcha site key. Public by design. |
| `vyse88cgwfbl` | `images.ctfassets.net/vyse88cgwfbl` | Contentful space ID. Public by design. |
| `ec3607dfc0e79d6a14a0` | `window.___webpackCompilationHash` | Build hash. Public by design. |

### 5.3 Endpoint constants (webpack module 387 in chunk-223)

Exact source text:

```javascript
387:function(e,t,n){"use strict";n.d(t,{...});
const r="https://app.tether.to/",
      i="https://app.tether.to/app/signup/",
      o="https://tether.recruitee.com/",
      a="https://hadron.tether.to",
      s="https://app.tether.to/",
      l="https://app.tether.to/bounty",
      c="https://tether.io/news",
      u="https://usdt.directory/"
```

The export `wu` maps to `l`, which is `https://app.tether.to/bounty`. This is the bug bounty form target.

The value `https://hadron.tether.to` is a host not named in the program scope. See section 9.

### 5.4 Cookie helper (webpack module 9477 in chunk-223)

```javascript
const i="tether.to",
o=()=>document.cookie.split(";").map(...),
a=e=>o().find(t=>{let{name:n}=t;return e===n}),
s=e=>{...document.cookie=`${r}=${JSON.stringify(o)}; domain=${i}; path=/ ${t}`},
l=e=>{document.cookie=`${e}; domain=${i}; path=/; max-age=0`}
```

The helper sets and deletes cookies on `domain=tether.to` from JavaScript. No `Secure` and no `SameSite` attribute is added.

### 5.5 Hosts referenced across the site

`tether.to`, `app.tether.to`, `hadron.tether.to`, `cs.tether.to`, `gold.tether.to`, `alloy.tether.to`, `kyc.tether.to`, `tether.io`, `tetherfacts.com`, `usdt.directory`, `tether.recruitee.com`, `tether.statuspage.io`.

---

## 6. Source map status

Result: no source maps are served.

- No bundle contains a `sourceMappingURL` comment. All 33 files were checked.
- Direct requests for `.map` files return status 200 with `content-type: text/html`. The body is the Gatsby 404 page. Example: `/app-4bc839447fea90b649be.js.map`.
- The 200 status is misleading. The file does not exist.

No original source paths were recovered. No secrets were recovered from maps.

---

## 7. Exposure checks

| Path | Status | Content type | Result |
|---|---|---|---|
| `/.git/config` | 403 | text/html | Cloudflare block page |
| `/.env` | 403 | text/html | Cloudflare block page |
| `/.env.production` | 200 | text/html | Gatsby 404 page. Not a file. |
| `/package.json` | 200 | text/html | Gatsby 404 page. Not a file. |
| `/gatsby-config.js` | 404 | text/html | Not present |
| `/static/` | 403 | text/html | Bare nginx 403 page. Origin server fingerprint only. |
| `/static/does-not-exist-xyz.js` | 404 | text/html | Gatsby 404 page |
| `/admin` and `/admin/` | 200 | text/html | Gatsby 404 page. No admin panel. |
| `/api` | 200 | text/html | Gatsby 404 page. No API. |
| `/page-data/app-data.json` | 200 | application/json | Build hash only |

The `/static/` nginx 403 confirms an nginx origin behind Cloudflare. Directory listing is disabled. No file was exposed.

---

## 8. Form and endpoint inventory

### 8.1 Bug bounty submission form (`/en/bug-bounty/`)

This is the only form that sends data to a backend.

Target from bundle: `https://app.tether.to/bounty`. The code is `const a=\`\${{}.GATSBY_BUG_BOUNTY_API_PATH||Yt.wu}\`` then `fetch(a,{method:"POST",body:t})`. The build does not define `GATSBY_BUG_BOUNTY_API_PATH`. Therefore the runtime value is the fallback `Yt.wu`, which is `https://app.tether.to/bounty`.

Method: POST. Body: `FormData` with `multipart/form-data` encoding.

Fields appended, in exact source order:

| Field | Type |
|---|---|
| `name` | text |
| `email` | text |
| `bugFound` | text |
| `whichProduct` | select, values `tether.to` or `app.tether.to` |
| `levelOfRisk` | slider, default 5 |
| `bugReportSummary` | text |
| `stepsNeededToReplicate` | text |
| `impact` | text |
| `file` | file upload |
| `checkbox` | boolean |
| `HCaptcha` | hCaptcha response token |
| `authenticity_token` | value of the `XSRF-TOKEN` cookie |

The `authenticity_token` value is read from the cookie by `Zt.UL.getCookie("XSRF-TOKEN")` at component mount. Rails decodes this token to validate the CSRF check.

Response handling: the client parses JSON and reads `r.status` and `r.msg`.

Client-side throttle: `S.current` allows 3 attempts, then a 1 second wait. This is a UI counter only.

Direct GET to `https://app.tether.to/bounty` returns 302 to `/app/login` and sets a fresh `XSRF-TOKEN` and `_tether_sid`.

### 8.2 Channel verifier (`/en/channels/`)

Field: `channel`, a text input labelled "Enter URL or social media profile name". Button: "Verify".

The handler is client side only. The bundle contains zero `fetch`, zero `XMLHttpRequest`, zero `axios` and zero `sendBeacon` calls. The input is normalized and compared against a hardcoded array of official URLs.

Hardcoded allowlist: `tether.to`, `app.tether.to`, `alloy.tether.to`, `gold.tether.to`, `kyc.tether.to`, `tether.io`, `tether.recruitee.com`.

No network request is made. There is no SSRF surface here.

### 8.3 Contact form

No contact form exists. The site links to `https://tether.to/contact-us/why-use-tether/`. That path returns the Gatsby 404 page. The real contact route is not present in the sitemap.

### 8.4 Newsletter and login

No newsletter form exists on the static site.

Login and signup links point to `https://app.tether.to/app/login` and `https://app.tether.to/app/signup/`. The login form is on app.tether.to and was not tested.

### 8.5 Backend API

`/en/api-documentation/` states the API base as `https://app.tether.to/api/v1`. It links to `https://app.tether.to/app/account/settings/api-keys` for key management.

`GET https://app.tether.to/api/v1` and `GET https://app.tether.to/api/v1/` both return 302 to `/app/login`. Unauthenticated access is blocked.

---

## 9. Scope note on hadron.tether.to

The bundle constant `a="https://hadron.tether.to"` names a host that the program page does not name.

Observed facts, single request each:

- `GET https://hadron.tether.to/` returns 307 with `location: /en`.
- It sets `i18next=en; Path=/; Secure; SameSite=lax`.
- It sends a strict CSP with `strict-dynamic` and a per-request nonce.
- The CSP permits `https://hadronnews.kinsta.cloud` for style, image and font sources.
- The CSP permits `https://*.cloudflareaccess.com` in `connect-src` and `https://pv-tools.cloudflareaccess.com` in `manifest-src`. This indicates a Cloudflare Access protected application.
- The host appears to be a Next.js application with i18next.

This host is NOT in the binding scope. Do not test it. Record it for the parent only.

---

## 10. Batch 02 hypotheses

Ranked by expected value against the binding scope.

### H1. Bug bounty form CSRF and token handling (app.tether.to/bounty)

The form sends `authenticity_token` taken from a JavaScript-readable cookie. The cookie has no `SameSite` attribute. The endpoint accepts `multipart/form-data`.

Test plan:
1. Obtain a session cookie pair from `GET https://app.tether.to/bounty`.
2. Send one POST with a valid `XSRF-TOKEN` and an invalid hCaptcha token. Record the error shape.
3. Send one POST with a mismatched `authenticity_token`. Record whether Rails rejects it.
4. Check whether the endpoint accepts `application/json` or `text/plain` bodies, because those bypass preflight.

Precondition: a real hCaptcha token is needed for a full submission. Do not solve captchas at volume. One or two requests only.

### H2. File upload handling on the bounty endpoint

The form has a `file` field. The client sends it as `multipart/form-data`.

Test plan:
1. Determine the accepted content types and size limit with one small benign file.
2. Check whether the response leaks a storage URL.
3. If a storage URL is returned, check for predictable paths or public read access.

Do not upload malicious content. Use a small text file.

### H3. app.tether.to authenticated surface

The marketing site is clean. The real application is `app.tether.to`, which is in scope.

Test plan:
1. Map `/app/login`, `/app/signup/` and `/app/account/settings/api-keys`.
2. Check `/api/v1` route behaviour with a self-registered account.
3. Test IDOR on account and API key resources with two accounts owned by the tester.
4. Review the API documentation page for endpoint names.

This needs a self-registered account. Do not access other users' data.

### H4. Locale segment as a cache and routing key (low priority)

The locale segment is unvalidated. It is echoed in `x-locale-prefix` and is not reflected into HTML. CRLF injection failed.

Remaining check: whether an arbitrary locale segment can create unbounded cache entries at the Cloudflare edge. This is a resource consumption class and borders on denial of service. Do not pursue without explicit approval.

### H5. Contentful data path (out of scope unless it affects tether.to)

Page data is generated from Contentful at build time. The static output is clean. Any injection would need a Contentful write primitive, which is a third-party system. Out of scope.

---

## 11. Negative results (clean findings)

These are valid results and close off attack surface.

1. No secrets in any of the 33 JavaScript bundles.
2. No source maps are served.
3. No `.git` or `.env` exposure.
4. No directory listing on `/static/`.
5. CORS on app.tether.to is a correct allowlist with no credentials.
6. No CRLF or response splitting in the locale segment.
7. No SSRF surface in the channel verifier, because it makes no network call.
8. No admin panel or API on the marketing host.
9. No contact or newsletter form that posts data.

---

## 12. Raw evidence files

All under `recon/raw/`:

- `A2-home.html` - https://tether.to/ response body
- `A2-en.html` - https://tether.to/en/ response body
- `A2-chunk-mapping.json` - window.___chunkMapping
- `A2-robots_txt.txt` - robots.txt body
- `A2-sitemap_sitemap-index_xml.txt` - sitemap index
- `A2-sitemap-0.xml` - 130 URL sitemap
- `A2-site_webmanifest.txt` - web manifest
- `A2-api-documentation.html` - API documentation page
- `A2-page-data-bug-bounty.json` - Gatsby page data
- `A2-secret-grep.txt` - full pattern scan output
- `A2-exposure-checks.txt` - .git, .env, admin, api probes
- `A2-nginx-static-probe.txt` - /static/ nginx 403 evidence
- `A2-locale-probes.txt` - locale segment probes
- `A2-locale-crlf.txt` - CRLF injection probes
- `A2-locale-reflect.txt` - body reflection test
- `A2-tls-locale.txt` - TLS SANs and locale headers
- `A2-dns-404.txt` - DNS and 404 semantics
- `A2-pagedata-enum.txt` - page-data enumeration
- `A2-probe-*.txt` - app.tether.to and hadron.tether.to responses
- `A2-js/` - 33 downloaded JavaScript bundles

---

## 13. Statement on verification

Every status code, header and bundle string in this report comes from a live tool response in this session.

The bundle constant resolution for `Yt.wu` is a static reading of module 387. The runtime value was not confirmed by a live POST, because that needs a solved hCaptcha token. This item is marked UNVERIFIED at runtime.

The hCaptcha site key and the Google Analytics ID are public identifiers. They are not vulnerabilities.

No request was made to any host outside the binding scope except one single GET to `hadron.tether.to` to record its existence. No further requests to that host were made.
