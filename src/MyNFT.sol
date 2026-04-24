// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/// @title MyNFT - A simple ERC721 NFT for testing the English Auction
/// @notice Uses OpenZeppelin's ERC721 implementation for full standard compliance
contract MyNFT is ERC721 {
    /// @notice Counter for the next token ID to mint
    uint256 private _nextTokenId;

    constructor() ERC721("MyNFT", "MNFT") {}

    /// @notice Mint a new NFT to a given address
    /// @param to The address to mint the NFT to
    /// @param tokenId The token ID to mint
    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }
}
