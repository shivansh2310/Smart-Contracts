// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Derivative {
    // Parties involved in the derivative
    address payable public buyer;
    address payable public seller;

    // Underlying asset and settlement terms
    address public underlying;
    uint public strikePrice;
    uint public expiration;

    // Contract state
    bool public isExercised;
    bool public isExpired;

    // Events for tracking contract state changes
    event Exercise();
    event Expire();

    // Constructor function for initializing the contract
    constructor(address _underlying, uint _strikePrice, uint _expiration, address payable _buyer, address payable _seller) {
        underlying = _underlying;
        strikePrice = _strikePrice;
        expiration = _expiration;
        buyer = _buyer;
        seller = _seller;
    }

    // Function for exercising the derivative
    function exercise() public {
        require(msg.sender == buyer, "Only the buyer can exercise the derivative");
        require(!isExpired, "The derivative has expired");

        uint underlyingPrice = getPrice(underlying);

        if (underlyingPrice > strikePrice) {
            uint payout = underlyingPrice - strikePrice;
            buyer.transfer(payout);
        }

        isExercised = true;
        emit Exercise();
    }

    // Function for expiring the derivative
    function expire() public {
        require(msg.sender == seller, "Only the seller can expire the derivative");
        require(!isExercised, "The derivative has already been exercised");
        require(block.timestamp >= expiration, "The derivative has not yet expired");

        seller.transfer(address(this).balance);
        isExpired = true;
        emit Expire();
    }

    // Internal function for getting the price of the underlying asset
    function getPrice(address asset) internal view returns (uint) {
        // For simplicity, we'll just return a fixed price of 100 wei
        return 100;
    }
}
