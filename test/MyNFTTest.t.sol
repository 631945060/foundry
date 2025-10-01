// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "forge-std/Test.sol";
import "../src/ERC721.sol"; // Adjust the path to your MyNFT contract
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract MyNFTTest is Test, IERC721Receiver {
    MyNFT myNFT;
    address marketPlaceAddress = address(0x1);

    function setUp() public {
        myNFT = new MyNFT(marketPlaceAddress);
    }

    function testMintNFT() public {
        string memory tokenURI = "https://example.com/nft";
        uint256 newItemId = myNFT.mintNFT(tokenURI, 5);
        assertEq(myNFT.ownerOf(newItemId), address(this), "Minter should be the owner of the new NFT");
        (uint256 royalty, address creator) = myNFT.royaltyInfo(newItemId);
        assertEq(royalty, 5, "Royalty should be correctly set");
        assertEq(creator, address(this), "Creator should be correctly set");
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}