// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title IXAUt
/// @notice Interface of the Tether Gold (XAUt) implementation contract TetherToken.
/// @dev Rebuilt from the verified Sourcify source of implementation
///      0x4C0d2c74A8D26f1E4F5653021c521F5471F9e566 (solc 0.8.4, optimizer 200).
///      The proxy 0x68749665FF8D2d112Fa859AA293F07A622782F38 is a
///      TransparentUpgradeableProxy (OpenZeppelin 4.x, solc 0.8.2).
interface IXAUt {
    // ------------------------------------------------------------------
    // ERC-20 core
    // ------------------------------------------------------------------
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    // ------------------------------------------------------------------
    // XAUt additions
    // ------------------------------------------------------------------
    function multiTransfer(address[] memory recipients, uint256[] memory values) external;

    // ------------------------------------------------------------------
    // Owner only
    // ------------------------------------------------------------------
    function mint(address destination, uint256 amount) external;
    function redeem(uint256 amount) external;
    function destroyBlockedFunds(address blockedUser) external;
    function addToBlockedList(address user) external;
    function removeFromBlockedList(address user) external;
    function transferOwnership(address newOwner) external;
    function renounceOwnership() external;

    // ------------------------------------------------------------------
    // EIP-2612 permit
    // ------------------------------------------------------------------
    // ------------------------------------------------------------------
    // Initializer (locked after deployment)
    // ------------------------------------------------------------------
    function initialize(string memory name_, string memory symbol_, uint8 decimals_) external;

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
    function nonces(address owner) external view returns (uint256);
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    // ------------------------------------------------------------------
    // Views
    // ------------------------------------------------------------------
    function owner() external view returns (address);
    function isBlocked(address user) external view returns (bool);
    function isTrusted(address user) external view returns (bool);

    // ------------------------------------------------------------------
    // Proxy admin surface (reverts for non admin)
    // ------------------------------------------------------------------
    function admin() external returns (address);
    function implementation() external returns (address);
    function upgradeTo(address newImplementation) external;
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable;
    function changeAdmin(address newAdmin) external;
}
