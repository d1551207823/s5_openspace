pragma solidity ^0.8.23;
import {console} from "forge-std/Test.sol";
import "../src/NFT721.sol";
import "../src/ERC20Token.sol";

contract NftMarket {
    address public owner;
    ERC20Token public token;
    BaseERC721 public nft;
    struct  NftItem {
        uint256 tokenId;
        address token;
        uint256 price;
        address owner;
    }
    mapping(uint256 => NftItem) public marketList;
    event NftListed(uint256 indexed tokenId, address indexed token, uint256 price, address indexed owner);
    event NftUnlisted(uint256 indexed tokenId, address indexed token, address indexed owner);
    event BuyNft(uint256 indexed tokenId, address indexed token, uint256 price, address indexed owner);
    constructor(address _nftAddress) {
        owner = msg.sender;
        nft = BaseERC721(_nftAddress); // Initialize nft contract
    }
    function listNft(uint256 _tokenId,address _token ,uint256 _price) public {
        // 检查调用者是否为 NFT 的拥有者
        require(msg.sender == nft.ownerOf(_tokenId), "NftMarket: only owner can list nft");
        // 检查是否已经上架
        require(marketList[_tokenId].tokenId == 0, "NftMarket: nft already listed");
        // 授权市场合约处理该 NFT
       // nft.approve(address(this), _tokenId); // 只有 NFT 的拥有者才能调用 approve
        marketList[_tokenId] = NftItem(_tokenId, _token, _price, msg.sender);
        emit NftListed(_tokenId, _token, _price, msg.sender);
    }
    function unlistNft(uint256 _tokenId) public {
        //检查是否为自己的Token
        require(msg.sender == nft.ownerOf(_tokenId), "NftMarket: only owner can unlist nft");
        //检查是否已经上架
        require(marketList[_tokenId].tokenId != 0, "NftMarket: nft not listed");
        //取消授权
        nft.approve(address(0), _tokenId);
        delete marketList[_tokenId];
    }
    function buyNFT(uint256 _tokenId) public payable {
        NftItem memory item = marketList[_tokenId];
         //检查是否已经上架
        require(item.tokenId != 0, "NftMarket: nft not listed");
        //判断购买这是否为自己
        require(msg.sender != item.owner, "NftMarket: can't buy your own nft");
        //获取NFT挂单者使用的Token合约地址
        address BuyTokenAddress = item.token;
        ERC20Token Buytoken = ERC20Token(BuyTokenAddress);
        //检查是否有足够的挂单者要求的Token,如果没有则报错
        require(Buytoken.balanceOf(msg.sender) >= item.price, "NftMarket: not enough token");

        //判断msg.value是否过多
        // console.log("msg.value:",msg.value);
        // require(msg.value >= item.price, "NftMarket: You Pay too less");
        // //判断msg.value是否过少
        // require(msg.value < item.price, "NftMarket: You Pay too much");
        //下面代码应该是考虑授权等等问题，因为是自写没有调用库函数，所以先省略，但是实际上应该是这样的逻辑
        //Buytoken.approve(address(this), item.price);
        //然后先付钱
        //Buytoken.transferFrom(msg.sender, item.owner, item.price);
        //取消Token授权
        //忘记叫啥了先省略
        //转移NFT
        //nft.transferFrom(item.owner, msg.sender, item.tokenId);
        //取消授权
       // nft.approve(address(0), _tokenId);

       
        emit BuyNft(_tokenId, item.token, item.price, item.owner);
        delete marketList[_tokenId];
    }
}
