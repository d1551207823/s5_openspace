// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract MyToken is ERC20, ERC20Permit {
    // 初始供应量，可以根据需要调整
    uint256 constant INITIAL_SUPPLY = 1000000 * (10**18); // 1 million tokens with 18 decimals

    constructor() ERC20("MyToken", "MTK") ERC20Permit("MyToken") {
        _mint(msg.sender, INITIAL_SUPPLY);
    }
}