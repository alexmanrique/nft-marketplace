// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "../lib/forge-std/src/Test.sol";
import {ERC721} from "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {NFTMarketplace} from "../src/NFTMarketplace.sol";

contract NFTMock is ERC721 {
    constructor() ERC721("NFTMock", "NFT") {}

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }
}

contract NFTMarketplaceTest is Test {
    NFTMarketplace nftMarketplace;
    address deployer = vm.addr(1);
    address user = vm.addr(2);
    NFTMock nft;
    uint256 tokenId = 0;
    uint256 feePercentage = 2;

    function setUp() public {
        vm.startPrank(deployer);
        nftMarketplace = new NFTMarketplace(feePercentage);
        nft = new NFTMock();
        vm.startPrank(user);
        nft.mint(user, tokenId);
        vm.stopPrank();
    }

    function testNFT() public {
        address owner = nft.ownerOf(tokenId);
        assertEq(owner, user);
    }

    function testShouldRevertIfPriceIsZero() public {
        vm.startPrank(user);
        vm.expectRevert("Price must be greater than 0");
        nftMarketplace.listNFT(address(nft), tokenId, 0);
        vm.stopPrank();
    }

    function testShouldRevertIfNotOwner() public {
        vm.startPrank(user);

        address user2_ = vm.addr(3);
        uint256 tokenId_ = 1;
        nft.mint(user2_, tokenId_);

        vm.expectRevert("You must be the owner of the NFT");
        nftMarketplace.listNFT(address(nft), tokenId_, 1);
        vm.stopPrank();
    }

    function testListNFTCorrectly() public {
        vm.startPrank(user);

        (, address sellerBefore,,) = nftMarketplace.listings(address(nft), tokenId);
        nftMarketplace.listNFT(address(nft), tokenId, 1);
        (, address sellerAfter,,) = nftMarketplace.listings(address(nft), tokenId);

        assertEq(sellerBefore, address(0));
        assertEq(sellerAfter, user);

        vm.stopPrank();
    }

    function testShouldRevertIfYouAreNotTheOwnerWhenCancelling() public {
        vm.startPrank(user);

        (, address sellerBefore,,) = nftMarketplace.listings(address(nft), tokenId);
        nftMarketplace.listNFT(address(nft), tokenId, 1);
        (, address sellerAfter,,) = nftMarketplace.listings(address(nft), tokenId);

        assertEq(sellerBefore, address(0));
        assertEq(sellerAfter, user);

        vm.stopPrank();

        address user2_ = vm.addr(3);
        vm.startPrank(user2_);
        vm.expectRevert("You must be the seller of the NFT");
        nftMarketplace.cancelListing(address(nft), tokenId);
        vm.stopPrank();
    }

    function testCancelListShouldWorkCorrectly() public {
        vm.startPrank(user);

        (, address sellerBefore,,) = nftMarketplace.listings(address(nft), tokenId);
        nftMarketplace.listNFT(address(nft), tokenId, 1);
        (, address sellerAfter,,) = nftMarketplace.listings(address(nft), tokenId);

        assertEq(sellerBefore, address(0));
        assertEq(sellerAfter, user);

        nftMarketplace.cancelListing(address(nft), tokenId);
        (, address sellerAfter2,,) = nftMarketplace.listings(address(nft), tokenId);

        assertEq(sellerAfter2, address(0));

        vm.stopPrank();
    }

    function testCannotBuyUnlistedNFT() public {
        vm.startPrank(user);
        vm.expectRevert("Listing not found");
        nftMarketplace.buyNFT(address(nft), tokenId);
        vm.stopPrank();
    }

    function testCannotBuyNFTWithIncorrectPrice() public {
        vm.startPrank(user);
        uint256 price = 3;
        (, address sellerBefore,,) = nftMarketplace.listings(address(nft), tokenId);
        nftMarketplace.listNFT(address(nft), tokenId, price);
        (, address sellerAfter,,) = nftMarketplace.listings(address(nft), tokenId);

        assertEq(sellerBefore, address(0));
        assertEq(sellerAfter, user);

        vm.stopPrank();

        address user2_ = vm.addr(3);
        vm.startPrank(user2_);
        vm.deal(user2_, price);
        vm.expectRevert("Amount sent must be equal to the listing price");
        nftMarketplace.buyNFT{value: price - 1}(address(nft), tokenId);
        vm.stopPrank();
    }

    function testShouldBuyNFTCorrectly() public {
        vm.startPrank(user);
        uint256 price = 3;

        (, address sellerBefore,,) = nftMarketplace.listings(address(nft), tokenId);
        nftMarketplace.listNFT(address(nft), tokenId, price);
        (, address sellerAfter,,) = nftMarketplace.listings(address(nft), tokenId);

        assertEq(sellerBefore, address(0));
        assertEq(sellerAfter, user);

        nft.approve(address(nftMarketplace), tokenId);
        vm.stopPrank();

        address user2_ = vm.addr(3);
        vm.startPrank(user2_);
        vm.deal(user2_, price);

        uint256 balanceBefore = address(user2_).balance;
        uint256 balanceBefore2 = address(user).balance;

        address ownerBefore = nft.ownerOf(tokenId);
        (, address sellerBefore2,,) = nftMarketplace.listings(address(nft), tokenId);

        nftMarketplace.buyNFT{value: price}(address(nft), tokenId);
        (, address sellerAfter2,,) = nftMarketplace.listings(address(nft), tokenId);

        uint256 balanceAfter = address(user2_).balance;
        uint256 balanceAfter2 = address(user).balance;

        uint256 fee = nftMarketplace.calculateFee(price);

        assertEq(balanceBefore - price - fee, balanceAfter);
        assertEq(balanceBefore2 + price - fee, balanceAfter2);

        uint256 balanceAfter3 = address(nftMarketplace.owner()).balance;
        assertEq(balanceAfter3, fee);

        address ownerAfter = nft.ownerOf(tokenId);

        assertEq(ownerBefore, user);
        assertEq(ownerAfter, user2_);

        assertEq(sellerBefore2, user);
        assertEq(sellerAfter2, address(0));

        vm.stopPrank();
    }
}

