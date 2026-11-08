# SCOPE — Tether Bug Bounty (captured 2026-11-08)

Source: https://tether.to/en/bug-bounty/. Raw page text archived in recon/source-pages/.

## In scope (explicit list, this is the contract)

### Web applications

| Asset | Class |
|---|---|
| tether.to | website and marketing site |
| app.tether.to | web application |

### Smart contracts

| Asset | Class |
|---|---|
| Tether Tokens Smart Contracts | as listed on the program page |

The program page names the smart contract target as "Tether Tokens Smart Contracts". The exact contract address list is on the program page and must be confirmed before any contract work starts.

## Out of scope

- tether.recruitee.com (Recruitee)
- tether.statuspage.io (Statuspage)
- Any third-party software. Integrations to third-party services are in scope.
- Social engineering.
- Physical building security.
- Coercion or extortion.
- Event security.
- Any host not named above. Discovered subdomains are leads for correlation only.

## Allowed methods

- Passive recon: DNS, certificate transparency logs, public archives, public code.
- Light active probing: manual GET and POST at human rates on the listed hosts only.
- Authenticated testing with own test accounts, if a batch needs it and the policy allows it.
- No automated high-volume scanning. No fuzzing floods. No load tests.

## Not allowed, and not done

- Denial of service of any kind, including accidental degradation.
- Spamming, blackhat SEO.
- Social engineering or phishing against users or Tether personnel.
- Access to other users' accounts or data.
- Data destruction.
- Public disclosure before a fix.

## Severity model (program risk priority)

| Priority | Meaning in this hunt |
|---|---|
| RP1 | Unauthorised access, account takeover, fund loss, or remote code execution on a listed host |
| RP2 | Data exposure across users, strong SSRF, or auth bypass with limited scope |
| RP3 | Stored XSS with a real victim path, CSRF on a sensitive state change, or subdomain takeover |
| RP4 | Reflected XSS with a real victim path, email spoofing through SPF or DMARC, or internal path disclosure |
| RP5 | Bounded information leakage with a demonstrated impact |

## Eligible bug classes (program page)

Injection, including RCE and SQLi. Broken access control, including IDOR and privilege escalation. All forms of XSS, except Self-XSS without a proven critical impact. CSRF on sensitive state-changing actions. SSRF. SPF and DMARC misconfiguration that allows email spoofing. Information leakage, including stack traces, internal paths and debug info. Mixed content and weak TLS. Subdomain takeover.

## Not eligible (program page)

Third-party hosted assets. Best-practice reports such as missing security headers. Unverified automated scanner output. Theoretical vulnerabilities without a reproducible exploit path. Low-impact and informational findings. Rate-limit complaints without a demonstrated bypass. Destructive denial of service.

## Submission

Report form at the bottom of https://tether.to/en/bug-bounty/. Fields: name, email, bug found, product, risk level, summary, steps to replicate, impact, and optional media up to 20 MB in jpg, jpeg, png, mp4, avi, mov or webm.

## Eligibility notes

- The researcher must be over 18 or the age of majority.
- Prohibited jurisdictions are listed on the program page.
- KYC and sanctions screening apply before payout.
- The first eligible report for an issue wins the reward.
- Tether decides the priority class and the reward at its sole discretion.
