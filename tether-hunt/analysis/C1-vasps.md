# Analysis — C1: unauthenticated counterparty VASP directory

Status: candidate. Needs triage. Not yet a finding.

## The observation

`GET https://app.tether.to/api/v1/int/vasps` answers any anonymous caller with the full
counterparty directory used by the travel rule form.

- Response size: 179,992 bytes.
- Records: 2,159.
- Records with a did:ethr identifier: 2,136.
- Fields per record: id and name. No email, no phone, no address, no user id.

Sample rows:

```
{"id":"manual","name":"####Manual Entry####"}
{"id":"did:ethr:0xdf41ef7dcb92ab5aed72e284db3766ace5026948","name":"1Money (US)"}
{"id":"did:ethr:0xfeb4f99829a9acdf52979abee87e83addf22a7e1","name":"1xBet"}
```

## Why the endpoint is reachable without a session

The app calls this endpoint from the acquire form before the user has finished a transfer. The
client code is in chunk 94. The server therefore treats it as public reference data.

## The question for triage

The data is a compliance directory. The program excludes theoretical findings and low impact
findings. The candidate is only reportable if one of these is true:

1. The pairing of a legal business name with an Ethereum address is treated as non-public by
   Tether. This needs evidence. The directory is likely derived from the public travel rule
   directory used across the industry.
2. The list includes counterparties that Tether does not disclose publicly, for example
   sanctioned or restricted entities, or internal test entries. The entry
   "####Manual Entry####" is a placeholder. A placeholder in production is a data quality
   signal, not a security bug.
3. The list can be used to attribute on-chain flows to named businesses. This is passive
   chain analysis. It does not depend on the endpoint, because the same addresses are on chain.

## Honest assessment

Point 3 is the only one with a real harm path, and it does not need the endpoint. Point 1 needs
evidence that the directory is non-public. Without that evidence the report would be a
"best practice" report, which the program explicitly does not pay for.

Recommendation: keep as a candidate. Do not report unless batch 02 proves the directory is
non-public or contains data that Tether does not publish anywhere else.

## Related observation

The endpoint returns `Cache-Control: max-age=0, private, must-revalidate` and an ETag. The
response is not cached by Cloudflare (cf-cache-status DYNAMIC). No CDN leak.

## Evidence

- recon/raw/vasps.json (179,992 bytes)
- recon/raw/vasps.hdr
