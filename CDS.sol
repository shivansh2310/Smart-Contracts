// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CreditDefaultSwap {
    address public buyer;
    address public seller;
    uint public notional;
    uint public premium;
    uint public threshold;
    bool public defaulted;
    bool public settled;
    
    constructor(address _buyer, address _seller, uint _notional, uint _premium, uint _threshold) {
        buyer = _buyer;
        seller = _seller;
        notional = _notional;
        premium = _premium;
        threshold = _threshold;
    }
    
    function makePayment() public payable {
        require(msg.sender == buyer, "Only the buyer can make a payment.");
        require(msg.value == premium, "Payment must be equal to the premium.");
        payable(seller).transfer(msg.value);
    }
    
    function triggerDefault() public {
        require(msg.sender == buyer, "Only the buyer can trigger default.");
        require(!defaulted, "Default has already been triggered.");
        defaulted = true;
    }
    
    function settle() public {
        require(msg.sender == buyer, "Only the buyer can settle the CDS.");
        require(defaulted, "Cannot settle until default has been triggered.");
        require(!settled, "Settlement has already occurred.");
        
        if(address(this).balance > notional) {
            payable(buyer).transfer(address(this).balance - notional);
        } else {
            payable(seller).transfer(notional - address(this).balance);
        }
        
        settled = true;
    }
    
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}
