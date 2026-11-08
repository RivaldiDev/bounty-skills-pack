# Analysis — app.tether.to surface (operator track, batch 01)

Captured 2026-11-08. All requests were unauthenticated GET requests at human rate.

## Stack

| Fact | Value | Evidence |
|---|---|---|
| Front end | Angular (modern Ivy build), base href /app | recon/raw/app-login.html |
| Bundler | webpack 5 with runtime chunk map | recon/raw/app-js/runtime.f44bccf5ac8f9f10.js |
| HTTP client | axios inside the app, XSRF cookie XSRF-TOKEN, header X-XSRF-TOKEN | main bundle @81889 |
| Back end | Ruby on Rails style. Session cookie _tether_sid, Rails 500 page, Rails ETag | recon/raw/secure_upload.html |
| Edge | Cloudflare | Server header |
| Session cookie | _tether_sid, domain .app.tether.to, secure, HttpOnly, no SameSite attribute | recon/raw/app-login.headers |
| XSRF cookie | XSRF-TOKEN, path /, no Secure, no HttpOnly, no SameSite | recon/raw/app-login.headers |

## API base path

The app calls relative paths such as /account/signup_status.json and /sessions. The API is
served at the origin root of app.tether.to. The Angular app itself is served under /app.
Any path outside the API route table falls through to the Angular index, which returns
HTTP 200 with text/html. This is a routing artefact, not a finding.

## Route map (Angular)

/app/login, /app/geo, /app/password, /app/password/:token, /app/signup, /app/signup/:token,
/app/secure_upload/:token, /app/logout, /app/account, /app/activity, /app/deposit, /app/2fa,
/app/settings, /app/settings/profile, /app/settings/preferences, /app/settings/api-keys,
/app/verification, /app/banks, /app/address-whitelist, /app/create, /app/edit/:id

## Endpoint inventory (from the bundles)

| Method | Path | Source chunk | Auth seen |
|---|---|---|---|
| GET | /account/signup_status.json | main | none |
| GET | /account/countries | main | none |
| GET | /account/states | main | none |
| POST | /sessions | main | none (login) |
| GET | /logout | main | none |
| GET | /account | main | redirect |
| POST | /users/signup | 671 | none |
| GET | /users/token | 83 | redirect |
| GET | /users/validate_token | 663 | redirect |
| POST | /users/secure_upload | 844 | 500 on GET |
| GET | /users/get_deposit_address | 845 | redirect |
| GET | /users/get_transport_protocols | 845, 91, 94 | redirect |
| GET | /account/verification | 94 | redirect |
| GET | /account/banks | 94 | redirect |
| POST | /account/banks/create | 94 | redirect |
| GET | /account/wire_details/:id | 94 | redirect |
| GET | /account/export_ledger | 358 | redirect |
| GET | /account/settings/profile | 186, 276 | redirect |
| POST | /account/settings/preferences | 276 | redirect |
| GET | /account/settings/api-keys, /api-key | 276 | redirect |
| GET | /api_keys | 509 | redirect |
| POST | /account/set_google_2fa, /account/activate_google_2fa, /account/disable_google_2fa | 186 | redirect |
| GET, POST | /whitelist/address, /whitelist/search | main | redirect |
| POST | /account/secure_mode | main | redirect |
| POST | /users/update_password | main | redirect |
| GET | /api/v1/int/vasps | 94 | none |
| POST | /password/validate_reset_password_token | 30 | redirect |
| POST | /password/reset | 30 | redirect |

## Unauthenticated results

Only four endpoints answered without a session: /account/signup_status.json,
/account/countries, /logout and /api/v1/int/vasps. Every other endpoint returned a 302 to
/app/login or to /. The auth boundary is enforced at the routing layer.

## Observations that are not findings

1. XSRF-TOKEN cookie has no Secure flag and no SameSite attribute. The session cookie has no
   SameSite attribute. This is a hygiene note, not an exploit. Modern browsers default an
   absent SameSite to Lax, which blocks cross-site POST.
2. /users/secure_upload returns a 500 on GET. The page is the static Rails 500 page with no
   stack trace and no path disclosure. The route expects a POST with a token.
3. /api/v1/int/vasps returns 2159 VASP entries with id and name only. The list is a public
   directory of counterparties. No user data.
4. The Angular catch-all returns 200 text/html for any unknown path. This makes status code
   fuzzing unreliable on this host. Only JSON responses are meaningful.

## Batch 02 leads

- /sessions is the login endpoint. It takes multipart FormData with login, password hash,
  and code. It has a client side retry of three attempts. Test the server side lockout and
  the response differential.
- /password/validate_reset_password_token and /password/reset take a base64 JSON token from
  the URL. Test token validation and reuse.
- /users/secure_upload/:token is a tokenised, unauthenticated upload path. Test token
  validation and upload handling.
- /account/signup_status.json returns a GLoc header. Test the geo blocking logic.
