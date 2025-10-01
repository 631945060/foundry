// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "forge-std/Test.sol";
import "../src/Marketplace.sol"; // Adjust the path to your NFTMarket contract
import "../src/ERC721.sol"; // Adjust the path to your MyNFT contract
import "../src/ERC20.sol"; // Adjust the path to your MoonToken contract
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract NFTMarketTest is Test, IERC721Receiver {
    NFTMarket market;
    MyNFT myNFT;
    MoonToken moonToken;
    address user1 = address(0x1);
    address user2 = address(0x2);

    function setUp() public {
        //创建代币合约
        moonToken = new MoonToken();
        //创建市场合约
        market = new NFTMarket(address(moonToken));
        //创建nft合约
        myNFT = new MyNFT(address(market)); // Now market has a valid address
        //用户1初始化代币余额
        moonToken.transfer(user1, 1000 * 10 ** 18); // Provide user1 some tokens for testing
    }

    function testListAndBuyNFT() public {
        // Mint an NFT to list
        string memory tokenURI = "https://example.com/nft";
        uint256 newItemId = myNFT.mintNFT(tokenURI, 5);
        //nft授权给market合约
        //市场合约可以代表用户出售nft
        myNFT.approve(address(market), newItemId);

        //市场合约上架nft
        uint256 price = 100 * 10 ** 18;
        uint256 royaltyAmount = (price * 5) / 100;
        uint256 marketPlaceFee = (price * 25) / 1000;
        market.listNFTs(address(myNFT), newItemId, price);

        //用户1购买nft
        vm.startPrank(user1);
        //用户1授权市场合约购买nft
        uint256 totalAmount = price + royaltyAmount + marketPlaceFee;
        moonToken.approve(address(market), totalAmount);
        market.buyNFT(newItemId);
        vm.stopPrank();
        
        // Calculate expected balances
        uint256 intialBalance = 1000 * 10 ** 18;
        //用户1的代币余额应该减少
        uint256 expectedBalanceAfterPurchase = intialBalance - totalAmount;

        //断言：用户1应该拥有nft
        assertEq(myNFT.ownerOf(newItemId), user1, "User1 should own the NFT after purchase");
        //断言：用户1的代币余额应该减少
        assertEq(moonToken.balanceOf(user1), expectedBalanceAfterPurchase, "Incorrect balance after purchase");

        // 由于本测试中卖家/创作者/平台费接收者均为本合约地址(this)，其余额应增加 totalAmount
        uint256 expectedThisBalance = (10000 * 10 ** 18) - (1000 * 10 ** 18) + totalAmount;
        assertEq(moonToken.balanceOf(address(this)), expectedThisBalance, "Receiver balances should be increased by totalAmount");
    }

    function testBuyRevertsOnInsufficientAllowance() public {
        // Mint + list
        string memory tokenURI = "https://example.com/nft2";
        uint256 tokenId = myNFT.mintNFT(tokenURI, 5);
        myNFT.approve(address(market), tokenId);
        uint256 price = 100 * 10 ** 18;
        market.listNFTs(address(myNFT), tokenId, price);

        // Compute fees
        uint256 royaltyAmount = (price * 5) / 100;
        uint256 marketPlaceFee = (price * 25) / 1000;

        // Approve 仅价格，不包含版税与平台费，第二/三次 transferFrom 将失败
        vm.startPrank(user1);
        moonToken.approve(address(market), price);
        vm.expectRevert();
        market.buyNFT(tokenId);
        vm.stopPrank();
    }

    function testBuyRevertsWhenAlreadySold() public {
        // List and buy once
        string memory tokenURI = "https://example.com/nft3";
        uint256 tokenId = myNFT.mintNFT(tokenURI, 5);
        myNFT.approve(address(market), tokenId);
        uint256 price = 100 * 10 ** 18;
        market.listNFTs(address(myNFT), tokenId, price);
        uint256 royaltyAmount = (price * 5) / 100;
        uint256 marketPlaceFee = (price * 25) / 1000;
        uint256 totalAmount = price + royaltyAmount + marketPlaceFee;

        vm.startPrank(user1);
        moonToken.approve(address(market), totalAmount);
        market.buyNFT(tokenId);
        vm.stopPrank();

        // Second buy should revert with not for sale
        vm.startPrank(user1);
        vm.expectRevert(bytes("NFT is not up for sale"));
        market.buyNFT(tokenId);
        vm.stopPrank();
    }

    function testBuyRevertsOnInsufficientBalance() public {
        // user2 没有代币余额，直接尝试购买应因余额不足而 revert
        string memory tokenURI = "https://example.com/nft4";
        uint256 tokenId = myNFT.mintNFT(tokenURI, 5);
        myNFT.approve(address(market), tokenId);
        uint256 price = 100 * 10 ** 18;
        market.listNFTs(address(myNFT), tokenId, price);

        vm.startPrank(user2);
        vm.expectRevert(bytes("Account balance is less than the price of the NFT"));
        market.buyNFT(tokenId);
        vm.stopPrank();
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
