# Batch 02 plan — Tether

Authored 2026-11-08 after all six batch 01 outputs were read. Not written at intake.

## What batch 01 proved

The named web scope is two hosts. Both are hardened at the edge and at the auth boundary.

- Email, TLS, CORS, DNS, mixed content and secrets are all clean.
- The app API enforces auth at the routing layer. Every protected route redirects.
- The USDT contract holds under fork tests.

So batch 02 stops hunting for the obvious classes on the same surface. It goes after the
things batch 01 could not settle without deeper work.

## Ranked hypotheses

| # | Hypothesis | Why it is worth a batch | Risk |
|---|---|---|---|
| H1 | API route map on app.tether.to through the 401 oracle | Turns a black box into a map. One GET per path. | Low |
| H2 | Auth boundary differential across the two filters | Two code paths can mean one is weaker. Needs one own account. | Medium |
| H3 | The bounty form at app.tether.to/bounty | In scope. Multipart upload. Rails CSRF. No session needed. | Medium |
| H4 | Reset and secure-upload tokens in the URL path | Base64 JSON in the path. Test single use, expiry, binding. | Medium |
| H5 | Contract track: XAUt and the cross-chain USDT deployments | The contract scope is a group, not one address. | Low |

## Six agents for batch 02

| Agent | Angle | Needs an account |
|---|---|---|
| B1 | API route enumeration through the 401 oracle. Map /api/v1 and the legacy /app prefix. | No |
| B2 | Bounty form: CSRF token handling, content type confusion, upload limits, response leak. | No |
| B3 | Unauthenticated surface on app.tether.to: /users, /password, /sessions, /account. Response differential only. No brute force. | No |
| B4 | Contract track: XAUt source, deployed state, fork tests. Same method as USDT. | No |
| B5 | Contract track: USDT on other chains. Compare deployed bytecode to the audited source. Find any chain running a different build. | No |
| B6 | tether.to static surface: Gatsby page-data, Contentful, i18n, the transparency page data. | No |

## Hard rules for batch 02

1. Only tether.to and app.tether.to. Every other host is a lead, not a target.
2. No account registration in this batch. B2 and B3 must be answerable without one.
3. No brute force. No password spraying. No fuzzing floods.
4. No email to any Tether address.
5. Every claim needs a raw request and response pair in recon/raw/.
6. Negative results are written down. A clean result is a result.

## Account decision deferred

H2 and H4 need one self-registered account. The program allows testing of own accounts. It
does not allow access to other users' data. That work is held for batch 03 and will be
proposed to the operator before any registration.
