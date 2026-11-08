# Batch 02 agent B2: the bug bounty submission form

Agent: B2. Date: 2026-11-08. Scope: tether.to and app.tether.to only.
Angle: the bug bounty submission form at app.tether.to/bounty.

Total requests this batch: about 55. All unauthenticated GET, OPTIONS and POST.
No report was submitted. No account was used. No file larger than 23 bytes was uploaded.

## Verdict summary

The form endpoint is hardened at the authentication layer. Every POST, with or without a
CSRF token, with any content type, returns the same 200 JSON error. The CSRF layer is never
reached, so CSRF enforcement could not be tested. This is NOT a CSRF bypass.

One correction to the batch 01 premise is important. The bounty form is not part of the
app.tether.to application. It is a server rendered form on tether.to. That form posts
cross origin to app.tether.to/bounty. The app.tether.to Angular application has no bounty
route at all.

| # | Test | Result | Verdict |
|---|---|---|---|
| 1 | GET /bounty with cookie jar | 302 to /app/login. Sets XSRF-TOKEN and _tether_sid | EXPECTED |
| 2 | OPTIONS preflight POST /bounty | 204 with no Access-Control-* headers | CORRECT |
| 3 | POST empty body, no authenticity_token | 200 {"status":"error","msg":"Unauthorized!"} | NOT A CSRF BYPASS, see T3 |
| 3b | POST with invalid authenticity_token | 200, identical body | INDISTINGUISHABLE from 3 |
| 3c | POST with VALID authenticity_token | 200, identical body | GATE IS BEFORE CSRF |
| 4 | POST as application/json | 200, identical body | NO CONTENT TYPE BYPASS |
| 4b | POST as text/plain | 200, identical body | NO CONTENT TYPE BYPASS |
| 5 | POST multipart, file field only, 23 byte text | 200, identical body | NO UPLOAD PROCESSING |
| 6 | Response leak check | No URL, bucket, path or stack trace | CLEAN |
| 7 | Server side captcha and rate limit | Not testable. Gate rejects first | UNVERIFIED |

## Test 1: GET /bounty with a cookie jar

Request:

    GET /bounty HTTP/1.1
    Host: app.tether.to
    User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) ... Chrome/131.0.0.0 Safari/537.36
    Accept: text/html,application/xhtml+xml

Response:

    HTTP/1.1 302 Found
    Location: https://app.tether.to/app/login
    Cache-Control: no-cache
    Set-Cookie: XSRF-TOKEN=8OFdjOIMoPT8g2sJENE49RAunrCHEkCPqWBrQ4z_Tt6-PyRQmW17yJylzFNMheS7DZSsaTVNOrxQtwATdd3yVQ; path=/
    Set-Cookie: _tether_sid=<long value>; domain=.app.tether.to; path=/; expires=...; secure; HttpOnly
    X-Frame-Options: allow-from https://app.tether.to
    Content-Security-Policy: frame-ancestors https://app.tether.to;

Evidence: raw/B2-01-get-bounty.txt, raw/B2-cookies.txt

Verdict: EXPECTED. The GET is redirected to the login page. The XSRF-TOKEN cookie has
path=/ and no Secure flag and no SameSite flag. This matches the batch 01 note. The
_tether_sid cookie is secure and HttpOnly.

## Test 2: OPTIONS preflight for POST /bounty

Request:

    OPTIONS /bounty HTTP/1.1
    Host: app.tether.to
    Origin: https://tether.to
    Access-Control-Request-Method: POST
    Access-Control-Request-Headers: x-xsrf-token,content-type

Response:

    HTTP/1.1 204 No Content
    Vary: Origin, Access-Control-Request-Method, Access-Control-Request-Headers
    X-Frame-Options: allow-from https://app.tether.to
    X-XSS-Protection: 1; mode=block
    Referrer-Policy: same-origin
    X-Content-Type-Options: nosniff
    Strict-Transport-Security: max-age=31536000; includeSubdomains;

Evidence: raw/B2-02-options-bounty.txt, raw/B2-37-options-from-tether-to.txt

Verdict: CORRECT. The response is 204. It contains NO Access-Control-Allow-Origin, NO
Access-Control-Allow-Methods and NO Access-Control-Allow-Headers. A browser therefore
blocks a cross origin POST with a custom header such as X-XSRF-TOKEN.

This creates a design conflict. The tether.to form posts cross origin to app.tether.to/bounty
and reads a XSRF-TOKEN cookie. The preflight denies the custom header. The form can only
work if the browser sends the request as a simple request with no custom header. See H1.

## Test 3: CSRF enforcement

### Test 3: empty body, no authenticity_token

    POST /bounty HTTP/1.1
    Content-Type: application/x-www-form-urlencoded
    Origin: https://app.tether.to
    Referer: https://app.tether.to/bounty
    Content-Length: 0

    HTTP/1.1 200 OK
    Content-Type: application/json; charset=utf-8
    Access-Control-Allow-Origin: https://app.tether.to

    {"status":"error","msg":"Unauthorized!"}

Evidence: raw/B2-03-post-empty-nocsrf.txt

### Test 3b: invalid authenticity_token

    POST /bounty
    Content-Type: application/x-www-form-urlencoded

    authenticity_token=INVALIDTOKEN_DEADBEEF_0000

    HTTP/1.1 200 OK

    {"status":"error","msg":"Unauthorized!"}

Evidence: raw/B2-04-post-invalid-csrf.txt

### Test 3c: VALID authenticity_token (the control test)

The token was the decoded value of the XSRF-TOKEN cookie from the same session.
The token was sent both as the X-XSRF-TOKEN header and as the authenticity_token form field.

    POST /bounty
    Content-Type: application/x-www-form-urlencoded
    X-XSRF-TOKEN: <valid token from cookie>

    authenticity_token=<valid token from cookie>

    HTTP/1.1 200 OK

    {"status":"error","msg":"Unauthorized!"}

Evidence: raw/B2-05-post-valid-csrf.txt

### Test 3d: no cookie at all, and forged session cookie

Both returned the same 200 Unauthorized body.

Evidence: raw/B2-14-post-no-cookie.txt, raw/B2-15-post-forged-session.txt

Verdict: NOT A CSRF BYPASS. The control test is decisive. A valid token and an absent token
produce byte identical responses. The request is rejected before the Rails CSRF check runs.
The status is 200 instead of 422 because the application returns its own JSON error, not a
Rails CSRF exception. The 200 status is a design choice and not a finding by itself.

The correct behaviour for this endpoint is a 422 CSRF error. The endpoint does not give one.
It gives an authentication error instead. The security result is the same, because the
request is not processed.

## Test 4: content type confusion

    POST /bounty  Content-Type: application/json  body: {}
    POST /bounty  Content-Type: text/plain        body: hello

Both returned HTTP 200 with {"status":"error","msg":"Unauthorized!"}.

Evidence: raw/B2-06-post-json.txt, raw/B2-07-post-textplain.txt

Verdict: NO BYPASS. The application/json body did not reach the CSRF layer. The response is
identical to the form encoded case. The Rails CSRF bypass class that depends on a non form
content type does not apply here, because the authentication gate runs first.

## Test 5: file upload field

Two requests. The file was a 23 byte text file named b2-test.txt with type text/plain.

    POST /bounty  multipart/form-data  field "file" only
    POST /bounty  multipart/form-data  fields "authenticity_token" and "file"

Both returned HTTP 200 with {"status":"error","msg":"Unauthorized!"}.

Evidence: raw/B2-08-post-multipart-fileonly.txt, raw/B2-09-post-multipart-file-token.txt

Verdict: NO UPLOAD PROCESSING. The multipart parser did not create a storage object, because
the request was rejected first. No storage URL, bucket name or internal path appeared.

## Test 6: response leak check

No response contained a storage URL, a bucket name, an internal path, a stack trace or a
framework version banner. The only server header is "cloudflare". The Rails default error
page was not reached.

One 404 page was observed on a nonexistent path. It is a static branded page that redirects
to https://tether.to. It leaks no framework detail.

Evidence: raw/B2-12-post-nonexistent-path.txt

Verdict: CLEAN.

## Test 7: server side captcha and rate limit

Not testable in this batch. The authentication gate rejects every request before the
captcha field or the rate limiter can act. Any rate limit test would measure the gate and
not the form.

Verdict: UNVERIFIED. Do not test the limit. The program forbids rate limit complaints without
a bypass.

## The important structural finding

The batch 01 note says the tether.to bug bounty page posts a multipart FormData to
https://app.tether.to/bounty. This is correct. The new fact is that app.tether.to does not
host the form.

Proof 1: the form is server rendered on tether.to. The page https://tether.to/en/bug-bounty/
contains the input elements name="bugFound", name="whichProduct" and the hCaptcha widget.
Evidence: raw/B2-28-tether-bounty-page.txt.

Proof 2: the submit handler is in the Gatsby page chunk
component---src-pages-bug-bounty-js-8ee03582a382406b575f.js. The handler builds a FormData
with these fields in this order: name, email, bugFound, whichProduct, levelOfRisk,
bugReportSummary, stepsNeededToReplicate, impact, file, checkbox, HCaptcha, authenticity_token.
It then calls fetch(API_PATH, {method:"POST", body:formData}).
Evidence: raw/B2-30-bugbounty-chunk.js.

Proof 3: the API_PATH constant resolves to the literal string "https://app.tether.to/bounty".
It is exported as wu from webpack module 387 in commons-6065149bd3a57d39c498.js:

    l="https://app.tether.to/bounty"

Evidence: raw/B2-34-commons.js.

Proof 4: the authenticity_token value comes from document.cookie XSRF-TOKEN on the tether.to
origin. The handler calls getCookie("XSRF-TOKEN") and appends the raw value. It does not
decode it.
Evidence: raw/B2-30-bugbounty-chunk.js.

Proof 5: the tether.to origin sets no XSRF-TOKEN cookie. A GET of /en/bug-bounty/ and a GET
of /en/ both returned no Set-Cookie header at all.
Evidence: raw/B2-35-tether-to-headers.txt.

Proof 6: the app.tether.to Angular application has no bounty route. All 28 lazy chunks were
downloaded and searched. The strings "bounty", "bugFound", "levelOfRisk" and "whichProduct"
have zero occurrences in all 28 chunks. The guest route table contains only login, geo,
password, password/:token, signup and signup/:token. The authenticated route table contains
only activity, deposit, account and 2fa.
Evidence: raw/B2-chunk-*.js, raw/B2-25-chunk13-guest.js, raw/B2-26-chunk94-app.js.

Proof 7: GET /app/bounty returns the Angular shell with HTTP 200. This is the single page
application fallback. The shell contains no bounty content. It is not a server rendered form.
Evidence: raw/B2-22-app-bounty-body.html.

## Negative results written down

- No CORS bypass. The allowlist is exactly https://tether.to and https://app.tether.to.
  The response has no Access-Control-Allow-Credentials header.
  Evidence: raw/B2-17 through raw/B2-20.
- No CSRF bypass. The authentication gate runs first.
- No content type bypass.
- No upload processing and no storage leak.
- No route on app.tether.to serves a bounty form.
- No XSRF cookie is issued on the tether.to origin.

## Hypotheses for batch 03

### H1: the cross origin form cannot send a CSRF token, so the server must accept a session bound token or no token

This is the strongest hypothesis. Three facts conflict:
1. The form posts cross origin from tether.to to app.tether.to.
2. The preflight denies the X-XSRF-TOKEN header.
3. The tether.to origin issues no XSRF-TOKEN cookie.

So the browser sends a simple POST with no custom header. The authenticity_token field is
empty. For the form to work at all, the server must accept a request with no authenticity
token. That is a CSRF weakness by design.

To confirm: a real browser run of the tether.to form would show whether the request carries
an empty authenticity_token and whether the server accepts it. This needs one controlled
submission, which is out of scope for batch 02. Do not test it without operator approval and
without a real report.

Alternative explanation, which must be tested first: the server sets the XSRF-TOKEN cookie on
app.tether.to from a prior visit, and the browser sends it on the cross origin POST as a
credential only if the request includes credentials. A simple POST with multipart body does
include cookies by default. The token would then be present in the cookie but absent from
the body field. Rails accepts the token from the form field or the X-CSRF-Token header, not
from a cookie named XSRF-TOKEN. So the field would still be empty.

### H2: the authentication gate on POST /bounty is the real surface

The gate returns a custom JSON error and not a Rails error. It runs before CSRF and before
parameter parsing. That means the gate is an application level check. The next step is to
find what the check reads. Candidates are the _tether_sid cookie, a header, or an IP range.
A differential test with a controlled cookie set is low risk and in scope. Do not attempt to
forge a session.

### H3: the file field is accepted before validation

The handler appends e.fileInput to the FormData with no client side type or size check in
the extracted code. If the gate is passed, the server side validation of the file is the
next question. This needs an authenticated path and is therefore held for batch 03.

## Files

Raw evidence: recon/raw/B2-01 through B2-37, plus B2-chunk-*.js and the harness scripts
B2-harness*.js.

## Method note

Every POST used an empty or deliberately invalid payload. No complete report was ever built.
The file upload used a 23 byte plain text file. No request was repeated more than needed.
Sleep between requests was 600 to 750 ms.
