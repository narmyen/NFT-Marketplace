// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Marketplace is ReentrancyGuard {
    struct Listing {
        uint256 price;
        address seller;
    }

    mapping(address => mapping(uint256 => Listing)) public listings;

    event ItemListed(address nftAddress, uint256 tokenId, uint256 price, address seller);
    event ItemSold(address nftAddress, uint256 tokenId, address seller, address buyer);
    event ItemCanceled(address nftAddress, uint256 tokenId, address seller);

    function listItem(address nftAddress, uint256 tokenId, uint256 price) external {
        require(price > 0, "Price must be above zero");
        IERC721 nft = IERC721(nftAddress);
        require(nft.ownerOf(tokenId) == msg.sender, "Not owner");
        require(nft.getApproved(tokenId) == address(this), "Not approved for marketplace");
        
        listings[nftAddress][tokenId] = Listing(price, msg.sender);
        emit ItemListed(nftAddress, tokenId, price, msg.sender);
    }

    function buyItem(address nftAddress, uint256 tokenId) external payable nonReentrant {
        Listing memory item = listings[nftAddress][tokenId];
        require(item.price > 0, "Item not listed");
        require(msg.value >= item.price, "Insufficient payment");
        
        delete listings[nftAddress][tokenId];
        IERC721(nftAddress).safeTransferFrom(item.seller, msg.sender, tokenId);
        payable(item.seller).transfer(msg.value);
        
        emit ItemSold(nftAddress, tokenId, item.seller, msg.sender);
    }

    function cancelListing(address nftAddress, uint256 tokenId) external {
        Listing memory item = listings[nftAddress][tokenId];
        require(item.seller == msg.sender, "Not seller");
        delete listings[nftAddress][tokenId];
        emit ItemCanceled(nftAddress, tokenId, msg.sender);
    }
}