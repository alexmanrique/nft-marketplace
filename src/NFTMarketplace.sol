// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {IERC721} from "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {ReentrancyGuard} from "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

contract NFTMarketplace is Ownable, ReentrancyGuard {
    struct Listing {
        uint256 price;
        address seller;
        address nftAddress;
        uint256 tokenId;
    }

    mapping(address => mapping(uint256 => Listing)) public listings;

    event NFTListed(address indexed seller, address indexed nftAddress, uint256 indexed tokenId, uint256 price);
    event NFTCancelled(address indexed seller, address indexed nftAddress, uint256 indexed tokenId);
    event NFTSold(
        address indexed buyer, address indexed seller, address indexed nftAddress, uint256 tokenId, uint256 price
    );

    // la cartera que deploye el smart contract sera el owner
    constructor() Ownable(msg.sender) {}

    function listNFT(address nftAddress_, uint256 tokenId_, uint256 price) external {
        require(price > 0, "Price must be greater than 0");
        address owner = IERC721(nftAddress_).ownerOf(tokenId_);
        require(owner == msg.sender, "You must be the owner of the NFT");

        Listing memory listing_ =
            Listing({price: price, seller: msg.sender, nftAddress: nftAddress_, tokenId: tokenId_});

        listings[nftAddress_][tokenId_] = listing_;

        emit NFTListed(msg.sender, nftAddress_, tokenId_, price);
    }

    function buyNFT(address nftAddress_, uint256 tokenId_) external payable nonReentrant {
        Listing memory listing_ = listings[nftAddress_][tokenId_];
        require(listing_.nftAddress != address(0), "Listing not found");
        require(listing_.price > 0, "Price must be equal to the listing price");
        require(msg.value == listing_.price, "Amount sent must be equal to the listing price");

        IERC721(nftAddress_).safeTransferFrom(listing_.seller, msg.sender, tokenId_);

        (bool success,) = listing_.seller.call{value: msg.value}("");
        require(success, "Transfer failed");
        delete listings[nftAddress_][tokenId_];
    }

    function cancelListing(address nftAddress_, uint256 tokenId_) external {
        Listing memory listing_ = listings[nftAddress_][tokenId_];
        require(listing_.seller == msg.sender, "You must be the seller of the NFT");
        delete listings[nftAddress_][tokenId_];
        emit NFTCancelled(msg.sender, nftAddress_, tokenId_);
    }
}
