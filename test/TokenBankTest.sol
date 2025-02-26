// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/TokenBank.sol";

contract TokenBankTest is Test {
    BaseERC20 token;
    TokenBank bank;
    address owner;
    address user1;
    uint256 user1PrivateKey;

    function setUp() public {
        owner = address(this);
        token = new BaseERC20();
        bank = new TokenBank(address(token));
        user1PrivateKey = 0x1; 
        user1 = vm.addr(user1PrivateKey);
        token.transfer(user1, 100 ether);
    }

    function testPermitDepositSuccess() public {
        uint256 amount = 10 ether;
        uint256 deadline = block.timestamp + 15 minutes;
        (uint8 v, bytes32 r, bytes32 s) = signPermit(user1, address(bank), amount, deadline);
        // 调用 permitDeposit
        vm.prank(user1);
        bank.permitDeposit(amount, deadline, v, r, s);
        assertEq(token.balanceOf(address(bank)), amount, "Bank should have received tokens");
        assertEq(bank.balances(user1), amount, "User balance in bank should be updated");
        assertEq(token.balanceOf(user1), 90 ether, "User token balance should decrease");
    }

    function signPermit(address owner_, address spender, uint256 value, uint256 deadline)
        internal
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        bytes32 domainSeparator = token.DOMAIN_SEPARATOR();
        bytes32 permitTypehash = keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );
        uint256 nonce = token.nonces(owner_);
        bytes32 structHash = keccak256(
            abi.encode(permitTypehash, owner_, spender, value, nonce, deadline)
        );
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        (v, r, s) = vm.sign(user1PrivateKey, digest);
    }
}