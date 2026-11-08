# FINDING TEMPLATE

Copy this file to `findings/FINDING-<n>-<short-name>.md` and fill every section.
One finding per file. Report text obeys ASD-STE100 Simplified Technical English.
No semicolons. No dash-pair constructions such as "X: Y".

---

# Finding <n>. <Title>

| Field | Value |
|---|---|
| Target | |
| Host | |
| Endpoint | |
| Method | |
| Authentication required | yes or no |
| Status | validated, dropped, or needs-more-data |
| CVSS 3.1 vector | |
| CVSS 3.1 score | |
| Severity | Critical, High, Medium, Low, or Informational |
| Discovered | date |
| Batch | |

## Summary

Two to four sentences. State what is wrong and what an attacker gains.

## Affected Component

State the exact host, path, and parameter.

## Preconditions

List what the attacker must have. Write "None" when the attack needs no account.

## Reproduction Steps

Numbered steps. Each step names the exact request.

### Step 1. <what this step does>

Request:
```
GET /path HTTP/1.1
Host: host
```

Response:
```
HTTP/1.1 200 OK
```

Why this proves the point. One sentence.

## Impact

State the concrete consequence. Do not use the words "could potentially".
Either the impact is proven or the finding is not validated.

## Evidence Files

List the saved raw evidence in `poc/` or `recon/`.

## Remediation

State the smallest correct fix.

## Triage Gate

| Question | Answer |
|---|---|
| What are the attack preconditions | |
| Are the preconditions met | |
| Is it reproducible | |
| Is it in scope | |
| Is it previously known | |
| Is the impact provable | |
| Is the severity honest | |

## Notes

Anything that weakens or strengthens the finding. Include negative results honestly.