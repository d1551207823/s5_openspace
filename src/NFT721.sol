// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


//随便写个简单的ERC721合约
contract BaseERC721  {
    // 构造函数，传入NFT名称和符号
    string public _name;
    string public _symbol;
    mapping(uint256 => address) private _owners; // TokenID => 所有者地址
    mapping(address => uint256) private _balances; // 所有者地址 => NFT数量
    constructor(string memory name,string memory symbol) {
        _name = name;
        _symbol = symbol;
    }
    event Mint(address indexed to, uint256 indexed tokenId);
    event TransferFrom (address indexed from, address indexed to, uint256 indexed tokenId);
    // mint函数：铸造新NFT
    function mint(address to,uint TokenID) public  {
        // 检查TokenID是否已经存在
        require(_owners[TokenID] == address(0), "TokenID already exists");
        // 设置TokenID的所有者为to
        _owners[TokenID] = to;
        // 增加to的NFT数量
        _balances[to] += 1;
    }
    // 设置批准者：允许某个地址管理当前拥有的NFT
    function approve(address to, uint256 tokenId) public  {
        // 检查调用者是否为Token的所有者
        require(_owners[tokenId] == msg.sender, "ERC721: approve caller is not owner");
        // 设置TokenID的批准者
        _owners[tokenId] = to;
    }
    // 查询所有者地址的NFT数量
    function balanceOf(address owner) public view  returns (uint256) {
        return _balances[owner];
       
    }
    // 查询特定Token的所有者地址
    function ownerOf(uint256 tokenId) public view  returns (address) {
        return _owners[tokenId];
    }
    
    function transferFrom(address from, address to, uint256 tokenId) public  {
        // 检查调用者是否为Token的所有者或者批准者
        require(_owners[tokenId] == msg.sender || _owners[tokenId] == from, "ERC721: transfer caller is not owner nor approved");
        // 检查Token的所有者是否为from
        require(_owners[tokenId] == from, "ERC721: transfer caller is not owner");
        // 设置TokenID的所有者为to
        _owners[tokenId] = to;
        // 增加to的NFT数量
        _balances[to] += 1;
        // 减少from的NFT数量
        _balances[from] -= 1;
    }
}