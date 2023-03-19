// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTInsurance is Ownable {
    struct Insurance {
        uint256 premium;
        uint256 expirationTime;
    }

    mapping(address => mapping(uint256 => Insurance)) private insurances;

    IERC20 public token;
    uint256 public premiumAmount;
    uint256 public insuranceDuration;

    constructor(IERC20 _token, uint256 _premiumAmount, uint256 _insuranceDuration) {
        token = _token;
        premiumAmount = _premiumAmount;
        insuranceDuration = _insuranceDuration;
    }

    function insureNFT(address nftContract, uint256 tokenId) external {
        require(insurances[nftContract][tokenId].expirationTime < block.timestamp, "NFTInsurance: NFT already insured");
        require(IERC721(nftContract).ownerOf(tokenId) == msg.sender, "NFTInsurance: Not the owner of the NFT");
        
        // Calculate the expiration time of the insurance
        uint256 expirationTime = block.timestamp + insuranceDuration;

        // Transfer the premium from the user to the contract
        token.transferFrom(msg.sender, address(this), premiumAmount);

        // Store the insurance details
        insurances[nftContract][tokenId] = Insurance(premiumAmount, expirationTime);
    }

    function checkInsurance(address nftContract, uint256 tokenId) external view returns (bool) {
        return insurances[nftContract][tokenId].expirationTime >= block.timestamp;
    }

    function withdrawPremiums() external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "NFTInsurance: No premiums to withdraw");

        token.transfer(owner(), balance);
    }
}
