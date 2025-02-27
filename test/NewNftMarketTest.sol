// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../src/NewNftMarket.sol"; // 只导入 NFTMarket.sol，其中包含所有合约

contract NFTMarketTest is Test {
    MyEip2612Token token;
    MyNFT nft;
    NFTMarket market;

    // owner 使用私钥 1 对应的地址
    address owner = 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf;
    // buyer 使用私钥 2 对应的地址
    address buyer = 0x2B5AD5c4795c026514f8317c7a215E218DcCD6cF;
    address seller = address(0x2); // 模拟卖家
    uint256 tokenId = 1;
    uint256 price = 100 ether;     // NFT 价格

    bytes32 constant PERMIT_TYPEHASH = keccak256(
        "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
    );

    function setUp() public {
        // 部署合约时指定 owner
        vm.startPrank(owner);
        token = new MyEip2612Token();
        nft = new MyNFT();
        market = new NFTMarket(address(token), address(nft));
        vm.stopPrank();

        // 给卖家铸造 NFT 并上架
        vm.prank(owner);
        nft.mint(seller);
        vm.prank(seller);
        nft.approve(address(market), tokenId);
        vm.prank(seller);
        market.listNFT(tokenId, price);

        // 给买家分配 token
        vm.prank(owner);
        token.mint(buyer, 1000 ether);
    }

    function testBuyNFT() public {
        vm.prank(buyer);
        token.approve(address(market), price);

        vm.prank(buyer);
        market.buyNFT(tokenId);

        assertEq(nft.ownerOf(tokenId), buyer, "NFT should be transferred to buyer");
        assertEq(token.balanceOf(seller), price, "Seller should receive payment");
        assertEq(market.isForSale(tokenId), false, "NFT should no longer be for sale");
    }

    function testPermitBuy() public {
        uint256 nonce = market.nonces(buyer);
        uint256 deadline = block.timestamp + 1 hours;

        // 白名单签名 (owner 使用私钥 1)
        bytes32 whitelistStructHash = keccak256(
            abi.encode(
                market.WHITELIST_TYPEHASH(),
                buyer,
                tokenId,
                nonce
            )
        );
        bytes32 domainSeparator = market.DOMAIN_SEPARATOR();
        bytes32 whitelistDigest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, whitelistStructHash));
        (uint8 vWhitelist, bytes32 rWhitelist, bytes32 sWhitelist) = vm.sign(1, whitelistDigest);

        // ERC20Permit 签名 (buyer 使用私钥 2)
        uint256 tokenNonce = token.nonces(buyer);
        bytes32 permitStructHash = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                buyer,
                address(market),
                price,
                tokenNonce,
                deadline
            )
        );
        bytes32 permitDigest = keccak256(abi.encodePacked("\x19\x01", token.DOMAIN_SEPARATOR(), permitStructHash));
        (uint8 vPermit, bytes32 rPermit, bytes32 sPermit) = vm.sign(2, permitDigest);

        // 执行 permitBuy
        vm.prank(buyer);
        market.permitBuy(tokenId, deadline, vPermit, rPermit, sPermit, vWhitelist, rWhitelist, sWhitelist);

        // 验证结果
        assertEq(nft.ownerOf(tokenId), buyer, "NFT should be transferred to buyer");
        assertEq(token.balanceOf(seller), price, "Seller should receive payment");
        assertEq(market.isForSale(tokenId), false, "NFT should no longer be for sale");
        assertEq(market.nonces(buyer), token.nonces(buyer), "Nonce should increment");
    }
}