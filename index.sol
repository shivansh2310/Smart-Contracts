// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract IndexToken is Ownable {
    using SafeERC20 for IERC20;

    // Array of underlying tokens
    IERC20[] private underlyingTokens;

    // Weights for each underlying token (sum of weights = 100)
    uint256[] private weights;

    // Mapping of underlying token address to its Chainlink aggregator
    mapping(address => AggregatorV3Interface) private aggregators;

    // Address of the index token
    string public name;
    string public symbol;

    // Rebalance period (in seconds)
    uint256 public rebalancePeriod;

    // Last rebalance timestamp
    uint256 public lastRebalance;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _rebalancePeriod,
        address[] memory _underlyingTokens,
        uint256[] memory _weights,
        address[] memory _aggregators
    ) {
        require(
            _underlyingTokens.length == _weights.length &&
                _underlyingTokens.length == _aggregators.length,
            "IndexToken: Invalid arguments"
        );

        name = _name;
        symbol = _symbol;
        rebalancePeriod = _rebalancePeriod;
        lastRebalance = block.timestamp;

        for (uint256 i = 0; i < _underlyingTokens.length; i++) {
            underlyingTokens.push(IERC20(_underlyingTokens[i]));
            weights.push(_weights[i]);

            aggregators[_underlyingTokens[i]] = AggregatorV3Interface(
                _aggregators[i]
            );
        }
    }

    // Returns the current price of an underlying token in USD (with 18 decimal places)
    function getPrice(address underlyingToken)
        public
        view
        returns (uint256)
    {
        AggregatorV3Interface aggregator = aggregators[underlyingToken];
        (, int256 price, , , ) = aggregator.latestRoundData();
        return uint256(price);
    }

    // Returns the value of a user's holdings in USD (with 18 decimal places)
    function getHoldingsValue(address user) public view returns (uint256) {
        uint256 totalValue = 0;
        for (uint256 i = 0; i < underlyingTokens.length; i++) {
            uint256 balance = underlyingTokens[i].balanceOf(user);
            uint256 price = getPrice(address(underlyingTokens[i]));
            uint256 value = (balance * price * weights[i]) / 1e18;
            totalValue += value;
        }
        return totalValue;
    }

    // Rebalances the index token by adjusting holdings of underlying tokens
    function rebalance() public onlyOwner {
        require(
            block.timestamp - lastRebalance >= rebalancePeriod,
            "IndexToken: Rebalance period not elapsed"
        );

        uint256 totalValue = getHoldingsValue(address(this));
        uint256[] memory newBalances = new uint256[](underlyingTokens.length);

        for (uint256 i = 0; i < underlyingTokens.length; i++) {
            uint256 targetValue = (totalValue * weights[i]) / 100;
	    uint256 currentBalance = underlyingTokens[i].balanceOf(address(this));
	    uint256 currentPrice = getPrice(address(underlyingTokens[i]));
	    uint256 targetBalance = (targetValue * 1e18) / currentPrice;

        if (currentBalance < targetBalance) {
            // Need to buy more tokens
            uint256 amountToBuy = targetBalance - currentBalance;
            underlyingTokens[i].safeTransferFrom(
                msg.sender,
                address(this),
                amountToBuy
            );
        } else if (currentBalance > targetBalance) {
            // Need to sell some tokens
            uint256 amountToSell = currentBalance - targetBalance;
            underlyingTokens[i].safeTransfer(msg.sender, amountToSell);
        }

        newBalances[i] = underlyingTokens[i].balanceOf(address(this));
    }

    // Update the weights based on new balances
    uint256 totalNewValue = getHoldingsValue(address(this));
    for (uint256 i = 0; i < underlyingTokens.length; i++) {
        uint256 newValue = (newBalances[i] * getPrice(address(underlyingTokens[i])) * 1e18) / totalNewValue;
        weights[i] = newValue;
    }

    lastRebalance = block.timestamp;
}

// Transfers index tokens to another address
function transfer(address recipient, uint256 amount)
    public
    returns (bool)
{
    require(
        amount <= getHoldingsValue(msg.sender),
        "IndexToken: Insufficient funds"
    );
    _transfer(msg.sender, recipient, amount);
    return true;
}

// Transfers index tokens from one address to another
function transferFrom(
    address sender,
    address recipient,
    uint256 amount
) public returns (bool) {
    require(
        amount <= getHoldingsValue(sender),
        "IndexToken: Insufficient funds"
    );
    _transfer(sender, recipient, amount);
    _approve(
        sender,
        msg.sender,
        IERC20(address(this)).allowance(sender, msg.sender) - amount
    );
    return true;
}

// Internal function to transfer tokens
function _transfer(
    address sender,
    address recipient,
    uint256 amount
) internal {
    uint256 senderBalance = getHoldingsValue(sender);
    require(
        senderBalance >= amount,
        "IndexToken: Transfer amount exceeds balance"
    );

    uint256 fee = (amount * 10) / 1000; // 0.1% fee
    underlyingTokens[0].safeTransferFrom(sender, owner(), fee);
    underlyingTokens[0].safeTransferFrom(sender, recipient, amount - fee);
}

// Approves an address to spend index tokens on behalf of the caller
function approve(address spender, uint256 amount) public returns (bool) {
    _approve(msg.sender, spender, amount);
    return true;
}

// Internal function to approve an address to spend tokens
function _approve(
    address owner,
    address spender,
    uint256 amount
) internal {
    require(
        owner != address(0),
        "IndexToken: Approve from the zero address"
    );
    require(
        spender != address(0),
        "IndexToken: Approve to the zero address"
    );

    IERC20(address(this)).approve(spender, amount);
}
 }
