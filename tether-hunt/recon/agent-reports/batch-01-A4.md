# BATCH 01 A4: EMAIL POSTURE (SPF, DMARC, DKIM, MX, SPOOFING FEASIBILITY)

Agent: A4-email-posture
Date: 2026-11-08
Target: tether.to (in scope per program page)
Method: passive DNS only. No email sent. No spoofing attempted.

Raw evidence: recon/raw/A4-email-posture-evidence.md
Scripts: recon/raw/A4-dns-raw.js, recon/raw/A4-spf-count.js, recon/raw/A4-dnssec-caa.js

---

## EXECUTIVE SUMMARY

tether.to has a strong email authentication posture. DMARC is at p=reject with strict
alignment on both SPF and DKIM. SPF uses a hard fail. SPF is well under the RFC 7208
lookup limit. The subdomain policy is also reject.

Direct spoofing of tether.to is NOT feasible. The paid class "SPF/DMARC misconfigurations
that allow for unauthorized email spoofing" is NOT met on tether.to.

Three weak points were found. Each is listed with an honest severity.
None of them is a confirmed paying finding at this time.

| # | Weak point | Severity | Status |
|---|-----------|----------|--------|
| 1 | DKIM s2 selector uses RSA 1024 bit key | Low | Validated config gap. No exploit path shown |
| 2 | No DNSSEC. Wildcard TXT returns v=spf1 -all for all names | Informational | Not ineligible class but no impact shown |
| 3 | No MTA-STS and no TLS-RPT | Informational | Availability only. Not a security finding |

---

## 1. MX

Query: `tether.to MX` against coby.ns.cloudflare.com, mary.ns.cloudflare.com, 1.1.1.1,
8.8.8.8, 9.9.9.9. All five agree.

```
tether.to  MX  1   aspmx.l.google.com
tether.to  MX  5   alt1.aspmx.l.google.com
tether.to  MX  5   alt2.aspmx.l.google.com
tether.to  MX  10  alt3.aspmx.l.google.com
tether.to  MX  10  alt4.aspmx.l.google.com
```

Provider: Google Workspace. This is the standard Google five MX set at the standard
priorities. Primary inbound mail for tether.to is Gmail.

No null MX. No catch-all MX. No third-party mailbox provider for the apex.

Subdomain mail:
```
email.tether.to  CNAME  u1576484.wl235.sendgrid.net
email.tether.to  MX     mx.sendgrid.net (priority 20)
149.72.93.105    PTR    o1.email.tether.to
```

`email.tether.to` is a SendGrid dedicated IP domain (single /32, 149.72.93.105). It
accepts mail on a SendGrid MX. This is a separate, intentional mail path.

---

## 2. SPF RECORD AND LOOKUP COUNT

Record (authoritative, confirmed on both Cloudflare NS and three public resolvers):

```
v=spf1 include:_spf.google.com include:sendgrid.net include:_spf.mlsend.com -all
```

All qualifier: `-all` (hard fail). Unlisted senders are rejected, not soft-failed.

### RFC 7208 section 4.6.4 lookup count

Counted mechanisms: include, a, mx, ptr, exists, redirect.

| # | Lookup | Source |
|---|--------|--------|
| 1 | include:_spf.google.com | tether.to |
| 2 | include:sendgrid.net | tether.to |
| 3 | include:ab.sendgrid.net | nested in sendgrid.net |
| 4 | include:_spf.mlsend.com | tether.to |

**TOTAL = 4 lookups. Limit = 10. Result: UNDER LIMIT.**

This is a clean result. The record is NOT over the limit. There is no perm-error
risk from lookup exhaustion. This is not a finding.

### Flattened chains

```
_spf.google.com    v=spf1 ip4:74.125.0.0/16 ip4:209.85.128.0/17 ip6:2001:4860:4864::/56
                   ip6:2404:6800:4864::/56 ip6:2607:f8b0:4864::/56 ip6:2800:3f0:4864::/56
                   ip6:2a00:1450:4864::/56 ip6:2c0f:fb50:4864::/56 ~all
sendgrid.net       v=spf1 ip4:167.89.0.0/17 ip4:208.117.48.0/20 ip4:50.31.32.0/19
                   ip4:198.37.144.0/20 ip4:198.21.0.0/21 ip4:192.254.112.0/20
                   ip4:168.245.0.0/17 ip4:149.72.0.0/16 ip4:159.183.0.0/16
                   ip4:134.128.64.0/18 ip4:159.26.176.0/20 include:ab.sendgrid.net ~all
ab.sendgrid.net    v=spf1 ip4:223.165.113.0/24 ip4:223.165.115.0/24 ip4:223.165.118.0/23
                   ip4:223.165.120.0/23 ~all
_spf.mlsend.com    v=spf1 ip4:185.249.220.0/24 ip4:185.225.161.0/24 ~all
```

### Sending services in the chain

| Service | Role | Takeover risk |
|---------|------|---------------|
| Google Workspace | Primary mail | Low. Tenant-bound |
| SendGrid (Twilio) | Transactional and marketing | Low for key sharing. See section 3 |
| mlsend.com | Marketing platform | UNVERIFIED ownership and reputation |

`mlsend.com` is the least known sender in the chain. It is a third-party marketing
platform. Its SPF is two /24 blocks. This service deserves a separate look in batch 02,
because a third-party marketing platform that allows self-service sending for a verified
domain is a classic spoofing path. That was NOT tested here. Marked UNVERIFIED.

---

## 3. DMARC RECORD AND INTERPRETATION

```
_dmarc.tether.to TXT =
v=DMARC1; p=reject; rua=mailto:66a08b43fae346e5b8fd2311be273c16@dmarc-reports.cloudflare.net,mailto:dmarc@tether.to; adkim=s; aspf=s; sp=reject
```

| Tag | Value | Meaning |
|-----|-------|---------|
| v | DMARC1 | Version |
| p | reject | Apex policy is reject |
| sp | reject | Subdomain policy is reject |
| adkim | s | DKIM alignment is strict |
| aspf | s | SPF alignment is strict |
| rua | Cloudflare + dmarc@tether.to | Aggregate reports |
| pct | absent | Defaults to 100 |
| fo | absent | Defaults to 0 |
| rf | absent | Defaults to afrf |
| ri | absent | Defaults to 86400 |

### Interpretation

This is the strongest possible DMARC posture.

- `p=reject`: receivers reject mail that fails alignment. Not quarantine. Not monitor.
- `sp=reject`: subdomains are covered at the same strength. There is no weak subdomain gap.
- `adkim=s` and `aspf=s`: strict alignment. A DKIM signature with `d=tether.to` must
  match the From header domain exactly. A subdomain like `evil.tether.to` cannot pass
  DKIM alignment for a `tether.to` From address.
- `pct` is absent, so it defaults to 100. Full enforcement.
- `rua` points to Cloudflare DMARC management plus their own mailbox. Reporting is active.

**p=none is NOT present. Spoofing is blocked at the DMARC layer.**

---

## 4. DKIM SELECTOR RESULTS

Selectors tested (36): default, google, selector1, selector2, k1, s1, mail, dkim, 20230601,
smtp, sendgrid, s2, k2, mx, email, mandrill, everlytics, cm, sig1, dkim1, selector3, s1024,
protonmail, zendesk, mailchimp, k3, sparkpost, smtpapi, amazonses, postmark, a1, b1, c1,
dkim2, tether, tether1, 2023, 2024, 2025.

**LIVE SELECTORS FOUND: 3**

### google._domainkey.tether.to
Direct TXT. RSA **2048 bit**. Key size verified with `crypto.createPublicKey`.
```
v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAj0YgN4E+5Tp0DZZyaSCK736kelMiak+l0FFl+BiDlbZOHqjZdkSraSNoA+K6uFS9Glb9R81/PWFf137pkK7B8DOX8Lz6YvbSANvsZkDamv7VwaxNdBlLk8VcWDem+dhIzC5Z10RORE3lWXDMfSd2YkjCslelv2Qgbrz8+5zUP87tr7OdJB5NphtqWlLcmj9gtad0us1COTnn/UJ9669FAzovA8n2Eo3fAewg/9FJ4vQZNk4SF8pemAOKbwPs+IG15ez3Cd8+TO0N0y4GSv/8gqDZRznnJ9kXkdGQ4xDuQx88V8UWyf75q3AFM/tqZzvFnE3VIdh9DVDCUJqc8/SCoQIDAQAB
```

### s1._domainkey.tether.to
CNAME to `s1.domainkey.u1576484.wl235.sendgrid.net`. RSA **2048 bit**.
```
k=rsa; t=s; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA4jknWgzGi6rVLnx8Np0r8zCZhO65er7KTnzqFrmL85cExvapoZxJp5xmPTkptTADxAS3FXVhKnMxvY+AO1xhur7JPpJA29APimoeBwDg/A7xn/NtZPL61fosaJKTs3l3i/F/KG9AP9qpeDdHsXYiSXPgp55GKKxgqEo5gVU4PDBdFI+jyJVXDn6Od4ogM549FBlcOEnzV2kNoEqPbUFSvk5DudfzjQGXhMJvYBDUQxe28wHgNfsfr0at9FhGVdHGXqSkdAGNITGNOE+4jPA5t8xlLCWZxO33MTiNBWgLZupHoIViY43lWEJMBDBR4YLMsOZWPo6MWlSO6iz8CSIpYwIDAQAB
```

### s2._domainkey.tether.to
CNAME to `s2.domainkey.u1576484.wl235.sendgrid.net`. RSA **1024 bit**.
```
k=rsa; t=s; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCiubm+T6HghGXTeB0AW5I6NSPd4sRKFGnnw6xAEOqhxTFu9WlhuW3lG+heqyJRQlbqAv3vf3BhKcNUJ/7OCNcHULikpi78+EIiwHjHWBkWmID2ARTfl4RFRRpmnsq8lc8fK5ONW9rfL7lSrVgP8NI4eJUNo360St2l/gx/JH8l8QIDAQAB
```

### Weak point 1: RSA 1024 bit DKIM key on s2

The `s2` selector uses a 1024 bit RSA key. RFC 8301 (January 2018) requires signers to use
at least 1024 bits and recommends 2048. NIST SP 800-57 deprecates 1024 bit RSA.

Honest assessment: this is a real configuration weakness, but it is NOT a spoofing
enabler on its own. Breaking a 1024 bit RSA key requires a large amount of compute. There
is no public report of a DKIM key of this size being factored in the wild. The DMARC
policy is `p=reject` with `adkim=s`, so a forged signature would need to be valid AND
aligned. I did not attempt any factoring.

**Status: validated config gap. Not a paying finding. Severity: Low.**
**Why it does not pay: no reproducible exploit path. This matches the ineligible class
"theoretical bugs with no reproducible exploit path".**

### Not a finding: SendGrid key sharing

I tested whether the `s2` key is a shared SendGrid key that other customers could use.
I compared the tether.to `s2` key against the `s2` keys of sendgrid.net, github.com,
twilio.com and spotify.com. **All keys differ.** Each SendGrid customer gets a unique key
pair. Key sharing is NOT present. This hypothesis is closed.

---

## 5. SUBDOMAIN POSTURE

| Name | TXT | MX | DMARC | Note |
|------|-----|----|-------|------|
| tether.to | SPF above | Google | p=reject sp=reject | Strong |
| app.tether.to | v=spf1 -all | none | inherits sp=reject | Correct. No sending |
| email.tether.to | v=spf1 ip4:149.72.93.105 -all | mx.sendgrid.net | inherits sp=reject | Correct. Tight /32 |
| www.tether.to | v=spf1 -all | none | inherits sp=reject | Correct |
| mail.tether.to | v=spf1 -all | none | inherits sp=reject | Correct |
| dev.tether.to | wildcard | none | inherits sp=reject | Wildcard A only |
| staging.tether.to | wildcard | none | inherits sp=reject | Wildcard A only |

**Does the parent DMARC cover subdomains?** Yes. `sp=reject` is set explicitly. Every
subdomain without its own `_dmarc` record inherits reject. I tested
`_dmarc.app.tether.to` and `_dmarc.email.tether.to`. Both return NXDOMAIN, so both
inherit `sp=reject`.

**Are there subdomains with a weaker SPF?** No. The only subdomain with sending
permission is `email.tether.to`, and its SPF is a single /32 with `-all`. Every other
subdomain returns `v=spf1 -all`.

**Wildcard DNS behaviour.** tether.to has a wildcard TXT record that returns
`v=spf1 -all` for every non-existent name. This is a defensive choice, not a defect.
It means that `_dmarc.<anything>.tether.to` returns `v=spf1 -all` instead of NXDOMAIN.
This is not a valid DMARC record, so receivers correctly fall through to the parent
`_dmarc.tether.to` and apply `sp=reject`. The wildcard does not weaken DMARC.

A wildcard A record also exists and answers for named hosts (`dev`, `staging`,
`wallet`, `kyc`, `gold` all return the same Cloudflare edge IPs). It does not answer
for random names.

---

## 6. BIMI, MTA-STS, TLS-RPT, DNSSEC, CAA

| Check | Result | Assessment |
|-------|--------|------------|
| BIMI `default._bimi.tether.to` | wildcard `v=spf1 -all` | Not deployed. Not a security defect |
| MTA-STS `_mta-sts.tether.to` | wildcard `v=spf1 -all` | Not deployed. Availability gap only |
| TLS-RPT `_smtp._tls.tether.to` | wildcard `v=spf1 -all` | Not deployed. Availability gap only |
| DNSSEC DS tether.to | NODATA. AD flag false | Not enabled |
| DNSSEC DS tether.io | NODATA. AD flag false | Not enabled |
| CAA tether.to | ENODATA | No CAA |
| Null MX | Not present | Fine |
| Catch-all MX | Not present | Fine |

**Weak point 2: no DNSSEC.** Without DNSSEC, a DNS-spoofing attacker who can control
the path between a resolver and the receiver can forge the SPF and DMARC lookups. This
is a real gap in principle. In practice it requires network position or a resolver
compromise. The program page lists "missing security headers as best practice" as
ineligible. A missing DNSSEC record is the DNS equivalent. I do not expect this to pay.
**Status: informational.**

**Weak point 3: no MTA-STS and no TLS-RPT.** This affects transport security between
mail servers. It does not enable spoofing. DMARC `p=reject` still applies.
**Status: informational. Do not report.**

---

## 7. SPOOFING FEASIBILITY VERDICT

**Verdict: NOT FEASIBLE for direct spoofing of tether.to.**

A spoofed message with `From: something@tether.to` would be evaluated as follows:

1. **SPF check.** The sending IP is not in Google, SendGrid, or mlsend ranges. SPF returns
   `-all`, which is a hard fail.
2. **SPF alignment.** `aspf=s`. The envelope from would have to be exactly `tether.to`
   to align. It would not be.
3. **DKIM check.** The attacker has no private key. No valid signature is possible with
   `d=tether.to`.
4. **DMARC evaluation.** SPF fails and DKIM fails. With `p=reject`, the receiver rejects
   the message.

**Exact DNS evidence for this verdict:**

```
tether.to TXT        v=spf1 include:_spf.google.com include:sendgrid.net include:_spf.mlsend.com -all
_dmarc.tether.to TXT v=DMARC1; p=reject; rua=...; adkim=s; aspf=s; sp=reject
```

The `-all` and `p=reject` together close the direct spoofing path.

### What a spoofed message WOULD pass

To be complete, here is what an attacker could still get through:

1. **Display name spoofing.** `From: "Tether Support" <attacker@gmail.com>`. This passes
   all authentication because the domain is not tether.to. DMARC cannot stop this. This
   is a user-education problem, not a Tether configuration defect.
2. **Lookalike domain.** `tether-support.com`, `tether.to.attacker.com`, or a
   homoglyph domain. DMARC on tether.to does not apply. This is a registration-monitoring
   problem. It is not a misconfiguration of tether.to.
3. **Compromise of an authorized sender.** If a SendGrid or mlsend account for tether.to
   is compromised, the attacker can send authenticated mail. This is an account security
   problem, not a DNS misconfiguration. Not tested here.

None of the three is an SPF or DMARC misconfiguration. The paid class is not met.

---

## 8. OUT OF SCOPE CONTEXT (NOT REPORTABLE)

These domains were checked for context only. None is in scope.

| Domain | Observation | Ownership |
|--------|-------------|-----------|
| tether.io | DMARC p=reject sp=reject adkim=s aspf=s. SPF mlsend + Google -all | Confirmed Tether Ltd |
| tether.com | DMARC **p=none**. SPF Outlook + Mailchimp + Brevo -all | **Seattle design agency. NOT Tether Ltd** |
| tether.org | DMARC p=none. SPF protonmail ~all | UNVERIFIED |
| usdt.to | SPF include:_spf.mx.cloudflare.net ~all. **NO DMARC** | UNVERIFIED |
| tethergold.com | No DMARC. SPF Outlook -all | UNVERIFIED |

**Important correction for the swarm.** `tether.com` resolves to a Seattle creative
agency ("Tether | Design, Branding & Industrial Design Agency"). Its `p=none` DMARC is
not Tether Ltd. Do not report it. `tether.org` and `usdt.to` have weak posture but
ownership is UNVERIFIED and neither is in scope.

---

## 9. BATCH 02 HYPOTHESES

Ranked by expected value.

### H1: mlsend.com self-service sending abuse (MEDIUM value)
tether.to authorizes `_spf.mlsend.com` in its SPF. If mlsend.com lets any user verify
`tether.to` as a sending domain, or if the platform has a shared-tenant path, then mail
would pass SPF. DMARC `adkim=s` and `aspf=s` would still require alignment, so the
envelope from must be `tether.to`. Test: read mlsend.com domain-verification policy.
Check whether the platform exposes a public API that accepts a From domain. Do NOT
register or send anything without written permission.
**Precondition to check first: does mlsend.com require DNS TXT proof for a sending domain?**
If yes, this hypothesis dies.

### H2: SendGrid account takeover for email.tether.to (MEDIUM value)
`email.tether.to` accepts mail on `mx.sendgrid.net` and sends from a single IP
(149.72.93.105). If the SendGrid account `u1576484` is reachable through a weak login,
or if the Inbound Parse webhook is exposed, an attacker could send authenticated mail as
`@email.tether.to`. That subdomain inherits `sp=reject`, so a From of
`user@tether.to` would still fail. A From of `user@email.tether.to` would pass.
Test: fingerprint the SendGrid account. Check for Inbound Parse host exposure. Passive
only. No login attempts.

### H3: DKIM 1024 bit key is not worth pursuing (LOW value)
Breaking the `s2` key is not practical. Do not spend batch 02 time on it. Keep it as a
one line hardening note in the final report.

### H4: SPF record parsing edge case (LOW value)
The record is 4 lookups and clean. No perm-error path. No void-lookup abuse. Closed.

### H5: Lookalike domain monitoring (LOW value, out of scope)
Not a Tether misconfiguration. Do not report.

---

## 10. HONEST STATUS

| Question | Answer |
|----------|--------|
| Is direct spoofing of tether.to possible? | No |
| Is SPF over the 10 lookup limit? | No. It is 4 |
| Is DMARC p=none? | No. It is p=reject with sp=reject |
| Are subdomains covered? | Yes. sp=reject |
| Is there a weak subdomain SPF? | No |
| Is there a shared DKIM key? | No. Keys are per customer |
| Is there a reportable spoofing finding? | **No** |
| Is this a clean result? | **Yes. A clean result is a valid result** |

The email posture of tether.to is well configured. Batch 02 should move to other angles.
