// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract IndexToken is ERC20, Ownable {

    struct TokenData {
        address tokenAddress;
        uint256 weight;
        uint8 decimals;
        AggregatorV3Interface priceFeed;
    }

    TokenData[] public tokenDataList;

    constructor() ERC20("Index Token", "INDX") {}

    function addToken(
        address _tokenAddress,
        uint256 _weight,
        address _priceFeedAddress
    ) external onlyOwner {
        require(_weight > 0, "Weight must be greater than 0");

        AggregatorV3Interface _priceFeed = AggregatorV3Interface(_priceFeedAddress);
        uint8 _decimals = _priceFeed.decimals();

        tokenDataList.push(
            TokenData({
                tokenAddress: _tokenAddress,
                weight: _weight,
                decimals: _decimals,
                priceFeed: _priceFeed
            })
        );
    }

    function removeToken(uint256 _index) external onlyOwner {
        require(_index < tokenDataList.length, "Invalid index");
        tokenDataList[_index] = tokenDataList[tokenDataList.length - 1];
        tokenDataList.pop();
    }

    function rebalance() external onlyOwner {
        uint256 totalWeightedPrice = 0;
        uint256 totalWeight = 0;

        for (uint256 i = 0; i < tokenDataList.length; i++) {
            TokenData storage tokenData = tokenDataList[i];
            uint256 price = uint256(getPrice(tokenData.priceFeed));
            uint256 weightedPrice = price * (10**18) / (10**tokenData.decimals) * tokenData.weight;
            totalWeightedPrice += weightedPrice;
            totalWeight += tokenData.weight;
        }

        uint256 indexTokenSupply = totalSupply();
        uint256 targetIndexTokenSupply = totalWeightedPrice * indexTokenSupply / totalWeight;
        uint256 amountToMint = targetIndexTokenSupply - indexTokenSupply;
        _mint(msg.sender, amountToMint);
    }

    function getPrice(AggregatorV3Interface _priceFeed) internal view returns (int256) {
        (,int256 price,,,) = _priceFeed.latestRoundData();
        return price;
    }
}
