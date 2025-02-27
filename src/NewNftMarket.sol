// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

// src/NFTMarket.sol
contract MyEip2612Token is ERC20, ERC20Permit, Ownable {
    constructor() ERC20("MyToken", "MTK") ERC20Permit("MyToken") Ownable(msg.sender) {
        _mint(msg.sender, 1000000 * 10**18);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}

contract MyNFT is ERC721, Ownable {
    uint256 private _tokenIdCounter;

    constructor() ERC721("MyNFT", "MNFT") Ownable(msg.sender) {
        _tokenIdCounter = 1;
    }

    function mint(address to) external onlyOwner returns (uint256) {
        uint256 tokenId = _tokenIdCounter;
        _safeMint(to, tokenId);
        _tokenIdCounter += 1;
        return tokenId;
    }
}

contract NFTMarket is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public token;
    IERC721 public nft;
    mapping(uint256 => bool) public isForSale;
    mapping(uint256 => uint256) public nftPrices;
    mapping(address => uint256) public nonces;
    bytes32 public constant WHITELIST_TYPEHASH = keccak256(
        "Whitelist(address buyer,uint256 tokenId,uint256 nonce)"
    );
    bytes32 public DOMAIN_SEPARATOR;

    event NFTListed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event NFTPurchased(address indexed buyer, uint256 indexed tokenId, uint256 price);
    event NFTUnlisted(uint256 indexed tokenId);

    constructor(address _token, address _nft) Ownable(msg.sender) {
        token = IERC20(_token);
        nft = IERC721(_nft);
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("NFTMarket")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    modifier canBuy(uint256 tokenId) {
        require(isForSale[tokenId], "NFT is not for sale");
        require(nft.ownerOf(tokenId) != msg.sender, "Cannot buy your own NFT");
        _;
    }

    function listNFT(uint256 tokenId, uint256 price) external {
        require(nft.ownerOf(tokenId) == msg.sender, "You are not the owner");
        require(price > 0, "Price must be greater than zero");
        require(
            nft.getApproved(tokenId) == address(this) || nft.isApprovedForAll(msg.sender, address(this)),
            "Market is not approved"
        );
        isForSale[tokenId] = true;
        nftPrices[tokenId] = price;
        emit NFTListed(tokenId, msg.sender, price);
    }

    function unlistNFT(uint256 tokenId) external {
        require(nft.ownerOf(tokenId) == msg.sender, "You are not the owner");
        require(isForSale[tokenId], "NFT is not listed");
        isForSale[tokenId] = false;
        delete nftPrices[tokenId];
        emit NFTUnlisted(tokenId);
    }

    function buyNFT(uint256 tokenId) external canBuy(tokenId) {
        uint256 price = nftPrices[tokenId];
        address seller = nft.ownerOf(tokenId);

        token.safeTransferFrom(msg.sender, address(this), price);
        token.safeTransfer(seller, price);
        nft.safeTransferFrom(seller, msg.sender, tokenId);

        isForSale[tokenId] = false;
        delete nftPrices[tokenId];
        emit NFTPurchased(msg.sender, tokenId, price);
    }

    // 内部函数：验证白名单签名
    function _verifyWhitelistSignature(
        address buyer,
        uint256 tokenId,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (bool) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(WHITELIST_TYPEHASH, buyer, tokenId, nonces[buyer]))
            )
        );
        address signer = ecrecover(digest, v, r, s);
        return signer == owner();
    }

    function permitBuy(
        uint256 tokenId,
        uint256 deadline,
        uint8 vPermit,
        bytes32 rPermit,
        bytes32 sPermit,
        uint8 vWhitelist,
        bytes32 rWhitelist,
        bytes32 sWhitelist
    ) external canBuy(tokenId) {
        require(block.timestamp <= deadline, "Permit has expired");

        // 验证白名单签名
        require(
            _verifyWhitelistSignature(msg.sender, tokenId, vWhitelist, rWhitelist, sWhitelist),
            "Invalid whitelist signature"
        );

        // 提前存储价格和卖家地址
        uint256 price = nftPrices[tokenId];
        address seller = nft.ownerOf(tokenId);

        // 调用 ERC20Permit 的 permit 函数
        IERC20Permit(address(token)).permit(
            msg.sender,
            address(this),
            price,
            deadline,
            vPermit,
            rPermit,
            sPermit
        );

        // 执行购买
        token.safeTransferFrom(msg.sender, address(this), price);
        token.safeTransfer(seller, price);
        nft.safeTransferFrom(seller, msg.sender, tokenId);

        isForSale[tokenId] = false;
        delete nftPrices[tokenId];
        nonces[msg.sender]++;
        emit NFTPurchased(msg.sender, tokenId, price);
    }

    function setToken(address _token) external onlyOwner {
        require(_token != address(0), "Invalid token address");
        token = IERC20(_token);
    }

    function setNFT(address _nft) external onlyOwner {
        require(_nft != address(0), "Invalid NFT address");
        nft = IERC721(_nft);
    }

    function withdrawTokens(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        require(token.balanceOf(address(this)) >= amount, "Insufficient balance");
        token.safeTransfer(msg.sender, amount);
    }
}