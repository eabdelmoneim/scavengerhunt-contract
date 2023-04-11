// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@thirdweb-dev/contracts/base/ERC1155LazyMint.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract ScavengerHunt1155Drop is ERC1155LazyMint {
    using EnumerableSet for EnumerableSet.AddressSet;
        
    EnumerableSet.AddressSet private swapOfferAddresses;

    uint256[] winningTokenIds;
    bool public isHuntPaused = false;

    struct SwapOffer {
        address from;
        uint256 id;
        uint256 forId;
    }

    mapping(address => SwapOffer) public offers;

    event SwapOfferCreated(address indexed from, uint256 indexed tokenId, uint256 indexed forTokenId);
    event SwapOfferCancelled(address indexed from, uint256 indexed tokenId, uint256 indexed forTokenId);
    event SwapTrade(address indexed from, address indexed to);

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

// Swap functions
    
    /**
     * @notice Creates a swap offer for a token
     */
    function createSwapOffer(address _from, uint256 _tokenId, uint256 _forTokenId) public {
        require(_from == msg.sender, "Only the owner can create an offer.");
        require(balanceOf[_from][_tokenId] >= 1, "Insufficient balance.");
        
        // require that the token id is not the last token id
        require(_forTokenId < nextTokenIdToMint()-1, "Invalid token id to swap for.");

        // require that the msg.sender doesn't already have an offer
        require(offers[msg.sender].from == address(0), "An address can only have one offer at a time.");
        
        offers[msg.sender] = SwapOffer(_from, _tokenId, _forTokenId);
        swapOfferAddresses.add(_from);

        emit SwapOfferCreated(_from, _tokenId, _forTokenId);
    }

    /**
     * @notice Cancels a swap offer for a token
     */
    function cancelSwapOffer() public {
        require(offers[msg.sender].from != address(0), "No offer to cancel.");

        uint256 id = offers[msg.sender].id;
        uint256 forId = offers[msg.sender].forId;

        delete offers[msg.sender];
        swapOfferAddresses.remove(msg.sender);

        emit SwapOfferCancelled(msg.sender, id, forId);
    }

    /**
     * @notice returns the swap offer for an address
     */    
    function getSwapOffer(address _from) public view returns (SwapOffer memory) {
        return offers[_from];
    }

    /**
    * @notice returns an array of swap offers for all addresses that have open swap offers
     */
    function getActiveSwapOffers() public view returns (SwapOffer[] memory) {
        SwapOffer[] memory offersArray = new SwapOffer[](swapOfferAddresses.length());
        for (uint256 i = 0; i < swapOfferAddresses.length(); i++) {
            offersArray[i] = offers[swapOfferAddresses.at(i)];
        }
        return offersArray;
    }

    /**
     * @notice conducts a swap between two addresses that have open swap offers
     */
    function swap(address _from, address _to) public {
        SwapOffer memory offer1 = offers[_from];
        SwapOffer memory offer2 = offers[_to];

        require(offer1.from != address(0), "No open swap offers found for address 1.");
        require(offer2.from != address(0), "No open swap offers found for address 2.");
        require(offer1.from != _to, "Can't trade with yourself.");
        require(offer1.id != offer2.id, "Can't swap the same token.");
        require(offer1.forId == offer2.id && offer2.forId == offer1.id, "Swap offers don't match.");

        require(balanceOf[_from][offer1.id] >= 1, "Insufficient balance of token for from address.");
        require(balanceOf[_to][ offer2.id] >= 1, "Insufficient balance of token for to address");

        // perform the swap
        _safeTransferFrom(_from, _to, offer1.id, 1, "");
        _safeTransferFrom(_to, _from, offer2.id, 1, "");

        // delete the offers
        delete offers[_from];
        delete offers[_to];
        swapOfferAddresses.remove(_from);
        swapOfferAddresses.remove(_to);

        emit SwapTrade(_from, _to);
    }
}