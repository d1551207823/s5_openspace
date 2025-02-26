// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MyToken} from "../src/MyToken.sol";
import {console, Script} from "forge-std/Script.sol";
contract MyTokenScript is Script {
    function setUp() public {}

    function deploy() public {
        vm.startBroadcast();
        {
            MyToken Token = new MyToken("MyToken", "MTK");
            console.log("Token deployed at address: ", address(Token));
            console.log("Token name: ", Token.name());
            console.log("Token symbol: ", Token.symbol());        }
        vm.stopBroadcast();
    }
}
