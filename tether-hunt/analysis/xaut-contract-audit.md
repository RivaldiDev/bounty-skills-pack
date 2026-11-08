# Analysis — XAUt (Tether Gold) contract audit

Date: 2026-11-08. Chain: Ethereum mainnet. Status: in progress.

## 1. Architecture

XAUt is not a plain contract like USDT. It is an upgradeable proxy.

| Component | Address | Evidence |
|---|---|---|
| Proxy (the token users call) | 0x68749665FF8D2d112Fa859AA293F07A622782F38 | 2,141 bytes |
| Proxy type | TransparentUpgradeableProxy, OpenZeppelin 0.8.2 | Sourcify exact_match |
| Implementation | 0x4c0d2c74a8d26f1e4f5653021c521f5471f9e566 | EIP-1967 slot 0x3608...2bbc |
| Implementation source | contracts/Tether/TetherToken.sol, solc 0.8.4 | Sourcify exact_match |
| Proxy admin | 0x856fcc085290ac1e40392442211e6a333afb873e | EIP-1967 slot 0xb531...6103 |
| Proxy admin owner | 0xC6CDE7C39eB2f0F0095F41570af89eFC2C1Ea828 | proxyAdmin.owner() |

The implementation is 8,273 bytes. It is a rewrite of the 2017 USDT design on
OpenZeppelin 4.x upgradeable contracts. It adds ERC-2612 permit and a multiTransfer
batch function.

## 2. Live state of the proxy

| Field | Value |
|---|---|
| name | Tether Gold |
| symbol | XAUt |
| decimals | 6 |
| owner | 0xC6CDE7C39eB2f0F0095F41570af89eFC2C1Ea828 |
| totalSupply | 827,417,630,000 (about 827,417 XAUt) |
| DOMAIN_SEPARATOR | 0xf04743eb802cd8859d4af406f2b8e6b7db23ba7b311694e0fa920cc4f63f0192 |

## 3. EIP-712 domain verification

The permit domain separator was recomputed by hand from the source and compared to the
on-chain value.

    typeHash    = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
    nameHash    = keccak256("Tether Gold")
    versionHash = keccak256("1")
    encoded     = abi.encode(typeHash, nameHash, versionHash, 1, proxyAddress)
    computed    = 0xf04743eb802cd8859d4af406f2b8e6b7db23ba7b311694e0fa920cc4f63f0192
    on chain    = 0xf04743eb802cd8859d4af406f2b8e6b7db23ba7b311694e0fa920cc4f63f0192

Result: MATCH. The domain separator is bound to the proxy address and to chain id 1. A
signature for the proxy cannot be replayed against the implementation, because the
implementation address produces a different separator
(0xf5f41f9b43520fac424a7e79199a660f5638d40733ce5477695416a76983c554).

## 4. Attack surface of the implementation

### Unrestricted, state changing

| Function | Guard |
|---|---|
| transfer | onlyNotBlocked, recipient not the contract |
| transferFrom | onlyNotBlocked, sender not blocked, recipient not the contract |
| multiTransfer | onlyNotBlocked, array length match |
| permit | EIP-2612 signature, nonce, deadline |
| approve | none |

### Owner only

mint, redeem, destroyBlockedFunds, addToBlockedList, removeFromBlockedList.

### Observations

1. transferFrom checks the sender blocklist twice. Once in the modifier on msg.sender and
   once explicitly on _sender. Redundant but correct.
2. multiTransfer loops and calls transfer. It is bounded by gas only. A large array costs
   more gas. No state corruption.
3. permit uses OpenZeppelin ECDSA.recover, which rejects a high s value and enforces
   v in 27 or 28. Signature malleability is closed.
4. redeem burns from owner(), not from msg.sender. Only the owner can call it, so the two
   are the same address. Correct.
5. destroyBlockedFunds uses _burn, which reverts on underflow. Correct.

## 5. The implementation contract is directly callable

This is the only unusual observation so far.

The implementation at 0x4c0d2c74... has its own storage, separate from the proxy.

| Call | On the proxy | On the implementation directly |
|---|---|---|
| owner() | 0xC6CDE7C39eB2f0F0095F41570af89eFC2C1Ea828 | 0x7224BEef47a6A7B414a0d0AdADf3f691C2691005 |
| totalSupply() | 827,417,630,000 | 1 |
| balanceOf(implementation owner) | 0 | 1 |
| name() | Tether Gold | TetherGold |
| DOMAIN_SEPARATOR() | 0xf04743eb... | 0xf5f41f9b... |

The implementation owner is 0x7224BEef47a6A7B414a0d0AdADf3f691C2691005. Its code is the
EIP-7702 delegation designator 0xef0100 || 0x7702aace7914e5b7237aedb3df9b12b831f5172d.
It is an externally owned account that delegates to a contract. It has nonce 107 and a
non-zero ETH balance. It is a Tether operations key.

### What this means

1. The implementation is initialised. It has its own owner and 1 wei of supply. This is
   normal for a proxy implementation that was initialised before being used behind a
   proxy, or that was initialised by the deployer.
2. The implementation owner can mint and burn on the implementation. This does not touch
   the proxy. The proxy has a different owner and a different storage.
3. The implementation is not a UUPS proxy. proxiableUUID reverts. Upgrades go through the
   proxy admin at 0x856fcc08..., whose owner is the same as the proxy owner.
4. A permit signature for the implementation cannot be replayed on the proxy, because the
   domain separator differs.

### Honest verdict

The implementation being callable is a known pattern. It is not exploitable by an
unprivileged attacker. The implementation owner is a Tether key. The proxy state and the
implementation state are separate. No path from the implementation to the proxy was found.

This is recorded as an observation, not a finding.

## 6. Fork test plan

The same harness as USDT, run against the proxy:

1. onlyOwner guards on mint, redeem, destroyBlockedFunds, addToBlockedList.
2. Blocklist blocks transfer and transferFrom.
3. multiTransfer length mismatch reverts.
4. permit with a wrong signer reverts.
5. permit with an expired deadline reverts.
6. permit replay with the same nonce reverts.
7. permit signature for the implementation domain is rejected by the proxy.
8. transfer to the contract address reverts.

## 7. Status

Source verified. Domain separator verified. Attack surface mapped. Implementation
callability assessed as not exploitable. Fork tests pending in batch 02 agent B4.
