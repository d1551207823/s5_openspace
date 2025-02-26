pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import   "../src/NftMarket.sol";
import '../src/NFT721.sol';
import '../src/ERC20Token.sol';
contract NftMarketTest is Test {
    NftMarket public Market;
    address public MarketAddress;
    ERC20Token public Token;
    BaseERC721 public Nft;
    address public alice;
    address public bob;
    function setUp() public {
    //假设随便创建一个NFT
        Nft = new BaseERC721("NftName","NftSymbol");
        Token = new ERC20Token("ListTokenName","ListTokenSymbol");
        Market = new NftMarket(address(Nft));
        MarketAddress = address(Market);
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        //写的ERC20有点问题，这里先手动mint
        vm.startPrank(alice);
        Token._mint(1000);
        vm.startPrank(bob);
        Token._mint(1000);
        Nft.mint(alice,1);
        Nft.mint(alice,2);
        Nft.mint(bob,3);
    }
  // 编写成功测试用例
    function test_successListNft() public {
        //假设用户自己选择了一个挂单的Token
        console.log("token address:",address(Token));
        //设置调用者为alice
        vm.startPrank(alice);
        Market.listNft(1,address(Token),1 ether);
    }

    function test_errorListNft() public {
        console.log("token address:",address(Token));
        //设置调用者为bob去挂单alice的NFT
        vm.expectRevert("NftMarket: only owner can list nft");
        vm.startPrank(bob);
        Market.listNft(1,address(Token),1 ether);
    }
    /**
        * 测试成功购买NFT
     */
    function test_successBuyNft() public{
        //先打印下余额
        console.log("alice balance:",Token.balanceOf(alice));
        console.log("bob balance:",Token.balanceOf(bob));
        //设置alice挂单
        vm.startPrank(alice);
        vm.expectEmit(false, false, false, false);
        emit NftListed(1,address(Token),1 ether,alice);
        Market.listNft(1,address(Token),1 ether);
        //设置bob购买
        vm.startPrank(bob);
        vm.expectEmit(false, false, false, false);
        emit BuyNft(1,address(Token),1 ether,bob);
        Market.buyNFT(1);
    }


    //测试自己购买自己的NFT
    function test_ownerBuyOwnerNFT() public{
        //设置alice挂单
        vm.startPrank(alice);
        vm.expectEmit(false, false, false, false);
        emit NftListed(1,address(Token),1 ether,alice);
        Market.listNft(1,address(Token),1 ether);
        //直接购买
        vm.expectRevert("NftMarket: can't buy your own nft");
        Market.buyNFT(1);
    }
    
    //测试购买不存在的NFT(重复购买,已经被买过了)
    function test_buyNotExistNFT() public{
        //设置alice挂单
        vm.startPrank(alice);
        vm.expectEmit(false, false, false, false);
        emit NftListed(1,address(Token),1 ether,alice);
        Market.listNft(1,address(Token),1 ether);
        //设置bob购买
        vm.startPrank(bob);
        vm.expectEmit(false, false, false, false);
        emit BuyNft(1,address(Token),1 ether,bob);
        Market.buyNFT(1);
        //再次购买
        vm.expectRevert("NftMarket: nft not listed");
        Market.buyNFT(1);
    }

    //购买测试支付的Token不足或过多
    function test_buyNFTNotEnoughToken() public{
        //设置alice挂单
        vm.startPrank(alice);
        vm.expectEmit(false, false, false, false);
        emit NftListed(1,address(Token),1 ether,alice);
        Market.listNft(1,address(Token),1 ether);
        //设置bob购买
        vm.startPrank(bob);
        //设置BOB余额为0
        deal(address(Token),bob,0);
        vm.expectRevert("NftMarket: not enough token");
        Market.buyNFT(1);
    }


    //模糊测试：测试随机使用 0.01-10000 Token价格上架NFT，并随机使用任意Address购买NFT
    function testFuzzListAndBuyNFT(uint256 price, address randomBuyer) public {
        vm.startPrank(alice);
        vm.assume(price >= 0.01 * 10**18 && price <= 10000 * 10**18);
        vm.assume(randomBuyer != address(0) && randomBuyer != alice);
        // List NFT
        Market.listNft(1, address(Token), price);
        vm.expectRevert("NftMarket: not enough token");//永远会出这个错，因为调用购买的时候没有设置value的Token值
        vm.startPrank(randomBuyer);
        Market.buyNFT(1);
        vm.stopPrank();
    }


    event BuyNft(uint256 indexed tokenId, address indexed token, uint256 price, address indexed owner);
    event NftListed(uint256 indexed tokenId, address indexed token, uint256 price, address indexed owner);
}