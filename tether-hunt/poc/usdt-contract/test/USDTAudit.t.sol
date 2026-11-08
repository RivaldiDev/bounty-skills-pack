// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {IUSDT} from "../src/IUSDT.sol";

/// @title USDT (TetherToken) adversarial test harness
/// @notice Runs against a local fork of Ethereum mainnet at a pinned block.
///         The deployed contract is used directly through its real interface.
contract USDTAuditTest is Test {
    IUSDT constant USDT = IUSDT(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    address constant OWNER = 0xC6CDE7C39eB2f0F0095F41570af89eFC2C1Ea828;

    address attacker = address(0xA77ACC);
    address victim = address(0xB0B);

    function setUp() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"));
    }

    // T1: owner and pause state match the audited source
    function test_T1_owner_and_state() public view {
        assertEq(USDT.owner(), OWNER, "owner");
        assertEq(USDT.paused(), false, "paused");
        assertEq(USDT.deprecated(), false, "deprecated");
        assertEq(USDT.basisPointsRate(), 0, "bps");
        assertEq(USDT.maximumFee(), 0, "maxFee");
        console2.log("owner", USDT.owner());
        console2.log("totalSupply", USDT.totalSupply());
    }

    // T2: onlyOwner on issue, redeem, pause, deprecate, blacklist
    function test_T2_onlyOwner_guards() public {
        vm.startPrank(attacker);
        vm.expectRevert();
        USDT.issue(1_000_000e6);
        vm.expectRevert();
        USDT.redeem(1);
        vm.expectRevert();
        USDT.pause();
        vm.expectRevert();
        USDT.deprecate(attacker);
        vm.expectRevert();
        USDT.addBlackList(victim);
        vm.expectRevert();
        USDT.transferOwnership(attacker);
        vm.stopPrank();
        console2.log("all owner-only paths reverted for attacker");
    }

    // T3: blacklisted sender cannot transfer
    function test_T3_blacklist_blocks_transfer() public {
        deal(address(USDT), victim, 1_000e6);
        vm.prank(OWNER);
        USDT.addBlackList(victim);
        assertTrue(USDT.isBlackListed(victim));
        vm.prank(victim);
        vm.expectRevert();
        USDT.transfer(attacker, 100e6);
        console2.log("blacklisted sender blocked");
    }

    // T4: transferFrom with MAX_UINT allowance does not decrement
    function test_T4_infinite_allowance() public {
        deal(address(USDT), victim, 1_000e6);
        vm.prank(victim);
        USDT.approve(attacker, type(uint256).max);
        vm.prank(attacker);
        USDT.transferFrom(victim, attacker, 100e6);
        assertEq(USDT.allowance(victim, attacker), type(uint256).max);
        console2.log("infinite allowance preserved");
    }

    // T5: approve race guard (must reset to 0 first)
    function test_T5_approve_race_guard() public {
        vm.startPrank(victim);
        USDT.approve(attacker, 100e6);
        vm.expectRevert();
        USDT.approve(attacker, 200e6);
        USDT.approve(attacker, 0);
        USDT.approve(attacker, 200e6);
        vm.stopPrank();
        console2.log("approve race guard active");
    }

    // T6: setParams bounds are enforced
    function test_T6_setParams_bounds() public {
        vm.startPrank(OWNER);
        vm.expectRevert();
        USDT.setParams(20, 0);
        vm.expectRevert();
        USDT.setParams(0, 50);
        vm.stopPrank();
        console2.log("setParams hard bounds enforced");
    }

    // T7: short address attack is blocked by onlyPayloadSize
    function test_T7_short_address_blocked() public {
        deal(address(USDT), victim, 1_000e6);
        bytes memory shortCalldata = abi.encodeWithSelector(bytes4(0xa9059cbb), attacker);
        vm.prank(victim);
        (bool ok,) = address(USDT).call(shortCalldata);
        assertFalse(ok, "short calldata must revert");
        console2.log("short address payload rejected");
    }
}