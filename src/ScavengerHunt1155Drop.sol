// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@thirdweb-dev/contracts/base/ERC1155LazyMint.sol";

contract ScavengerHunt1155Drop is ERC1155LazyMint {

    uint256[] winningTokenIds;
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

    function addWinningTokenId(uint256 _tokenId) public onlyOwner {
        winningTokenIds.push(_tokenId);
    }

    function hasWinningTokenIds(address _claimer) public view returns (bool) {
        uint256 numWinningTokens = 0;
        for (uint256 i = 0; i < winningTokenIds.length; i++) {
       
            if (balanceOf[_claimer][winningTokenIds[i]] > 0) {
                numWinningTokens++;
            }
        }
        // if the number of winning tokens is equal to the number of winning token ids, then the claimer has all the winning tokens
        if (numWinningTokens == winningTokenIds.length && winningTokenIds.length > 0) {
            return true;
        }

        return false;
    }

    function verifyClaim(
        address _claimer,
        uint256 _tokenId,
        uint256 _quantity
    ) public view override {

        // only allow claiming if the hunt is not paused
        require(isHuntPaused == false, "The hunt is paused");

        // only allow claiming a token once
        require(balanceOf[_claimer][_tokenId] == 0, "You already claimed this token");

        // only allow claiming of a quantity of 1
        require(_quantity == 1, "You can only claim one token at a time");

        // if the last token is being claimed, check if the claimer has all the winning tokens
        if (_tokenId == nextTokenIdToMint() - 1) { 
            require(hasWinningTokenIds(_claimer) == true, "You must have all the winning tokens to claim the winner token"); 
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