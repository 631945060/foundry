// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "forge-std/Test.sol";
import {TokenBank, BaseERC20, IBaseERC20} from "../src/TokenBank.sol";

contract TokenBankTest is Test {
    BaseERC20 internal token;
    TokenBank internal bank;

    address internal user1 = address(0x111);
    address internal user2 = address(0x222);

    function setUp() public {
        // 部署基础 ERC20，并将初始供应分给本测试合约
        token = new BaseERC20();

        // 部署银行合约，指向 token 地址
        bank = new TokenBank(address(token));

        // 给 user1 分配一些初始代币用于测试
        token.transfer(user1, 1_000 ether);
    }

    function testDepositSuccess() public {
        uint256 amount = 100 ether;

        // user1 授权并存款
        vm.startPrank(user1);
        token.approve(address(bank), amount);
        bank.deposit(amount);
        vm.stopPrank();

        // 断言：银行记录与余额
        assertEq(bank.getDepositBalance(user1), amount, "deposit record mismatch");
        assertEq(bank.getTotalBalance(), amount, "bank total balance mismatch");

        // 断言：user1 余额减少
        assertEq(token.balanceOf(user1), 900 ether, "user1 balance should decrease");
        // 断言：银行合约地址的 token 余额增加
        assertEq(token.balanceOf(address(bank)), amount, "bank token balance mismatch");
    }

    function testDepositZeroReverts() public {
        vm.startPrank(user1);
        vm.expectRevert(bytes("TokenBank: amount must be greater than 0"));
        bank.deposit(0);
        vm.stopPrank();
    }

    function testWithdrawSuccess() public {
        uint256 amount = 300 ether;
        uint256 withdrawAmount = 120 ether;

        // 存款
        vm.startPrank(user1);
        token.approve(address(bank), amount);
        bank.deposit(amount);

        // 取款
        bank.withdraw(withdrawAmount);
        vm.stopPrank();

        // 断言：存款记录减少
        assertEq(bank.getDepositBalance(user1), amount - withdrawAmount, "deposit record after withdraw mismatch");
        // 断言：银行余额减少
        assertEq(bank.getTotalBalance(), amount - withdrawAmount, "bank total after withdraw mismatch");
        // 断言：user1 余额增加（初始 1000 ether - 存款 300 + 取回 120 = 820）
        assertEq(token.balanceOf(user1), 820 ether, "user1 token balance after withdraw mismatch");
    }

    function testWithdrawInsufficientReverts() public {
        uint256 amount = 50 ether;

        // 存入 50
        vm.startPrank(user1);
        token.approve(address(bank), amount);
        bank.deposit(amount);
        // 尝试超额提取 60，应 revert
        vm.expectRevert(bytes("TokenBank: insufficient balance"));
        bank.withdraw(60 ether);
        vm.stopPrank();
    }

    function testGetters() public {
        // 初始银行余额为 0
        assertEq(bank.getTotalBalance(), 0, "initial bank total should be zero");

        // 存款后，getDepositBalance 与 getTotalBalance 应更新
        vm.startPrank(user1);
        token.approve(address(bank), 200 ether);
        bank.deposit(200 ether);
        vm.stopPrank();

        assertEq(bank.getDepositBalance(user1), 200 ether, "deposit balance mismatch");
        assertEq(bank.getTotalBalance(), 200 ether, "total balance mismatch");

        // 另一个用户未存款，其存款余额应为 0
        assertEq(bank.getDepositBalance(user2), 0, "user2 deposit should be zero");
    }
}


