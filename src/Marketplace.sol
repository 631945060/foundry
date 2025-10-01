//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/InterfaceRoyalty.sol";


contract NFTMarket is ReentrancyGuard, ERC721Holder{
    uint256 private _itemsIds;
    IERC20 public tokenAddress; 
    uint256 public platformFee = 25;

    address payable owner; 
    
    constructor(address _tokenAddress) {
        owner = payable(msg.sender);
        tokenAddress = IERC20(_tokenAddress);
    }

    struct NFTMarketItem{
        uint256 tokenId;
        uint256 price;
        address nftContract;
        address payable owner;
        address payable seller;
        bool sold;
    }

    mapping(uint256 => NFTMarketItem) public marketItems;

    event MarketItemCreated(
        uint256 indexed tokenId,
        uint256 price,
        uint256 royalty,
        address creator,
        address indexed nftContract,
        address owner,
        address seller, 
        bool sold  
    );


    function listNFTs(address nftContract, uint256 tokenId, uint256 price) external nonReentrant {
        require(price > 0, "Price must be atleast 1 Wei");
        
        _itemsIds++;
        uint256 itemId = _itemsIds;

        marketItems[itemId] = NFTMarketItem(
            tokenId,
            price,
            nftContract,
            payable(address(0)),
            payable(msg.sender),  
            false
        );

        NFTMarketItem memory nftMarketItem = marketItems[tokenId];

        (uint256 royaltyFee, address creator) = getRoyalty(nftMarketItem.nftContract, tokenId);

        IERC721(nftContract).safeTransferFrom(msg.sender, address(this), tokenId);

        emit MarketItemCreated( 
            tokenId,
            price,
            royaltyFee,
            creator,
            nftContract, 
            address(0),
            msg.sender,
            false
            );
    }

    /// @notice 购买上架的 NFT
    /// @dev 买家需提前授权本合约可划转足够的 ERC20 代币；本实现会向卖家支付全额价格，另外再分别向创作者与平台支付版税与平台费（即买家总支出=价格+版税+平台费）
    /// @param tokenId 被购买的 NFT 的 tokenId（也是本合约中用于索引的键）
    function buyNFT(uint256 tokenId) external nonReentrant {
        // 读取挂牌信息
        NFTMarketItem memory nftMarketItem = marketItems[tokenId];
        // 查询版税比例与创作者地址（单位：百分比，例如 5 表示 5%）
        (uint256 royaltyFee, address creator) = getRoyalty(nftMarketItem.nftContract, tokenId);

        // 校验：必须仍在售卖，且买家 ERC20 余额足够
        require(nftMarketItem.sold == false, "NFT is not up for sale");
        require(tokenAddress.balanceOf(msg.sender) >= nftMarketItem.price, "Account balance is less than the price of the NFT");

        // 基础价格与费用计算
        uint256 price = nftMarketItem.price;
        // 版税 = 价格 * 版税百分比 / 100
        uint256 royaltyAmount = (price * royaltyFee) / 100;
        // 平台费 = 价格 * 平台费千分比 / 1000（platformFee 以千分比计）
        uint256 marketPlaceFee = (price * platformFee) / 1000;

        // 先将商品价格全额转给卖家（需要买家对本合约 approve 足额代币）
        tokenAddress.transferFrom(msg.sender, nftMarketItem.seller, price);

        // 然后按需分别转出版税与平台费（注意：这会让买家支付价格+版税+平台费）
        if (royaltyAmount > 0) {
            tokenAddress.transferFrom(msg.sender, creator, royaltyAmount);
        }
        if (marketPlaceFee > 0) {
            tokenAddress.transferFrom(msg.sender, owner, marketPlaceFee);
        }

        // 更新订单持有人与状态
        marketItems[tokenId].owner = payable(msg.sender);
        marketItems[tokenId].sold = true;

        // 将 NFT 从市场合约转给买家
        IERC721(marketItems[tokenId].nftContract).safeTransferFrom(address(this), msg.sender, tokenId);
    }


    function getRoyalty(address nftContractAddress, uint256 _tokenId) internal view returns (uint256 _royalty, address _creator) {
            return InterfaceGetRoyalty(nftContractAddress).royaltyInfo(_tokenId);     
    }
}