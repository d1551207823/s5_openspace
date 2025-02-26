// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import "../src/Bank.sol";

contract BankTest is Test {
    Bank bank;

    function setUp() public {
        bank = new Bank();
    }
    function testDepositETH() public {
        uint initialBalance = bank.balanceOf(address(this));//用本合约地址作为测试地址
        console.log( "initialBalance:", initialBalance);
        uint depositAmount = 1 ether;//存1ETH   
        vm.expectEmit(true, true, false, true);//事件断言
        //还需要定义Deposit事件
        emit Deposit(address(this), depositAmount);//触发事件
        bank.depositETH{value: depositAmount}();
        uint newBalance = bank.balanceOf(address(this));
        console.log( "newBalance:", newBalance);
        assertEq(newBalance, initialBalance + depositAmount);//余额断言
    }
    event Deposit(address indexed user, uint amount);
}
