// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;


interface IERC721 {
  function transferFrom(address from, address to, uint256 tokenId) external;
}
contract EnglishAuction {
//events
    event Start(uint startTime , uint endTime);
    event Bid(address indexed bidder , uint amount);
    // Auction state
    bool public started;
    bool public ended;
    uint public endTime;

    uint public highestBid;
    address public highestBidder;
    mapping(address => uint) public allBids;


    // for constructor
    address payable public immutable OWNER;
    IERC721 public immutable NFT;
    uint public immutable NFT_ID;


    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() internal view {
        require(msg.sender == OWNER, "Not the owner");
    }

    constructor(address _nft, uint _nftId) {
        OWNER = payable(msg.sender);
        NFT = IERC721(_nft);
        NFT_ID = _nftId;
    }

    function start(uint _openingBid,uint _duration) external onlyOwner {
        // Implement start logic
        require(!started && !ended , "Auction already started or ended");
        require(_openingBid >0 , "Opening bid must be greater than 0");
        require(_duration >0 , "Duration must be greater than 0");
        highestBid = _openingBid;
        endTime = block.timestamp + _duration;
        NFT.transferFrom(msg.sender, address(this), NFT_ID);
        started = true;

        emit Start(block.timestamp, endTime);
    }

    function bid() external payable {
        // 1. Check if started and not ended
        require(started && !ended , "Auction not started or ended");
        require(block.timestamp < endTime , "Auction has ended");
        // 2. Check if msg.value > highestBid
        require(msg.value > highestBid , "Bid must be higher than current highest bid");
       

        allBids[highestBidder] += highestBid;
        highestBid = msg.value;
        highestBidder = msg.sender;

        emit Bid(msg.sender, msg.value);
    }

    function withdraw() external {
        
    }

    function end() external onlyOwner {
        // TODO: Implement end logic
    }
}
