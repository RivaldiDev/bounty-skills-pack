// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IUSDT {
    function owner() external view returns (address);
    function paused() external view returns (bool);
    function deprecated() external view returns (bool);
    function upgradedAddress() external view returns (address);
    function basisPointsRate() external view returns (uint256);
    function maximumFee() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function isBlackListed(address user) external view returns (bool);
    function transfer(address to, uint256 value) external;
    function transferFrom(address from, address to, uint256 value) external;
    function approve(address spender, uint256 value) external;
    function issue(uint256 amount) external;
    function redeem(uint256 amount) external;
    function pause() external;
    function deprecate(address upgraded) external;
    function addBlackList(address user) external;
    function transferOwnership(address newOwner) external;
    function setParams(uint256 newBasisPoints, uint256 newMaxFee) external;
}
