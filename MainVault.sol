// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BulletERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Vault is Ownable {
    BullToken private token;

    constructor(BullToken _token) {
        token = _token;
    }

    function deposit(uint256 amount) public {
        require(amount > 0, "Amount must be greater than 0");

        uint256 balanceBefore = token.balanceOf(address(this));
        token.transferFrom(msg.sender, address(this), amount);
        uint256 balanceAfter = token.balanceOf(address(this));

        require(balanceAfter > balanceBefore, "Token transfer failed");

        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) public onlyOwner {
        require(amount > 0, "Amount must be greater than 0");

        uint256 balanceBefore = token.balanceOf(address(this));
        token.transfer(msg.sender, amount);
        uint256 balanceAfter = token.balanceOf(address(this));

        require(balanceAfter < balanceBefore, "Token transfer failed");

        emit Withdrawal(msg.sender, amount);
    }

    function getBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function getPoolBalance() public view returns (uint256) {
        return getBalance();
    }

    function close() public onlyOwner {
        selfdestruct(payable(owner()));
    }

    event Deposit(address indexed from, uint256 amount);
    event Withdrawal(address indexed to, uint256 amount);
}
