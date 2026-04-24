// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {EnglishAuction} from "../src/EnglishAuction.sol";
import {MyNFT} from "../src/MyNFT.sol";

/// @title TestEnglishAuction - Unit tests for the English Auction contract
contract TestEnglishAuction is Test {
    EnglishAuction public auction;
    MyNFT public nft;

    // Test addresses
    address public owner = makeAddr("owner");
    address public bidder1 = makeAddr("bidder1");
    address public bidder2 = makeAddr("bidder2");

    // Test constants
    uint256 public constant TOKEN_ID = 1;
    uint256 public constant OPENING_BID = 1 ether;
    uint256 public constant DURATION = 1 days;

    /// @notice Set up the test environment before each test
    function setUp() public {
        // Deploy contracts as the owner
        vm.startPrank(owner);

        nft = new MyNFT();
        nft.mint(owner, TOKEN_ID);

        auction = new EnglishAuction(address(nft), TOKEN_ID);
        nft.approve(address(auction), TOKEN_ID);

        vm.stopPrank();

        // Fund the bidders with ETH for testing
        vm.deal(bidder1, 10 ether);
        vm.deal(bidder2, 10 ether);
    }

    // ──────────────────────────────────────────────
    //              Constructor Tests
    // ──────────────────────────────────────────────

    function test_ConstructorSetsOwner() public view {
        assertEq(auction.OWNER(), owner);
    }

    function test_ConstructorSetsNFT() public view {
        assertEq(address(auction.NFT()), address(nft));
    }

    function test_ConstructorSetsNftId() public view {
        assertEq(auction.NFT_ID(), TOKEN_ID);
    }

    // ──────────────────────────────────────────────
    //                Start Tests
    // ──────────────────────────────────────────────

    function test_StartAuction() public {
        vm.prank(owner);
        auction.start(OPENING_BID, DURATION);

        assertTrue(auction.started());
        assertEq(auction.highestBid(), OPENING_BID);
        assertEq(nft.ownerOf(TOKEN_ID), address(auction));
    }

    function test_RevertStartIfNotOwner() public {
        vm.expectRevert("Not the owner");
        vm.prank(bidder1);
        auction.start(OPENING_BID, DURATION);
    }

    function test_RevertStartIfAlreadyStarted() public {
        vm.startPrank(owner);
        auction.start(OPENING_BID, DURATION);

        vm.expectRevert("Auction already started or ended");
        auction.start(OPENING_BID, DURATION);
        vm.stopPrank();
    }

    // ──────────────────────────────────────────────
    //                  Bid Tests
    // ──────────────────────────────────────────────

    function test_Bid() public {
        // Start the auction
        vm.prank(owner);
        auction.start(OPENING_BID, DURATION);

        // Place a bid
        vm.prank(bidder1);
        auction.bid{value: 2 ether}();

        assertEq(auction.highestBid(), 2 ether);
        assertEq(auction.highestBidder(), bidder1);
    }

    function test_RevertBidIfNotStarted() public {
        vm.expectRevert("Auction not active");
        vm.prank(bidder1);
        auction.bid{value: 2 ether}();
    }

    function test_RevertBidIfTooLow() public {
        vm.prank(owner);
        auction.start(OPENING_BID, DURATION);

        vm.expectRevert("Bid must be higher than current highest bid");
        vm.prank(bidder1);
        auction.bid{value: 0.5 ether}();
    }

    function test_RevertBidIfOwner() public {
        vm.prank(owner);
        auction.start(OPENING_BID, DURATION);

        // Fund owner so the ETH transfer doesn't fail before the contract's require check
        vm.deal(owner, 10 ether);
        vm.expectRevert("Owner cannot bid on their own auction");
        vm.prank(owner);
        auction.bid{value: 2 ether}();
    }

    function test_OutbidRefundsAreSaved() public {
        vm.prank(owner);
        auction.start(OPENING_BID, DURATION);

        // Bidder1 bids first
        vm.prank(bidder1);
        auction.bid{value: 2 ether}();

        // Bidder2 outbids
        vm.prank(bidder2);
        auction.bid{value: 3 ether}();

        // Bidder1 should have a refundable balance
        assertEq(auction.allBids(bidder1), 2 ether);
    }

    // ──────────────────────────────────────────────
    //              Withdraw Tests
    // ──────────────────────────────────────────────

    function test_Withdraw() public {
        vm.prank(owner);
        auction.start(OPENING_BID, DURATION);

        // Bidder1 bids, then gets outbid
        vm.prank(bidder1);
        auction.bid{value: 2 ether}();

        vm.prank(bidder2);
        auction.bid{value: 3 ether}();

        // Bidder1 withdraws their outbid amount
        uint256 balanceBefore = bidder1.balance;
        vm.prank(bidder1);
        auction.withdraw();
        uint256 balanceAfter = bidder1.balance;

        assertEq(balanceAfter - balanceBefore, 2 ether);
        assertEq(auction.allBids(bidder1), 0);
    }

    function test_RevertWithdrawIfNothingToWithdraw() public {
        vm.expectRevert("Nothing to withdraw");
        vm.prank(bidder1);
        auction.withdraw();
    }

    // ──────────────────────────────────────────────
    //                  End Tests
    // ──────────────────────────────────────────────

    function test_EndAuction() public {
        vm.prank(owner);
        auction.start(OPENING_BID, DURATION);

        // Place a bid
        vm.prank(bidder1);
        auction.bid{value: 2 ether}();

        // Fast forward past the auction end time
        vm.warp(block.timestamp + DURATION + 1);

        // End the auction
        uint256 ownerBalanceBefore = owner.balance;
        vm.prank(owner);
        auction.end();

        // Verify: auction ended, NFT transferred to winner, funds to owner
        assertTrue(auction.ended());
        assertEq(nft.ownerOf(TOKEN_ID), bidder1);
        assertEq(owner.balance - ownerBalanceBefore, 2 ether);
    }

    function test_EndAuctionWithNoBids() public {
        vm.prank(owner);
        auction.start(OPENING_BID, DURATION);

        // Fast forward past the auction end time
        vm.warp(block.timestamp + DURATION + 1);

        // End the auction with no bids — NFT should return to owner
        vm.prank(owner);
        auction.end();

        assertTrue(auction.ended());
        assertEq(nft.ownerOf(TOKEN_ID), owner);
    }

    function test_RevertEndIfNotEnded() public {
        vm.prank(owner);
        auction.start(OPENING_BID, DURATION);

        vm.expectRevert("Auction has not ended yet");
        vm.prank(owner);
        auction.end();
    }

    function test_RevertEndIfNotOwner() public {
        vm.prank(owner);
        auction.start(OPENING_BID, DURATION);

        vm.warp(block.timestamp + DURATION + 1);

        vm.expectRevert("Not the owner");
        vm.prank(bidder1);
        auction.end();
    }
}
