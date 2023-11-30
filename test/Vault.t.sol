// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {Test, console} from "forge-std/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Vault} from "@contracts/Vault.sol";
import {Errors} from "@libraries/Errors.sol";
import {TestERC20} from "./token/TestERC20.sol";

contract VaultTest is Test {
    Vault public vault;
    address owner;
    address user;
    TestERC20 erc20;

    bool constant RUNNING = true;
    bool constant PAUSED = false;

    function setUp() public {
        owner = vm.addr(0x1);
        user = vm.addr(0x2);
        vm.prank(owner);
        vault = new Vault();
    }

    function deployErc20() public {
        vm.startPrank(owner);
        erc20 = new TestERC20();
        vault.registerToken(address(erc20));
        vm.stopPrank();
    }

    /*///////////////////////////////////////////////////
                        registerToken
    ///////////////////////////////////////////////////*/

    function test_Success_registerToken_ByAdmin(address token) public {
        vm.prank(owner);
        // fuzz token's address
        vault.registerToken(token);
        assertEq(vault.isWhitelisted(token), true);
    }

    function test_Fail_registerToken_ByUser(address token) public {
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        vault.registerToken(token);
    }

    function test_Fail_registerToken_Duplicated(address token) public {
        vm.startPrank(owner);
        vault.registerToken(token);
        vm.expectRevert(Errors.AlreadyRegistered.selector);
        vault.registerToken(token);
        vm.stopPrank();
    }

    /*///////////////////////////////////////////////////
                    pause & unpause
    ///////////////////////////////////////////////////*/

    function test_Success_pause_ByAdmin() public {
        assertEq(vault.status(), RUNNING);
        vm.prank(owner);
        vault.pause();
        assertEq(vault.status(), PAUSED);
    }

    function test_Fail_pause_ByUser() public {
        assertEq(vault.status(), RUNNING);
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        vault.pause();
    }

    function test_Fail_pause_Again() public {
        vm.startPrank(owner);
        vault.pause();
        vm.expectRevert(Errors.AlreadyPaused.selector);
        vault.pause();
        vm.stopPrank();
    }

    function test_Success_unpause_ByAdmin() public {
        assertEq(vault.status(), RUNNING);
        vm.startPrank(owner);
        vault.pause();
        vault.unpause();
        assertEq(vault.status(), RUNNING);
        vm.stopPrank();
    }

    function test_Fail_unpause_ByUser() public {
        assertEq(vault.status(), RUNNING);
        vm.prank(owner);
        vault.pause();
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        vault.unpause();
    }

    function test_Fail_unpause_Again() public {
        vm.startPrank(owner);
        vault.pause();
        vault.unpause();
        vm.expectRevert(Errors.AlreadyRunning.selector);
        vault.unpause();
        vm.stopPrank();
    }

    /*///////////////////////////////////////////////////
                        deposit
    ///////////////////////////////////////////////////*/

    function test_Success_deposit(uint256 amount) public {
        deployErc20();

        vm.prank(owner);
        erc20.mint(user, amount);

        vm.startPrank(user);
        erc20.approve(address(vault), amount);
        vault.deposit(address(erc20), amount);
        assertEq(vault.balances(user, address(erc20)), amount);
        assertEq(erc20.balanceOf(user), 0);
        assertEq(erc20.balanceOf(address(vault)), amount);
        vm.stopPrank();
    }

    function test_Fail_deposit_WhenPaused(uint256 amount) public {
        deployErc20();

        vm.startPrank(owner);
        erc20.mint(user, amount);
        vault.pause();
        vm.stopPrank();

        vm.startPrank(user);
        erc20.approve(address(vault), amount);
        vm.expectRevert(Errors.ActionWhenPaused.selector);
        vault.deposit(address(erc20), amount);
        vm.stopPrank();
    }

    function test_Fail_deposit_WithInvalidToken(address token, uint256 amount) public {
        vm.startPrank(user);
        vm.expectRevert(Errors.UnauthorizedToken.selector);
        vault.deposit(token, amount);
        vm.stopPrank();
    }

    /*///////////////////////////////////////////////////
                        withdraw
    ///////////////////////////////////////////////////*/

    function test_Success_withdraw(uint256 amount) public {
        deployErc20();

        vm.prank(owner);
        erc20.mint(user, amount);

        vm.startPrank(user);
        erc20.approve(address(vault), amount);
        vault.deposit(address(erc20), amount);

        vault.withdraw(address(erc20), amount / 2);
        assertEq(erc20.balanceOf(user), amount / 2);
        assertEq(vault.balances(user, address(erc20)), amount - amount / 2);
        vm.stopPrank();
    }

    function test_Fail_withdraw_WhenPaused(uint256 amount) public {
        deployErc20();

        // mint erc20 to user
        vm.startPrank(owner);
        erc20.mint(user, amount);
        vm.stopPrank();

        // deposit
        vm.startPrank(user);
        erc20.approve(address(vault), amount);
        vault.deposit(address(erc20), amount);
        vm.stopPrank();

        // pause the vault
        vm.prank(owner);
        vault.pause();

        // try to withdraw
        vm.startPrank(user);
        vm.expectRevert(Errors.ActionWhenPaused.selector);
        vault.withdraw(address(erc20), amount / 2);
        vm.stopPrank();
    }

    function test_Fail_withdraw_WithInvalidToken(address token, uint256 amount) public {
        vm.startPrank(user);
        vm.expectRevert(Errors.UnauthorizedToken.selector);
        vault.withdraw(token, amount);
        vm.stopPrank();
    }

    function test_Fail_withdraw_WithInvalidAmount() public {
        deployErc20();

        uint256 amount = 0x100;

        vm.prank(owner);
        erc20.mint(user, amount);

        vm.startPrank(user);
        erc20.approve(address(vault), amount);
        vault.deposit(address(erc20), amount);

        vm.expectRevert(abi.encodeWithSelector(Errors.NotEnoughBalance.selector, user, address(erc20), amount * 2));
        vault.withdraw(address(erc20), amount * 2);
        vm.stopPrank();
    }
}
