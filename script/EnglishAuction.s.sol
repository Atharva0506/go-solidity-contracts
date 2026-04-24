// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {EnglishAuction} from "../src/EnglishAuction.sol";
import {MyNFT} from "../src/MyNFT.sol";

/// @title EnglishAuctionScript - Deployment script for the English Auction
/// @notice Deploys the NFT and Auction contracts for local testing
contract EnglishAuctionScript is Script {
    EnglishAuction public englishAuction;
    MyNFT public nft;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // 1. Deploy the mock NFT contract
        nft = new MyNFT();
        uint256 tokenId = 1;
        console.log("MyNFT deployed at:", address(nft));

        // 2. Mint the NFT to the deployer
        nft.mint(msg.sender, tokenId);
        console.log("NFT #%d minted to:", tokenId, msg.sender);

        // 3. Deploy the English Auction contract
        englishAuction = new EnglishAuction(address(nft), tokenId);
        console.log("EnglishAuction deployed at:", address(englishAuction));

        // 4. Approve the auction contract to transfer the NFT
        nft.approve(address(englishAuction), tokenId);
        console.log("Auction approved to transfer NFT #%d", tokenId);

        vm.stopBroadcast();
    }
}
