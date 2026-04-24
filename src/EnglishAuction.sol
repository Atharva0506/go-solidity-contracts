// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title EnglishAuction - A simple English auction for a single NFT
/// @notice Allows the owner to auction off an NFT to the highest bidder
/// @dev Uses OpenZeppelin's IERC721 and ReentrancyGuard for safety
contract EnglishAuction is ReentrancyGuard {
    // ──────────────────────────────────────────────
    //                    Events
    // ──────────────────────────────────────────────

    /// @notice Emitted when the auction starts
    event Start(uint256 startTime, uint256 endTime);

    /// @notice Emitted when a new bid is placed
    event Bid(address indexed bidder, uint256 amount);

    /// @notice Emitted when the auction ends
    event End(address indexed winner, uint256 amount);

    /// @notice Emitted when a bidder withdraws their outbid funds
    event Withdraw(address indexed bidder, uint256 amount);

    // ──────────────────────────────────────────────
    //                 State Variables
    // ──────────────────────────────────────────────

    /// @notice Whether the auction has started
    bool public started;

    /// @notice Whether the auction has ended
    bool public ended;

    /// @notice The timestamp when the auction ends
    uint256 public endTime;

    /// @notice The current highest bid amount
    uint256 public highestBid;

    /// @notice The address of the current highest bidder
    address public highestBidder;

    /// @notice Mapping of bidder address to their total refundable balance
    mapping(address => uint256) public allBids;

    // ──────────────────────────────────────────────
    //              Immutable Variables
    // ──────────────────────────────────────────────

    /// @notice The owner of the auction (receives funds on completion)
    address payable public immutable OWNER;

    /// @notice The NFT contract being auctioned
    IERC721 public immutable NFT;

    /// @notice The token ID of the NFT being auctioned
    uint256 public immutable NFT_ID;

    // ──────────────────────────────────────────────
    //                   Modifiers
    // ──────────────────────────────────────────────

    /// @notice Restricts function access to the contract owner
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    /// @dev Internal function to check owner — saves bytecode when modifier is used multiple times
    function _onlyOwner() internal view {
        require(msg.sender == OWNER, "Not the owner");
    }

    // ──────────────────────────────────────────────
    //                  Constructor
    // ──────────────────────────────────────────────

    /// @notice Initializes the auction with the NFT contract and token ID
    /// @param _nft Address of the ERC721 NFT contract
    /// @param _nftId Token ID of the NFT to be auctioned
    constructor(address _nft, uint256 _nftId) {
        require(_nft != address(0), "Invalid NFT address");

        OWNER = payable(msg.sender);
        NFT = IERC721(_nft);
        NFT_ID = _nftId;
    }

    // ──────────────────────────────────────────────
    //              External Functions
    // ──────────────────────────────────────────────

    /// @notice Starts the auction with an opening bid and duration
    /// @dev The owner must approve this contract to transfer the NFT before calling
    /// @param _openingBid The minimum bid amount to start the auction
    /// @param _duration The duration of the auction in seconds
    function start(uint256 _openingBid, uint256 _duration) external onlyOwner {
        require(!started && !ended, "Auction already started or ended");
        require(_openingBid > 0, "Opening bid must be greater than 0");
        require(_duration > 0, "Duration must be greater than 0");

        // Set the opening bid and auction end time
        highestBid = _openingBid;
        endTime = block.timestamp + _duration;
        started = true;

        // Transfer the NFT from the owner to this contract (escrow)
        NFT.transferFrom(msg.sender, address(this), NFT_ID);

        emit Start(block.timestamp, endTime);
    }

    /// @notice Place a bid on the auction
    /// @dev Must send ETH greater than the current highest bid
    function bid() external payable {
        // Checks
        require(started && !ended, "Auction not active");
        require(block.timestamp < endTime, "Auction has ended");
        require(msg.value > highestBid, "Bid must be higher than current highest bid");
        require(msg.sender != OWNER, "Owner cannot bid on their own auction");

        // Effects — update state before any external calls (CEI pattern)
        // Track the previous highest bidder's refundable balance
        if (highestBidder != address(0)) {
            allBids[highestBidder] += highestBid;
        }

        // Update the new highest bid
        highestBid = msg.value;
        highestBidder = msg.sender;

        emit Bid(msg.sender, msg.value);
    }

    /// @notice Withdraw your outbid funds
    /// @dev Protected by OpenZeppelin's ReentrancyGuard
    function withdraw() external nonReentrant {
        uint256 amount = allBids[msg.sender];
        require(amount > 0, "Nothing to withdraw");

        // Effects — zero out balance BEFORE sending (prevents reentrancy)
        allBids[msg.sender] = 0;

        // Interactions — send funds using call (safer than transfer)
        (bool success,) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdraw failed");

        emit Withdraw(msg.sender, amount);
    }

    /// @notice End the auction and distribute the NFT and funds
    /// @dev Only callable by the owner after the auction duration has passed
    function end() external onlyOwner nonReentrant {
        // Checks
        require(started && !ended, "Auction not started or already ended");
        require(block.timestamp >= endTime, "Auction has not ended yet");

        // Effects — mark ended before external calls (CEI pattern)
        ended = true;

        // Interactions — transfer NFT and funds
        if (highestBidder != address(0)) {
            // Someone placed a bid — send NFT to winner, funds to owner
            NFT.transferFrom(address(this), highestBidder, NFT_ID);
            (bool success,) = OWNER.call{value: highestBid}("");
            require(success, "Transfer to owner failed");
        } else {
            // No bids were placed — return the NFT to the owner
            NFT.transferFrom(address(this), OWNER, NFT_ID);
        }

        emit End(highestBidder, highestBid);
    }
}
