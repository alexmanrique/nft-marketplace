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

    function setUp() public {
        vm.startPrank(deployer);
        nftMarketplace = new NFTMarketplace();
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
      
      (,address sellerBefore,,) = nftMarketplace.listings(address(nft), tokenId);
      nftMarketplace.listNFT(address(nft), tokenId, 1);
      (,address sellerAfter,,) = nftMarketplace.listings(address(nft), tokenId);
      
      assertEq(sellerBefore, address(0));
      assertEq(sellerAfter, user);
      
      vm.stopPrank();
    }


}

