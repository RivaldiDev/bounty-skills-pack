# Tether — Hunt Folder

**Program:** https://tether.to/en/bug-bounty/ — self-hosted report form on the program page. No HackerOne, Bugcrowd or Immunefi listing for this program.
**Program terms:** linked from the program page ("here"). Read before any submission.
**Mode:** Batch 01 unauthenticated, passive-first. Authenticated testing only with own test accounts, and only if a later batch needs it and the policy allows it.
**Folder created:** 2026-11-08 (Asia/Jakarta)

## Reward table (captured 2026-11-08)

### Web applications

| Risk priority | Minimum (USD) | Maximum (USD) |
|---|---|---|
| RP1 | 1,000 | 10,000+ |
| RP2 | 800 | 1,500 |
| RP3 | 200 | 400 |
| RP4 | 50 | 150 |
| RP5 | 10 | 50 |

### Smart contracts

| Risk priority | Minimum (USD) | Maximum (USD) |
|---|---|---|
| RP1 | 50,000 | 10,000,000 |
| RP2 | 10,000 | 50,000 |
| RP3 | 500 | 10,000 |
| RP4 | 100 | 500 |
| RP5 | 10 | 100 |

RP1 smart contract payout is 10 percent of the funds directly affected, capped at USD 10,000,000. The cap is valued at the submission date.

## Scope (short form, full contract in SCOPE.md)

Web: tether.to, app.tether.to.
Smart contracts: Tether Tokens Smart Contracts, as listed on the program page.
Out of scope: tether.recruitee.com, tether.statuspage.io, third-party software, social engineering, physical, extortion.

## Focus

Medium and above. The program pays for injection, broken access control, XSS, CSRF on state changes, SSRF, SPF and DMARC misconfiguration, information leakage, transport and mixed content, and subdomain takeover. The hunt targets the two web hosts first, because the smart contract surface is a large separate audit.

## Layout

```
tether-bounty/
├── README.md        # this file
├── SCOPE.md         # scope contract and rules of engagement
├── recon/           # one output file per batch: batch-NN.md
├── analysis/        # per-candidate deep dives
├── findings/        # candidates Medium and above, uses FINDING-TEMPLATE.md
├── notes/           # running hunt log
├── repos/           # local clones (gitignored)
├── poc/             # one directory per finding, plus poc/evidence/
└── report/          # PDF report, submission draft, MD attachment
```

## Process

1. Batch 01: six parallel subagents, passive and light-touch surface map. Plan written at intake.
2. Batch N+1 is authored only after all six outputs of batch N are read and written to recon/batch-NN.md.
3. No overlapping batches. Agents run in parallel inside a batch. Batches run in sequence.
4. Triage gate with seven questions before any report. One failed reproduction means drop or park.
5. Deliverables in report/ obey ASD-STE100 Simplified Technical English.

## Rules of engagement (from the program page, binding)

- Report once a bug is found, through the form at the bottom of the program page.
- Do not share details in support chat or in public.
- Do not interrupt or degrade the products or services.
- Do not harm or defraud Tether systems, products or users.
- Test only own accounts.
- Do not violate the privacy of other users, destroy data, or access other users' accounts or data.
- Do not attempt social engineering or phishing on users or Tether personnel.
- No denial of service, no spamming, no blackhat SEO.
- Automated scanner output without verification is not eligible.
- Theoretical findings without a reproducible exploit path are not eligible.
- Rate-limit complaints without a demonstrated bypass are not eligible.
- Missing security headers and best-practice notes are not eligible.
- Third-party hosted assets are not eligible. Integrations to third parties are in scope.

## Eligibility traps (from program page)

- Only tether.to and app.tether.to are in scope for the web program. Any other host is a lead, not a target.
- The reward is at Tether's sole discretion. There is no obligation to explain a decision.
- Duplicate reports get no response.
- KYC and sanctions screening apply before payout. Prohibited jurisdictions are listed in the page.
- Reports that are false or misleading bar the researcher from the program.

## Status

Batch 01 in progress. See notes/hunt-log.md for the live log.
