# Analysis — USDT (TetherToken) contract audit

Date: 2026-11-08. Chain: Ethereum mainnet. Fork block 26,369,797.

## 1. Source provenance

| Fact | Value |
|---|---|
| Contract | 0xdAC17F958D2ee523a2206206994597C13D831ec7 |
| Source | Sourcify full match, file TetherToken.sol |
| Compiler | solc 0.4.18+commit.9cf6e910 |
| Optimizer | disabled |
| Local rebuild | byte-identical to the deployed runtime code, 11,075 bytes |
| EIP-170 limit | 24,576 bytes. The contract is under the limit by a wide margin. |

The byte-identical rebuild is the important fact. It proves the audited source is exactly the
code that runs on mainnet. No proxy, no hidden logic, no unverified library.

## 2. Live state at fork block

| Field | Value |
|---|---|
| owner | 0xC6CDE7C39eB2f0F0095F41570af89eFC2C1Ea828 |
| paused | false |
| deprecated | false |
| upgradedAddress | 0x0000000000000000000000000000000000000000 |
| basisPointsRate | 0 |
| maximumFee | 0 |
| totalSupply | 84,298,550,180,940,091 (about 84.3 billion with 6 decimals) |

## 3. Attack surface

Every external function, grouped by who can call it.

### Unrestricted, state changing

| Function | Guard | Note |
|---|---|---|
| transfer | whenNotPaused, sender not blacklisted | onlyPayloadSize(64) |
| transferFrom | whenNotPaused, from not blacklisted | onlyPayloadSize(96) |
| approve | none | onlyPayloadSize(64), race guard |

### Owner only

| Function | Guard | Note |
|---|---|---|
| issue | onlyOwner | overflow checked by two require statements |
| redeem | onlyOwner | balance and supply checked |
| pause, unpause | onlyOwner | |
| deprecate | onlyOwner | switches every method to the upgraded contract |
| addBlackList, removeBlackList | onlyOwner | |
| destroyBlackFunds | onlyOwner plus isBlackListed | zeroes balance and reduces supply |
| transferOwnership | onlyOwner | zero address is ignored |
| setParams | onlyOwner | newBasisPoints < 20, newMaxFee < 50 |

### View

balanceOf, allowance, totalSupply, owner, getOwner, getBlackListStatus, isBlackListed,
paused, deprecated, upgradedAddress, basisPointsRate, maximumFee, name, symbol, decimals.

## 4. Fork test results

Command: forge test in poc/usdt-contract against a mainnet fork.

| Test | What it proves | Result |
|---|---|---|
| T1 | owner and pause state match the audited source | PASS |
| T2 | issue, redeem, pause, deprecate, addBlackList, transferOwnership all revert for a non-owner | PASS |
| T3 | a blacklisted sender cannot transfer | PASS |
| T4 | a MAX_UINT allowance is not decremented (infinite approval) | PASS |
| T5 | approve from a non-zero value to a non-zero value reverts | PASS |
| T6 | setParams rejects 20 basis points and 50 max fee | PASS |
| T7 | a short calldata transfer reverts | PASS |

Seven of seven passed. The unprivileged surface holds.

## 5. Observations that are not exploitable

These are recorded so that later batches do not re-report them.

### 5.1 transferFrom does not check the recipient blacklist

Line 346 to 353. The sender is checked. The recipient is not. A blacklisted address can still
receive tokens. This is a deliberate design choice. It lets the owner recover funds to a
blacklisted address and it lets a blacklisted address be credited. It does not let an attacker
move funds out. Not a finding.

### 5.2 destroyBlackFunds does not check for underflow

Line 291 uses `_totalSupply -= dirtyFunds` without SafeMath. Solidity 0.4.18 does not revert on
underflow by default. However, the function only runs for a blacklisted address, and the
balance of that address is always less than or equal to totalSupply, because every balance is
a subset of supply. The subtraction therefore cannot underflow in a reachable state. Not a
finding.

### 5.3 approve race guard is stricter than ERC-20

Line 201 requires the allowance to be zero before a new non-zero value is set. This blocks the
classic approve race. It also breaks some integrators that expect to update an allowance in one
call. This is a compatibility note, not a security bug.

### 5.4 Owner can pause, blacklist and mint

The owner can pause all transfers, blacklist any address, and issue new tokens. These are
documented powers of the contract. They are not a vulnerability. They are a centralisation
fact. The program pays for a vulnerability that lets an attacker steal or mint. An owner power
is not that.

### 5.5 No reentrancy surface

The contract makes no external call except in the deprecated path, where it calls the upgraded
contract. The upgraded address is zero and deprecated is false, so that path is dead. There is
no callback into user code. No reentrancy.

### 5.6 The deprecated path is the only external call

If the owner ever calls deprecate, every transfer forwards to the upgraded contract. The
upgraded contract must be trusted. That is an owner action, not an attacker path.

## 6. Conclusion

No unprivileged path to steal, mint, or freeze another user's funds was found in the USDT
contract. The owner-only guards hold under fork tests. The deployed code matches the audited
source exactly.

The contract is a 2017 era design. Its risk is centralisation, not a coding defect.

## 7. Other Tether contracts

The program names "Tether Tokens Smart Contracts" as a group. USDT on Ethereum is one of them.
The same source is deployed on many chains. XAUt (Tether Gold) is a different contract and is
the subject of a 2020 public transfer bug that is already fixed. A later batch can audit XAUt
and the cross-chain deployments if the operator wants to continue the contract track.
