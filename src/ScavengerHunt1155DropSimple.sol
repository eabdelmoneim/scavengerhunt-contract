// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @notice By acquiring this NFT, you agree to the Honda 200 at Mid-Ohio 2023 NFT terms and conditions listed here: https://honda.Gryfyn.io/Honda2002023/nft-terms

import "@thirdweb-dev/contracts/base/ERC1155LazyMint.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract ScavengerHunt1155DropSimple is ERC1155LazyMint {

    uint256 finalPrizeTokenId;
    bool public isHuntPaused = false;

    constructor(
        string memory _name,
        string memory _symbol
    )
        ERC1155LazyMint(
            _name,
            _symbol,
            msg.sender,
            0
        )
    {}

    /**
     *
     *  @dev             Sets the token ID of the prize token that will be used to reward people who have claimed all the other tokens
     *
     *  @param _tokenId   The tokenId to be set as the final prize token
     */
    function setFinalPrizeTokenId(uint256 _tokenId) public onlyOwner {
        finalPrizeTokenId = _tokenId;
    }

    /**
     *
     *  @dev             Gets the token ID of the prize token that will be used to reward people who have claimed all the other tokens
     *
     */
    function getFinalPrizeTokenId() public view returns (uint256) {
        return finalPrizeTokenId;
    }

    /**
     *
     *  @dev             Checks if a claimer has claimed all the scavenger hunt tokens
     *
     *  @param _claimer   Caller of the claim function.
     */
    function hasClaimedAllTokens(address _claimer) public view returns (bool) {
        uint256 numWinningTokens = 0;
        for (uint256 i = 0; i < finalPrizeTokenId; i++) {
       
            if (balanceOf[_claimer][i] > 0) {
                numWinningTokens++;
            }
        }
        // if the number of winning tokens is equal to the number of winning token ids, then the claimer has all the winning tokens
        if (numWinningTokens == finalPrizeTokenId && finalPrizeTokenId > 0) {
            return true;
        }

        return false;
    }

    /**
     *
     *  @dev             Checks a request to claim NFTs against a custom condition.
     *
     *  @param _claimer   Caller of the claim function.
     *  @param _tokenId   The tokenId of the lazy minted NFT to mint.
     *  @param _quantity  The number of NFTs being claimed.
     */
    function verifyClaim(
        address _claimer,
        uint256 _tokenId,
        uint256 _quantity
    ) public view override {

        // only allow claiming if the hunt is not paused
        require(isHuntPaused == false, "The hunt is paused");

        // only allow claiming of a quantity of 1
        require(_quantity == 1, "You can only claim one token at a time");

        // only allow claiming a token id once
        require(balanceOf[_claimer][_tokenId] == 0, "User has already claimed this token");

        // if the last token is being claimed, check if the claimer has all the winning tokens
        if (_tokenId == finalPrizeTokenId) { 
            require(hasClaimedAllTokens(_claimer) == true, "You must have all the winning tokens to claim the final token"); 
        }
    }

     /** 
     * @notice Lets the owner restart the game
     */
    function startHunt() external {
        require(msg.sender == owner(), "Only owner can start the scavenger hunt");
        isHuntPaused = false;
    }

    /** 
     * @notice Lets the owner pause the game
     */
    function stopHunt() external {
        require(msg.sender == owner(), "Only owner can stop the scavenger hunt");
        isHuntPaused = true;
    }
}