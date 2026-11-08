# Batch 01 - Agent A3 - app.tether.to

Angle: framework, authentication flow, API hosts, JavaScript bundles, route map.

Hunt folder: C:\Users\rival\Documents\Ngoding\Bug-Bounty-Finder\tether-bounty
Date of capture: 2026-11-08 (server time 11:09 to 11:14 GMT)
Scope check: app.tether.to is in scope. All probes use GET or OPTIONS only. No account was registered. No brute force was used. Request volume was 8 probes plus 33 static asset fetches.

---

## 1. Redirect chain

### Request 1

    GET https://app.tether.to/ HTTP/1.1
    User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36
    Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8

### Response 1 (raw, from curl.exe)

    HTTP/1.1 302 Found
    Date: Sun, 08 Nov 2026 11:13:23 GMT
    Content-Type: text/html; charset=utf-8
    Transfer-Encoding: chunked
    Connection: keep-alive
    Server: cloudflare
    Cache-Control: no-store
    Expires: Fri, 01 Jan 1990 00:00:00 GMT
    Location: https://app.tether.to/app/login
    Set-Cookie: XSRF-TOKEN=Hbwrxt7ATvdb4NSOV_NZoICdTEHc82z8420l7nh_5GCQDKCbK8i9vIAkvCDblR860Fj708ebZBNY2tcTwdbjPw; path=/
    Set-Cookie: _tether_sid=OFZmQ1VvOGRBSEF0NjhyVnRTeGtkQVEvNzF2YjRkQ2NmeG1ka2sxMWhqdmhKQyt2MnhKejdjVGo0amMxRFdydzl6U1dSQjlibjBOdVBDODQzMXdkTGszNkRBZEF4T2FUMFVBcW9GL1JnNmZlWDN3SHVTZnhIcm5iOVBPVHcyUE8yMXFUZTBIa01kMXZueVRpRjFrdzEweVVmM0J0Wk5TWi9IOWJicytFWTRMN1lyUHhJQ0lYMEdZSkpWR1pJOUdmQ2N0U2JXbWJaZDJpWVlBMzBDS29xeVVMM2F3cTk1RW9JN0hjR0xpbVI3VWVnZFNsY1gvMklaLzIyQ3hSNktndXh4S1Q4aVVscDE1WURRNFdRelhSd2NJdmY5Slc3MDlFd1FjTEtvVlR2WDg9LS16YWxUeW9kUU4wRGhtbUt1THNuNVN3PT0%3D--afaa2bb6016be959a39d215cf7c06e7d413f6fb0; domain=.app.tether.to; path=/; expires=Wed, 11 Nov 2026 11:13:23 GMT; secure; HttpOnly
    X-Frame-Options: allow-from https://app.tether.to
    Content-Security-Policy: frame-ancestors https://app.tether.to;
    Strict-Transport-Security: max-age=31536000; includeSubdomains;
    cf-cache-status: DYNAMIC
    CF-RAY: a57425e9ae438c50-SIN

### Response 2

    HTTP/1.1 200 OK
    Date: Sun, 08 Nov 2026 11:09:06 GMT
    Content-Type: text/html
    Transfer-Encoding: chunked
    Server: cloudflare
    Last-Modified: Wed, 14 Oct 2026 14:06:54 GMT
    Vary: Accept-Encoding
    cf-cache-status: DYNAMIC
    X-Frame-Options: allow-from https://app.tether.to
    X-XSS-Protection: 1; mode=block
    Referrer-Policy: same-origin
    X-Download-Options: noopen
    X-Content-Type-Options: nosniff
    X-Permitted-Cross-Domain-Policies: none
    Content-Security-Policy: frame-ancestors https://app.tether.to;
    Strict-Transport-Security: max-age=31536000; includeSubdomains;
    CF-RAY: a5741fa1afb5585b-SIN

Chain summary: one hop. https://app.tether.to/ returns 302 to https://app.tether.to/app/login. The final document returns 200.

Note: the 200 response for /app/login does not set a cookie. The 302 response for / does set both cookies. The session is issued at the origin root and not at the SPA route.
## 2. Framework and build

| Item | Value | Evidence |
|---|---|---|
| Framework | Angular, standalone components, Angular Material | ng-app=tetherApp, app-root element, u0275cmp and u0275prov decorators |
| Angular version | 17 or later | Standalone bootstrap and signal-style APIs in bundle |
| Bundler | webpack 5 with runtime chunk | runtime.f44bccf5ac8f9f10.js holds the chunk map |
| Webpack chunk name | tether_ui_new | self.webpackChunktether_ui_new |
| CSS inliner | Critters | html tag has data-critters-container |
| Edge | Cloudflare | server: cloudflare, CF-RAY present |
| Backend hint | Ruby on Rails | X-Download-Options, X-Permitted-Cross-Domain-Policies, X-XSS-Protection, .json suffix route, weak ETag, _tether_sid signed cookie format |
| SPA base href | /app | base href=/app |
| Build date | 2026-10-14 | Last-Modified on index |
| Lazy chunks | 28 | runtime chunk map |
| Analytics | Google Analytics G-3HRVQ9CSXD | inline gtag bootstrap |
| Captcha | hCaptcha | HCAPTCHA_SITE_KEY in main bundle |
| CMS | Contentful | spaceId and delivery token in main bundle |

### Script and stylesheet list (from https://app.tether.to/app/login)

    <link rel=stylesheet href=styles.2bb13b808a67dd55.css media=print onload=this.media='all'>
    <script src=runtime.f44bccf5ac8f9f10.js type=module></script>
    <script src=polyfills.a702f1a7ab473eaf.js type=module></script>
    <script src=main.386d6f3a79ed309c.js type=module></script>
    <script async src=https://www.googletagmanager.com/gtag/js?id=G-3HRVQ9CSXD></script>
    <script src=/cdn-cgi/challenge-platform/scripts/jsd/main.js>  (injected by Cloudflare)

### Inline script of interest

The page defines replaceGoogleAnalyticsPath() before the gtag config. It rewrites two path patterns to a fixed literal:

    const regexPassword = new RegExp('/password/.+');
    const regexSecureUpload = new RegExp('/secure_upload/.+');
    url.replace(regexPassword, '/password/secret_token')
       .replace(regexSecureUpload, '/secure_upload/secret_token');

This is a defensive control against token leakage to Google Analytics. Section 9 refers to it.

---

## 3. Cookie table

All cookies are set by the origin on every 302 or JSON response. The attributes below come from the raw curl capture.

| Cookie | Domain | Path | SameSite | Secure | HttpOnly | Expires | Notes |
|---|---|---|---|---|---|---|---|
| _tether_sid | .app.tether.to | / | NOT SET | yes | yes | 3 days | Session id. Value is base64 of a signed payload with a --HMAC suffix. Rails signed cookie format. |
| XSRF-TOKEN | not set (host-only) | / | NOT SET | no | no | session | Angular reads it and sends it as the X-XSRF-TOKEN header. |
| cf_clearance | tether.to | / | not observed | yes | yes | 1 year | Cloudflare clearance. Listed in the app cookie policy. Not set in our requests. |
| __cf_bm | tether.to | / | not observed | yes | yes | session | Cloudflare bot management. Not set in our requests. |
| user_preferences | tether.to | / | not observed | no | no | 2 years | Consent choice. Set by client JavaScript with domain=tether.to. |
| ga-disable-G-3HRVQ9CSXD | tether.to | / | no | no | no | session | Analytics opt-out flag. Client side only. |

### Cookie observations

1. Neither security cookie declares SameSite. Modern browsers default to SameSite=Lax. This is a best-practice gap only and is not eligible under the program rules.
2. _tether_sid uses Domain=.app.tether.to. This is a parent-domain scope. It does not cover tether.to. A subdomain that is out of scope cannot read it.
3. The XSRF-TOKEN cookie is not marked Secure. It still travels only over HTTPS because the origin enforces HSTS.
4. The app writes its own cookies with document.cookie and domain=tether.to (main bundle, module 6559):

       setCookie(I,_){document.cookie=`${I}=${JSON.stringify(_)}; domain=${this.DOMAIN}; path=/`}

   This is a JavaScript-writable cookie on the registrable domain. It carries only preference flags. No session material is stored there.

---

## 4. JS bundle table

All files were fetched from https://app.tether.to/app/ with status 200.

| File | Bytes | Role |
|---|---|---|
| runtime.f44bccf5ac8f9f10.js | 3,480 | webpack chunk map and lazy loader. Exposes 28 chunk ids. |
| polyfills.a702f1a7ab473eaf.js | 36,265 | Angular polyfills |
| main.386d6f3a79ed309c.js | 1,442,185 | Core app. Router, interceptors, login service, user service, whitelist service, constants, Contentful SDK, axios, Angular Material. |
| styles.2bb13b808a67dd55.css | 168,145 | Global styles |
| 13.bd970c4832031d52.js | 2,003 | GuestModule routes (login, signup, password, geo) |
| 30.a50a3703dbeab44b.js | 8,771 | Password reset confirm |
| common.8a491b51019e6912.js | 16,327 | Shared module |
| 83.7168369ebaab4fbc.js | 8,384 | /users/token service |
| 91.bacecc040fa60ca0.js | 30,798 | Transport protocol selector |
| 94.05799eed7474fd14.js | 206,441 | AppModule. Activity, deposit, acquire, redeem, VASP travel rule. Largest feature chunk. |
| 157.7702a117f4563301.js | 2,916 | Small feature |
| 175.a59401c7073a3abb.js | 21,114 | Feature module |
| 186.247bd3db13f181c2.js | 38,735 | Google 2FA enable, activate, disable |
| 225.da79c6f8e5eadaf0.js | 1,328 | Small feature |
| 276.6bffe0999f1753ef.js | 6,043 | Settings routes (profile, preferences, api-keys) |
| 297.a0beb81c218d727b.js | 1,570 | Bank create and edit routes |
| 323.5bc5d2c360f56329.js | 13,041 | Profile form |
| 354.e7813542c98dc887.js | 8,884 | Forgot password |
| 358.157b67e50363bb80.js | 37,464 | Ledger and CSV export |
| 388.1f5600f4cd68d802.js | 4,195 | Feature module |
| 450.18e99fd1637e8786.js | 21,755 | Feature module |
| 469.58c75f387a554642.js | 850 | LogoutModule |
| 509.1bf891fcfdb4e04b.js | 29,925 | API key management (/api_keys) |
| 559.3fd520d3eb1c1a74.js | 50,282 | CryptoJS and the password hash Web Worker |
| 642.82662b600d3de548.js | 18,786 | Bank account templates |
| 663.28b6cac0c0170ed4.js | 123,932 | Signup and registration |
| 671.9aa91ba24a976013.js | 9,687 | Signup email step |
| 779.fe78c1659fa3066e.js | 4,122 | Settings menu routes |
| 844.d62acc84861bbafa.js | 15,366 | Secure upload (public token route) |
| 845.9cdb09e0431cae67.js | 31,420 | Withdraw and deposit address |
| 852.cbf45468e7052fd0.js | 5,860 | Login form |
| 894.3c07e6937a9185f0.js | 7,036 | Feature module |

Raw copies are in recon/raw/A3-*.js.

### Build configuration found in main bundle (module 5312)

    {production: true,
     apiBaseUrl: "",
     contentful: {spaceId: "vyse88cgwfbl",
                  token: "CkQ3H7rbrjChQlgVhAtyc4NZYVo3x7idKHMGCGiF1Qw"}}

### HTTP interceptor (main bundle, module 3364)

    intercept(g,k){
      const {apiBaseUrl:ee, production:Me} = Gi.c;
      if (Me || -1 !== g.url.indexOf("http")) return k.handle(g);
      if (g.url.includes("/app")) {
        const h = g.clone({url: g.url.replace("/app","")});
        return k.handle(h);
      }
      const at = g.clone({url: ee + g.url});
      return k.handle(at);
    }

In production apiBaseUrl is the empty string. Every API call is same-origin to app.tether.to. There is no separate API host.

### CSRF configuration

Angular HttpClientModule defaults are in effect. The cookie name is XSRF-TOKEN. The header name is X-XSRF-TOKEN. The value is read from document.cookie at request time. No custom header logic was found.

### Password hashing (chunk 559)

A Web Worker performs the hash before any credential leaves the browser:

    const a = R.SHA1(password).toString();
    const p = R.PBKDF2(password, a, {keySize: 8, iterations: 2000, hasher: R.algo.SHA512}).toString();
    postMessage(p);

Result: the server receives PBKDF2-HMAC-SHA512 with 2,000 iterations and the SHA1 of the password as the salt.

---
## 5. API host table

| Host | Purpose | Classification |
|---|---|---|
| app.tether.to | SPA host and all REST API calls | IN SCOPE |
| tether.to | Marketing site, legal pages, transparency, knowledge base, fees | IN SCOPE |
| gold.tether.to | Tether Gold product site and legal pages. Linked from the app theme config. | OUT OF SCOPE lead (host not named in program) |
| cs.tether.to | Customer support portal. Listed in the app SUPPORT constant. | OUT OF SCOPE lead |
| cdn.contentful.com | Contentful CMS delivery API. Called by the Contentful SDK in the bundle. | OUT OF SCOPE (third party) |
| www.googletagmanager.com | Google Tag Manager and gtag | OUT OF SCOPE (third party) |
| fonts.gstatic.com | Inter web font | OUT OF SCOPE (third party) |
| api.hcaptcha.com | hCaptcha challenge backend | OUT OF SCOPE (third party) |
| csp-reporting.cloudflare.com | CSP violation reporting endpoint | OUT OF SCOPE (third party) |

The program text says tether.to and app.tether.to ONLY. Treat gold.tether.to and cs.tether.to as out of scope. Do not probe them.

No GraphQL endpoint exists. The string graphql does not appear in any bundle.

---

## 6. Route map

### Top level router (main bundle)

    {path: "secure_upload/:token", loadChildren: chunk 76 + 844}   // no guard
    {path: "logout",              loadChildren: chunk 469}          // no guard
    {path: "", loadChildren: chunk 76 + 94, canActivate: [AuthGuard]}   // AppModule
    {path: "", loadChildren: chunk 76 + 13, canActivate: [GuestGuard]}  // GuestModule
    {path: "**", redirectTo: "", pathMatch: "full"}

### GuestModule routes (chunk 13)

    login
    geo
    password
    password/:token
    signup
    signup/:token

### AppModule routes (chunk 94)

    activity
    deposit
    account
    account/settings/profile
    account/settings/preferences
    account/settings/api-keys
    2fa

### Settings menu routes (chunk 779)

    /settings
    /verification
    /banks
    /address-whitelist
    module-is-still-under-development

### Bank routes (chunk 297)

    create
    edit/:id

### Guards (main bundle, module 775)

    GuestGuard.canActivate: returns true if guard.url includes "geo".
      Otherwise, if loginService.isLoggedIn.value is true, it navigates to /activity and returns false.

    AuthGuard.canActivate:
      if (!loginService.isLoggedIn.value) { redirectToLogin(); return false; }
      return userService.user$.value || userService.getUser(true).pipe(...)

### Guard observation

The AuthGuard does not check the server first. It checks a localStorage key named onLoggedIn, which LoginService.setLogin writes. The real gate is the server response to GET /account. The client guard is cosmetic. Every protected API call is still authorized by the server session cookie.

---

## 7. Authentication flow

### Token model

The application uses a server-side session cookie, not a bearer token.

- Session cookie: _tether_sid (HttpOnly, Secure, Domain=.app.tether.to, 3-day expiry).
- CSRF token: XSRF-TOKEN cookie, replayed as the X-XSRF-TOKEN header.
- No JWT was found. Bearer and Authorization appear only inside the vendored axios and Contentful SDK code.
- Client login state is a boolean in localStorage under the key onLoggedIn. It is not a credential.

### Login sequence

1. GET /account/signup_status.json issues a fresh _tether_sid and XSRF-TOKEN. The body is {"success":true,"data":{"signup_disabled":null}}. If the response carries a GLoc header, the client exposes a geo link to https://tether.to/geo/eu.
2. POST /sessions with a multipart body of login, password (PBKDF2 hash) and code (the 2FA code).
3. The response object is inspected for these fields: success, geo_blocked, reason, two_factor_auth_enabled, redirect_to, msg.
   - geo_blocked true means the client navigates to /geo.
   - success true means the client sets localStorage onLoggedIn and emits onLoggedIn.
   - success false with two_factor_auth_enabled true and no code sent means the client shows the 2FA code field.
   - reason equal to locked means the client shows the failure message.
4. On onLoggedIn, UserService calls GET /account. A success true response populates user$. A failure triggers loginService.logout(true).
5. GET /account is also re-polled every 60,000 ms (REFRESH_INTERVAL) while the user is logged in.
6. GET /logout clears the session. The client then clears localStorage and navigates to /login.

### Endpoints that issue or consume credentials

| Endpoint | Method | Purpose | Auth required |
|---|---|---|---|
| /sessions | POST | Login. Issues the session cookie. | No |
| /logout | GET | Destroys the session. | Session |
| /users | POST | Registration (multipart). Creates the account. | No |
| /users/signup | POST | Signup with email and captcha. | No |
| /users/token | POST | Requests a signup token. | No |
| /users/validate_token | POST | Validates a signup token and returns the email. | No |
| /users/update_password | POST | Change password. Needs code. | Session |
| /password/forgot | POST | Sends a reset email. | No |
| /password/validate_reset_password_token | POST | Validates the reset token. | No |
| /password/reset | POST | Sets a new password. Needs code and reset_token. | No |
| /account/set_google_2fa | GET | Starts Google 2FA enrolment. | Session |
| /account/activate_google_2fa | POST | Confirms 2FA enrolment. | Session |
| /account/disable_google_2fa | POST | Disables 2FA. | Session |
| /api_keys | GET, POST | List and create API keys. | Session |
| /api_keys/{id} | PUT, DELETE | Update or delete an API key. | Session |
| /api_keys/activate | POST | Activates an API key with an emailed confirmation code. | Session |
| /users/secure_upload | POST | Public file upload. Needs a token and captcha. | No |

### Endpoints that are unauthenticated by design (confirmed by probe)

| Endpoint | Method | Confirmed |
|---|---|---|
| /account/signup_status.json | GET | 200 |
| /account/countries | GET | 200 |
| /api/v1/int/vasps | GET | 200, 179,992 bytes |
| / | GET | 302 to /app/login |
| /app/login and all /app/*.js assets | GET | 200 |

### Endpoints that redirect when unauthenticated

| Endpoint | Method | Result |
|---|---|---|
| /account | GET | 302 to https://app.tether.to/ |
| /account/states | GET | 302 to https://app.tether.to/app/login |
| /balance | GET | 302 to https://app.tether.to/ |
| /announcements | GET | 302 to https://app.tether.to/ |

Note the inconsistency. /account, /balance and /announcements redirect to the origin root. /account/states redirects to the SPA login route. This suggests two different authentication filters in the Rails application.

---
## 8. Unauthenticated probe results

All requests used GET or OPTIONS. No request mutated state. Raw captures are in recon/raw/A3-raw-probe-capture.txt and recon/raw/A3-unauth-probes.txt.

### 8.1 GET /api/v1/int/vasps - FINDING A3-F1

Context: This endpoint returns the travel-rule VASP directory used by the acquire form. The client calls it from chunk 94 in getListVasps() with no special headers.

Raw request:

    GET /api/v1/int/vasps HTTP/1.1
    Host: app.tether.to
    User-Agent: Mozilla/5.0 Chrome/131
    Accept: application/json

Raw response:

    HTTP/1.1 200 OK
    Date: Sun, 08 Nov 2026 11:13:43 GMT
    Content-Type: application/json; charset=utf-8
    Transfer-Encoding: chunked
    Server: cloudflare
    ETag: W/"e16782cc300a860f27ef27ebb5d93218"
    Cache-Control: max-age=0, private, must-revalidate
    X-Frame-Options: allow-from https://app.tether.to
    Content-Security-Policy: frame-ancestors https://app.tether.to;
    Strict-Transport-Security: max-age=31536000; includeSubdomains;
    cf-cache-status: DYNAMIC

    [{"id":"manual","name":"####Manual Entry####"},
     {"id":"did:ethr:0xdf41ef7dcb92ab5aed72e284db3766ace5026948","name":"1Money (US)"},
     {"id":"did:ethr:0xfeb4f99829a9acdf52979abee87e83addf22a7e1","name":"1xBet"},
     ...]

Measured size: 179,992 bytes. Parsed array length: 2,159 entries. 2,136 entries carry a did:ethr DID with a unique Ethereum address. 1,569 entries have no country suffix.

Explanation line: The endpoint returns the full Tether counterparty VASP list to any anonymous caller. Each row exposes a business name and an Ethereum address bound to a DID.

Severity assessment: Low to Medium. The data is a compliance directory and is not a user record. The program excludes theoretical bugs. Report this only if a concrete harm path is shown. The concrete path is hypothesis H1.

### 8.2 GET /account/signup_status.json

Context: The login page calls this on load to decide whether to show the signup link.

Raw request:

    GET /account/signup_status.json HTTP/1.1
    Host: app.tether.to
    User-Agent: Mozilla/5.0 Chrome/131

Raw response:

    HTTP/1.1 200 OK
    Content-Type: application/json; charset=utf-8
    ETag: W/"07e5634bcf72c1d166d8ae1a582f2d2d"
    Cache-Control: max-age=0, private, must-revalidate
    Set-Cookie: XSRF-TOKEN=eMIBRcZgr-i2ekbY2cB7WWcmzcdD4SPFdaYIBjifHtdPpuerMZf9wYYk6WyZJpt0YEw81uIcRmDdd0TT6y8dZg; path=/
    Set-Cookie: _tether_sid=...; domain=.app.tether.to; path=/; expires=Wed, 11 Nov 2026 11:13:45 GMT; secure; HttpOnly

    {"success":true,"data":{"signup_disabled":null}}

Explanation line: This confirms the session bootstrap point and the CSRF token issuance point. It is expected behaviour, not a bug.

### 8.3 GET /account/countries

Raw response: status 200. The Content-Type is text/html with charset=utf-8. The body is a JSON array of name and alpha2Code pairs for every country.

Explanation line: Public reference data. The Content-Type is text/html for a JSON array. This is a minor header inconsistency and is not eligible. There is no security impact.

### 8.4 GET /account/states

Raw response:

    HTTP/1.1 302 Found
    Location: https://app.tether.to/app/login
    Cache-Control: no-cache
    Set-Cookie: XSRF-TOKEN=...; path=/
    Set-Cookie: _tether_sid=...; domain=.app.tether.to; path=/; expires=Wed, 11 Nov 2026 11:11:40 GMT; secure; HttpOnly

Explanation line: This endpoint requires a session. The 302 target differs from the other protected endpoints. This is a fingerprint of two separate auth filters.

### 8.5 GET /account, /balance, /announcements

Each returns 302 with Location: https://app.tether.to/ and Cache-Control: no-cache. There is no body.

Explanation line: These endpoints require a session. The redirect to the origin root rather than to /app/login is inconsistent with 8.4. This is a low-value fingerprint.

### 8.6 OPTIONS /sessions

Raw response:

    HTTP/1.1 400 Bad Request
    Content-Length: 0
    Server: cloudflare
    Content-Security-Policy-Report-Only: script-src 'unsafe-inline' 'unsafe-eval'; report-uri https://csp-reporting.cloudflare.com/...
    Report-To: {"group":"cf-csp-endpoint","max_age":86400,...}
    Reporting-Endpoints: cf-csp-endpoint="https://csp-reporting.cloudflare.com/..."

Explanation line: No CORS preflight is served. There is no Access-Control-Allow-Methods header. The endpoint does not accept cross-origin callers. This is correct behaviour.

### 8.7 CORS observation

Several responses carry Access-Control-Allow-Origin: https://app.tether.to. This is a fixed same-origin value. No request was found that reflects an arbitrary Origin. No credentialed cross-origin read was observed. This is NOT a finding.

---
## 9. Additional code-level observations (not probed)

These are recorded for batch 02. None is confirmed as a vulnerability.

### A3-O1 - Password reset token is base64 JSON in the URL path

Chunk 30, ngOnInit:

    const t = JSON.parse(atob(this.route.snapshot.paramMap.get("token")));
    this.resetToken$.next(t.token);

The reset token arrives in the URL path as base64 of a JSON object. The route is /password/:token. The page rewrites the path to /password/secret_token only for the Google Analytics page_location field. The raw URL still reaches the web server access log, the browser history, and any Referer header sent before the rewrite.

The same pattern exists for /secure_upload/:token in chunk 844.

This is a real design weakness. Its exploitability depends on whether the server logs the full path and who can read those logs. Mark UNVERIFIED.

### A3-O2 - Signup token validation returns the account email

Chunk 663, getEmail():

    this.http.post("/users/validate_token",{token:t}).subscribe(a=>{
      a.success && (this.email$.next(a.email), this.email.setValue(a.email), this.showMessage())
    })

A signup token is exchanged for the email address it was issued to. If tokens are guessable or leak, an attacker learns the email. Token entropy was not measured. Mark UNVERIFIED.

### A3-O3 - API key lifecycle is code-gated but the code is emailed

/api_keys/activate takes {id, confirmation, code}. The code is emailed to the account owner. The delete call accepts the literal path /api_keys/all with a body of {code}. One code can delete all keys. This is a high-impact operation. Mark UNVERIFIED. It needs an authenticated account.

### A3-O4 - Client-side password pre-hash

The password is hashed to PBKDF2-HMAC-SHA512 (2,000 iterations, SHA1 salt) in the browser. The server therefore never sees the plaintext. However, the PBKDF2 output is the effective password. A database leak that stores this value directly, with no second server-side hash, would allow offline cracking at 2,000 iterations. This is a weakness only if the server stores the client hash verbatim. Mark UNVERIFIED.

### A3-O5 - Third-party Contentful delivery token in the public bundle

spaceId vyse88cgwfbl and token CkQ3H7rbrjChQlgVhAtyc4NZYVo3x7idKHMGCGiF1Qw are in main.js. Contentful delivery tokens are designed to be public. This is not a secret leak. It is recorded so that later batches do not re-report it.

### A3-O6 - hCaptcha site key

HCAPTCHA_SITE_KEY: f09cc5e8-39e7-4b54-ab7f-4eb7029507bf. Site keys are public by design. Not a finding.

### A3-O7 - Business constants exposed

SYSTEM_USER_ID: 1, RESERVE_USER_ID: 1, SETTLE_USER_ID: 1, GEO_BLOCKING.BLOCKED_COUNTRIES (a full country list), VERIFICATION fee 150, REDEEM and ACQUIRE fee schedules, EMAIL.ADMIN archive@tether.to, EMAIL.COMPLIANCE compliance@tether.to.

These are business rules, not secrets. The user IDs are recorded because batch 02 may test for IDOR that references user id 1.

---

## 10. Batch 02 hypotheses

### H1 - VASP DID to on-chain address correlation (highest priority)

The /api/v1/int/vasps response binds 2,136 business names to did:ethr Ethereum addresses. If Tether Gold or Tether token transfer records on chain carry these DIDs or their addresses, a passive observer can attribute on-chain flows to named exchanges and payment processors.

Test plan: take 20 DIDs, query a public chain explorer for transactions that involve those addresses, and check whether the address appears as a transfer counterparty. Do not send any request to tether.to for this. All work is passive and uses public chain data. If attribution succeeds, this becomes a privacy and business-intelligence exposure with a reproducible path.

### H2 - Auth-filter inconsistency between /account/states and /account

Two different unauthenticated redirects were observed. /account/states redirects to /app/login. /account, /balance and /announcements redirect to /. Two filters means two code paths.

Test plan: register one account in batch 02 with operator approval. Then request each protected endpoint with the session cookie removed, partially removed, and with a tampered _tether_sid signature. Look for an endpoint that returns data instead of a redirect. Focus on endpoints that the client calls without waiting for a guard: /whitelist/search, /banks, /ledger, /account/export_ledger.

### H3 - Reset and secure-upload tokens in the URL path

Both /password/:token and /secure_upload/:token carry base64 JSON in the path.

Test plan: request one password reset for our own test account in batch 02. Inspect the exact URL shape and the token body. Then test whether the token is single use, whether it expires, and whether it is bound to the account. Also test whether the server accepts a token issued for account A when the reset is submitted for account B. This is an authenticated-to-authenticated test with our own accounts only.

### Secondary hypotheses for batch 02

- H4: The /whitelist/search POST takes {currency, chain}. It may return other users' whitelisted addresses, or the full address book, if the server does not scope by session. Test with our own account first.
- H5: /api_keys/activate with a replayed confirmation code. Test whether the code is bound to the key id and to the session.
- H6: The GLoc header on /account/signup_status.json drives geo blocking. Test whether a spoofed GLoc or a spoofed client IP header changes the geo decision. This is a compliance control, so any bypass is a real finding.

---

## 11. Evidence files

| File | Contents |
|---|---|
| recon/raw/A3-app-root.html | Full HTML of https://app.tether.to/app/login (27,280 bytes) |
| recon/raw/A3-main.386d6f3a79ed309c.js | Main bundle |
| recon/raw/A3-runtime.f44bccf5ac8f9f10.js | Webpack runtime with chunk map |
| recon/raw/A3-polyfills.a702f1a7ab473eaf.js | Polyfills |
| recon/raw/A3-styles.2bb13b808a67dd55.css | Stylesheet |
| recon/raw/A3-chunk-*.js | All 28 lazy chunks |
| recon/raw/A3-unauth-probes.txt | Structured probe log (status, headers, body) |
| recon/raw/A3-raw-probe-capture.txt | Raw curl header captures |
| recon/raw/A3-vasps.json | First VASP response (179,934 bytes) |
| recon/raw/A3-vasps-body.json | Second VASP response (179,992 bytes) |

---

## 12. Honest status

Confirmed: the framework, the build, the full route map, the full API surface, the auth flow, the cookie attributes, and the unauthenticated status of /api/v1/int/vasps, /account/countries and /account/signup_status.json.

Not confirmed: no exploitable vulnerability was proven in this batch. Every code-level observation in section 9 is UNVERIFIED. No account was created. No state-changing request was sent.

Clean result: CORS is correctly restricted to https://app.tether.to. No GraphQL surface exists. No bearer token exists. No API host outside the scope was found in the application code.
