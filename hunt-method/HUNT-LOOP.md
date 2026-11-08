# HUNT-METHOD

The operating loop this pack is built around. Read this first. Then load the skill that
matches the phase you are in.

## The loop

1. RECON. Map the surface. Subdomains, endpoints, contracts, TVL.
2. SURFACE. Rank what can be attacked. Crown jewel times easiest entry.
3. HYPOTHESIZE. Ask "what if the caller is malicious" on every external input.
4. PoC. Build a runnable exploit. Fork, sandbox, or live request.
5. EXECUTE. Prove it with real output. No output means no finding.
6. TRIAGE. Run the 7 question gate. Drop anything that fails.
7. REPORT. Impact first. Raw request and response. Fix in one sentence.
8. CLAIM. Submit to the program. Respect its rules.

## Non negotiable rules

- "Could potentially" is not a bug. Prove it or drop it.
- A finding without a reproducible path is a note, not a finding.
- Admin key required means stop. Re read the scope before you write the PoC.
- One bug class at a time, deep. Spraying is how you miss the real bug.
- Negative results are results. Write them down so the next batch does not repeat them.
- Every claim traces to a logged exchange or a real test run.

## Batch model

Work in batches. One batch is a decision point.

- Six agents per batch. One focused angle each.
- No overlapping batches. Batch N plus 1 is authored only after every agent of batch N
  returns and its output is written to recon/batch-NN.md.
- Each batch ends with a kill list and a ranked hypothesis list for the next batch.

## Where to go next

| You are doing | Load |
|---|---|
| Choosing the next move | skills/bb-methodology |
| Recon and asset discovery | skills/web2-recon |
| Picking a bug class | skills/web2-vuln-classes |
| Payloads and bypass tables | skills/security-arsenal |
| Scanning for common classes | skills/argus |
| Smart contracts | skills/web3-audit, skills/web3-playbook |
| Meme coins and tokens | skills/meme-coin-audit |
| GraphQL | skills/graphql-audit |
| CI/CD and supply chain | skills/cicd-security |
| Credential and login attacks | skills/credential-attack |
| Signed or anti bot requests | skills/client-reverse |
| Multi stage chains | skills/attack-chain |
| Validating before reporting | skills/triage-validation |
| Writing the report | skills/report-writing |
| Full autonomous engine | skills/bountyforge |
| Web search and page reads | skills/use-tinyfish |
| Browser PoC evidence | skills/browser-automation |
| Multi agent coordination | skills/orchestration |
| Heavy payload library | skills/pentest-tools |
