# WORKFLOW SC WEB3 — 0xkonde // ZERO-DAY HUNTER
> Model: opus 5.5 via Hermes Agent. Fokus: Solidity/EVM smart contract. Deliverable HANYA Critical/High PROVEN + Foundry PoC.

## 0. DOKTRIN SC
1. Bug valid = reachable path + invariant jebol + impact duit + preconditions realistis + PoC.
2. "Could potentially" = BUKAN bug. Prove atau drop.
3. Satu aturan emas: baca SEMUA sibling function. `vote()` ada modifier, cek `poke()` `reset()` `harvest()`. Modifier missing di sibling = 19% Critical.
4. Admin-key-required = STOP duluan (cek Phase 0), jangan buang 4 jam buat PoC yg auto-reject.

## 1. PRE-DIVE KILL SIGNALS (cek SEBELUM baca code)
- TVL < $500K -> skip (payout kekecilan)
- 2+ audit top-tier (Halborn, ToB, Cyfrin, OZ) di versi ini + protokol simple -> skip
- Protokol <500 baris, flow A->B->C doang -> surface tipis
- Formula: `max_payout = min(10% x TVL, program_cap)` kalau < $10K skip
- Soft kill: OZ/ToB audit + >500K LOC -> 40 jam+ buat 1 finding. Gas cuma kalau floor >$50K + lu paham protokolnya.

Scoring gas kalau >=6/10:
TVL>$10M +2, Immunefi Crit>=$50K +2, belum ada top-tier audit versi ini +2, <30 hari deploy +1, pernah hunt protokol sejenis +1, source+natspec +1, upgradeable proxy +1

## 2. PHASE 0 — SCOPE + DEDUP (30 detik, wajib pertama)
- Baca OUT-OF-SCOPE harfiah. Kalau exploit butuh `prank(owner/admin)` dan program exclude "admin key / centralization / governance" -> STOP class itu.
- Self-test: kalimat report "compromised owner could..." / "malicious owner could..."? Ya = butuh admin key = STOP. Pivot ke path external attacker (Comptroller, oToken, oracle, deposit/burn yg callable anyone).
- Bedain primary (`loss of funds` = max bounty) vs secondary (frontend/dApp = tier rendah). Aim primary.
- Confirm program beneran ada: cek `SECURITY.md` + Immunefi/H1. Kalau cuma `security@...` tanpa reward = disclosure channel, bukan bounty.
- Dedup: GitHub issues/PRs, GHSA, Rekt/BlockSec/PeckShield post-mortem, audit report Certik/Immunefi/Sherlock, CHANGELOG. PR terbuka/post-mortem sama persis = jangan submit.

## 3. PHASE 1 — SOURCE ACQUISITION
```bash
# Custom explorer
curl -s "https://explorer.CHAIN.org/api?module=contract&action=getsourcecode&address=ADDR"

# Etherscan API v2 (butuh free key, v1 deprecated 2026)
curl "https://api.etherscan.io/v2/api?chainid=1&module=contract&action=getsourcecode&address=ADDR&apikey=KEY"

# Etherscan HTML data-csource (no browser)
curl -s -L -A "Mozilla/5.0 Chrome/131" "https://etherscan.io/address/ADDR#code" -o page.html
python3 -c "import re; d=open('page.html').read(); idx=d.find('ContractName.sol'); m=re.search(r\"data-csource='(.*?)'\", d[idx:idx+200000], re.DOTALL); open('src.sol','w').write(m.group(1))"
```

## 4. PHASE 2 — ON-CHAIN CONFIRMATION (jangan nulis report sebelum ini)
```bash
RPC=https://ethereum.publicnode.com
# owner() 0x8da5cb5b
curl -s -X POST $RPC -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","method":"eth_call","params":[{"to":"ADDR","data":"0x8da5cb5b"},"latest"],"id":1}'
# EOA vs multisig
curl -s -X POST $RPC -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","method":"eth_getCode","params":["OWNER_ADDR","latest"],"id":1}'
# 0x = EOA. bytecode panjang = contract (multisig/timelock)
# balance ERC20
DATA="0x70a08231000000000000000000000000$(echo CONTRACT | sed 's/0x//')"
curl -s -X POST $RPC -H 'Content-Type: application/json' -d "{\"jsonrpc\":\"2.0\",\"method\":\"eth_call\",\"params\":[{\"to\":\"TOKEN\",\"data\":\"$DATA\"},\"latest\"],\"id\":1}"
# ETH balance
curl -s -X POST $RPC -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","method":"eth_getBalance","params":["ADDR","latest"],"id":1}'
```
- PITFALL TVL: spot-RPC (cuma USDC/WETH) underestimate. Onyx case: RPC $613K vs holdings page $12.89M (9 token). Wajib cross-check `https://etherscan.io/address/ADDR` -> expand Token Holdings. Itu angka authoritative buat severity.

## 5. PHASE 3 — MANUAL AUDIT (10 bug class bayaran)
Urutan: accounting -> access control -> incomplete path -> off-by-one -> oracle -> ERC4626 -> reentrancy -> flashloan -> sig replay -> proxy.

### C1 ACCOUNTING DESYNC (28% Critical)
A-B supposed sync, satu path update A lupa B -> phantom value.
- Yeet: `totalSupply -=` sebelum transfer -> `balance-totalSupply` = phantom yield
- Alchemix: early return skip `cumulativeEarmarked/totalDebt`
- deposit hitung shares SEBELUM `totalAssets +=`
```bash
grep -rn "totalSupply\|totalShares\|totalAssets\|totalDebt\|cumulativeReward\|rewardPerShare" contracts/
grep -rn "\breturn\b" contracts/ -B3 | grep -B3 "if\b"
```

### C2 ACCESS CONTROL (19% Critical, $953M 2024)
- sibling missing modifier (`poke()` no `onlyNewEpoch`)
- existence vs ownership (`_requireOwned` cek exist, bukan own -> curi via `split()`)
- silent modifier (`if(admin){_;}` bukan `require` -> non-admin lolos diam2)
- `initialize()` tanpa `initializer` + no `_disableInitializers()`
```bash
grep -rn "function vote\|function poke\|function reset\|function update\|function claim\|function harvest" contracts/ -A2
grep -rn "_requireOwned\|ownerOf\|_isApprovedOrOwner\|_checkAuthorized" contracts/ -B5
grep -rn "modifier\b" contracts/ -A8 | grep -B3 "if (" | grep -v "require\|revert"
grep -rn "function initialize\b" contracts/ -A3; grep -rn "_disableInitializers()" contracts/
```

### C3 INCOMPLETE PATH (17% Critical)
Test: list state-change A (deposit/place/create), list reverse B (withdraw/update/cancel). A ada X tapi B gak ada reverse = BUG.
- ThunderNFT `update_order` no refund pas harga turun -> stuck
- Plume partial fill refund ETH doang, ERC20 nyangkut
- MetaPool `mint()` bypass validasi yg ada di `deposit()`
```bash
grep -rn "function place_\|function create_\|function add_\|function open_" contracts/ -A5
grep -rn "function update_\|function modify_\|function cancel_" contracts/ -A5
grep -rn "function deposit\|function mint\|function withdraw\|function redeem" contracts/ -A10
```

### C4 OFF-BY-ONE (22% High)
Tiap `if(A>B)`: "gimana kalau A==B?" VeChain `>` harusnya `>=` -> drain post-exit.
Cek: epoch boundary, `timestamp==deadline`, `break` `>` vs `>=`, `i<=length` harusnya `<`, `>=amount` full withdraw, rounding ke 0.
```bash
grep -rn "Period\|Epoch\|Round\|Deadline" contracts/ -A3 | grep "[<>][^=]"
grep -rn "\bbreak\b" contracts/ -B10
grep -rn "\.length\s*-\s*1\|i\s*<=\s*.*\.length\b" contracts/
```

### C5 ORACLE (payout terbesar: Mango $117M, Curve $70M)
- Chainlink no staleness: wajib `updatedAt` + `block.timestamp-updatedAt<=MAX` + `price>0`
- Pyth no conf: wajib `conf*10 <= price`
- TWAP 60s = flashloanable. Bener min 1800s.
- Single-source Uniswap spot = manipulatable. Bener Chainlink primary + TWAP fallback + require close.
```bash
grep -rn "latestRoundData" contracts/ -A5 | grep -v "updatedAt\|timestamp"
grep -rn "getPriceUnsafe\|getPrice\b" contracts/ -A8 | grep -v "conf\|confidence"
grep -rn "secondsAgo\|TWAP\|cardinality\|getReserves\|getAmountsOut\|slot0\b" contracts/ -A5
```

### C6 ERC4626
- First depositor attack: deposit 1 wei -> donate langsung -> rate 1 share = gede -> victim round to 0. Fix `_decimalsOffset()=9` (OZ v4.9+).
- Transfer shares tapi lock record ketinggalan -> stuck/freeze.
```bash
grep -rn "function transfer\|function transferFrom" contracts/ -A15
grep -rn "function deposit\|function mint\|function withdraw\|function redeem" contracts/ -A10
grep -rn "_decimalsOffset\|virtual.*shares" contracts/
```

### C7 REENTRANCY (masih bayar 40+ case 2023-25: cross-function, read-only view)
Pola: interaction sebelum effect. Fix CEI.
Baru 2024+: EIP-1153 transient `tload/tstore` desync across call. EIP-7702 re-delegation replay. ERC-777/hooks/callback = curigai.
```bash
grep -rn "\.call{value\|safeTransfer\|transfer(" contracts/ -B10 | grep -v "require\|revert"
grep -rn "function withdraw\|function redeem\|function claim" contracts/ -A2 | grep -v "nonReentrant"
grep -rn "tload\|tstore" contracts/ -B3 -A3
```

### C8 FLASHLOAN
Flow: pinjam $50-100M -> dump pool -> oracle baca spot jatuh -> borrow max -> repay -> keep profit. Target secondary oracle (TWAP low-liq V2, internal oracle, fallback stale), bukan Chainlink primary.

### C9 SIGNATURE REPLAY
Hash wajib include nonce + chainid + contract address. Cek `ecrecover/ECDSA.recover` -B20.
```bash
grep -rn "ecrecover\|ECDSA\.recover" contracts/ -B20
grep -rn "nonce\|_nonces\|nonces\[" contracts/
grep -rn "block.chainid\|chainId" contracts/
```

### C10 PROXY/UPGRADE
- Storage collision (slot0 owner vs initialized)
- Implementation bisa `initialize()` langsung -> rebut -> `upgradeTo()` ganti logic
- `delegatecall` ke address user-controlled
```bash
grep -rn "function initialize\b\|_disableInitializers\|initializer" contracts/
grep -rn "delegatecall\b" contracts/ -B3 -A5
grep -rn "0x360894\|EIP1967\|_IMPLEMENTATION_SLOT" contracts/
```

### BRIDGE BONUS (lock-mint = impact tertinggi)
- whitelist token on-chain di `deposit()/burn()`? missing = Low/Med
- `emergencyWithdraw`/drain: owner EOA/multisig? timelock?
- depositId/withdrawId replay across chain?
- relayer single EOA vs validator set? signature vs trusted-relayer?
- `timestamp/number` di ID gen = miner-manipulable
Severity: admin drain EOA no timelock $100k+ = Med-High, whitelist missing = Low-Med, replay/depositId reuse = High-Crit, reentrancy withdraw = High-Crit.

## 6. PHASE 4 — STATIC (jangan andelin doang)
```bash
pip install slither-analyzer
slither . --print human-summary
slither . --detect reentrancy-eth,arbitrary-send-eth,unprotected-upgrade
forge build
```
Prioritas manual: admin func -> external call -> transfer path (fee/rebase/non-standard ERC20) -> ID/nonce -> math rounding (round against user) -> modifier coverage.

## 7. PHASE 5 — FOUNDRY FORK POC (Immunefi wajib, tanpa PoC auto-reject)
```bash
curl -L https://foundry.paradigm.xyz | bash; foundryup
mkdir poc && cd poc; forge init --no-git --force
forge install foundry-rs/forge-std --no-git
rm -f src/Counter.sol test/Counter.t.sol
cast to-check-sum-address 0xabc... # checksum dulu, lowercase gagal compile
sed -i 's/—/-/g' test/*.sol # scrub non-ASCII dari output AI
forge test --fork-url https://ethereum.publicnode.com --match-path test/MyPoC.t.sol -vvvv
```
Template:
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "forge-std/Test.sol";
contract ExploitTest is Test {
  address attacker = makeAddr("attacker");
  address victim = makeAddr("victim");
  function setUp() public {
    vm.createSelectFork("mainnet", BLOCK_NUMBER);
    deal(address(token), attacker, 1 ether);
  }
  function test_exploit() public {
    vm.startPrank(attacker);
    // 1 setup -> 2 exploit -> 3 verify
    vm.stopPrank();
    assertGt(token.balanceOf(attacker), 1 ether, "fail");
  }
}
```
Cheat: `prank/startPrank deal warp roll createSelectFork expectRevert assume label`
PoC ideal = 1x `forge test` langsung prove, ada `assertEq` balance drain / mint / state corrupt. Jangan yg butuh setup manual.

## 8. PHASE 6 — VALIDATE + REPORT (Immunefi)
Gate: PoC jalan di fork? in-scope? repro clean? dedup? bukan admin-key? impact $ / %TVL? severity pake matrix program itu persis (Crit = % loss TVL, beda $500K vs $500M beda bayaran)?
Judul: `[Class] in [Contract::func] allows [actor] to [impact] ($X / N users)`
Body: summary 2-3 kalimat -> steps repro (copy-paste forge cmd) -> PoC code -> impact $ -> fix 1-2 kalimat.
Multisig >5 + timelock >48h = rug-pull low, jangan klaim malicious-team (auto-downgrade centralization).

## 9. STATE + ITERATION
Gagal compile/revert: tulis 1 baris LESSON, ganti payload, RUN AGAIN. Min 3 iterasi per vector. Stuck -> pindah fungsi/contract beda.
```
STATE @ <proto> <HH:MM>
findings: <proven+kandidat+tier>
invariants: <yg harus hold>
tested-safe: <vector->kenapa gagal>
untouched: <belum disentuh>
next: <3 move>
```

---
Scaffold: `targets/<proto>/scope.md findings/ evidence/ recon/`
Ingat: Onyx lesson 4 jam kebuang karena `startPrank(owner)` = out-of-scope. Phase 0 dulu, PoC belakangan.
