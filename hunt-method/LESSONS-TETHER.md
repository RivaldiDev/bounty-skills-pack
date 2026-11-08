# LESSONS FROM THE TETHER RUN

Real results from a live hunt against a hardened target. Read this before you hunt. It saves
hours. Every item below was produced by real tool output, not theory.

## 1. A clean target is a real outcome

The Tether web scope is two hosts. Both are hardened.

| Class | Result |
|---|---|
| Email spoofing | DMARC p=reject, sp=reject, strict alignment, SPF 4 lookups ending -all |
| CORS | Allowlist reflects only the real origin. No credentials header. |
| Missing headers | Not eligible by program rules |
| Mixed content | None |
| Dangling DNS and takeover | No CNAMEs to claimable SaaS |
| Secrets in bundles | Zero across 64 bundles |
| Source maps | None served |
| SSRF through a verifier | The verifier makes zero network calls |
| GraphQL | No surface |
| Weak TLS | TLS 1.0 and 1.1 refused |

Conclusion: the paid classes on the named surface were already closed. The value of the
batch was proving that, and finding where the surface actually is.

## 2. The 401 oracle trick

When a SPA serves its own fallback for unknown paths, status codes lie. Find the real API
boundary instead.

On app.tether.to:

- A real API route returns HTTP 200 with {"code":401,"error":"Unauthorized"}.
- A non route returns HTTP 302 to the SPA login.

That single difference turns a black box into a map. Enumerate slowly, one GET per path,
and stop at the 401. This is the highest value recon primitive found in the run.

Generalise it: find the response that differs between "route exists but you may not" and
"route does not exist". Then map the API without touching auth.

## 3. Two auth filters mean one is weaker

/account, /balance and /announcements redirected to the origin root.
/account/states, /users and /account/verification redirected to the SPA login.

Two different redirect targets from one application means two code paths. Two code paths
means one may be older. Always test the odd one out.

## 4. Verify the source before you audit the bytecode

Do not trust a source listing. Rebuild it.

The USDT source from Sourcify, compiled with solc 0.4.18 and no optimizer, produced runtime
bytecode byte identical to mainnet (11,075 bytes). Only then is the audit meaningful.

Practical notes that cost time:

- solc 0.4.x ships as a zip, not an exe. Unpack it before you point forge at it.
- forge needs the exact compiler for each pragma. Install every version you need.
- Strip the CBOR metadata before a bytecode compare. The length field tells you how much.

## 5. Proxy implementations are a separate contract with separate state

XAUt is a TransparentUpgradeableProxy. The implementation at 0x4c0d2c74 is directly
callable and has its own owner, its own supply and its own EIP-712 domain.

- proxy owner 0xC6CDE7C3, implementation owner 0x7224BEef (an EIP-7702 delegated EOA)
- proxy supply 827,417,630,000, implementation supply 1
- proxy domain separator 0xf04743eb, implementation domain separator 0xf5f41f9b

The domain separator difference is the reason a permit signature cannot be replayed across
them. Always compute the domain separator by hand and compare it to the chain.

## 6. Not every difference is a bug

The implementation being callable looked alarming. It is not exploitable.

- The implementation owner is a Tether operations key.
- The two states are separate. Minting on the implementation does not touch the proxy.
- No path from the implementation to the proxy was found.

Record it as an observation. Do not report it as a finding. A triager who sees an
unexploitable observation marks the whole report down.

## 7. Cross chain builds differ

The same token name is not the same code.

| Chain | Build | Note |
|---|---|---|
| Ethereum | TetherToken 0.4.18 | Audited, byte identical |
| BSC | BEP20USDT 0.5.16 | Different contract. 18 decimals. |
| Arbitrum | TransparentUpgradeableProxy | Different architecture |
| Avalanche | TetherToken proxy | Different implementation |
| Optimism | L2 standard bridge token | l1Token points at Ethereum USDT |

A chain running a different build is where a new bug can live. Compare code hashes first.
Only read the source of the chains that differ.

## 8. Things that waste time

- Status code fuzzing on a host that returns 200 for every path.
- Reporting a public token (Contentful delivery token, hCaptcha site key, analytics id).
- Testing hosts that are not in the scope list. They are leads, not targets.
- Writing a CSRF report when the auth gate rejects the request before CSRF runs.
- Treating an unverified scanner hit as a finding.

## 9. What to do when the surface is closed

Move to a surface the program named but nobody audited. For Tether that is the contract
group, not the two web hosts. Read the scope text literally. "Tether Tokens Smart
Contracts" is a group, not one address.
