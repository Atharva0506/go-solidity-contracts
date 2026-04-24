// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {EnglishAuction} from "../src/EnglishAuction.sol";
import {MyNFT} from "../src/MyNFT.sol";

contract EnglishAuctionScript is Script {
    EnglishAuction public englishAuction;
    MyNFT public nft;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // 1. Deploy the NFT
        nft = new MyNFT();
        uint256 tokenId = 1;
        
        // 2. Mint the NFT to the deployer so they can start the auction
        nft.mint(msg.sender, tokenId);

        // 3. Deploy the Auction with the NFT address and token ID
        englishAuction = new EnglishAuction(address(nft), tokenId);

        vm.stopBroadcast();
    }
}
