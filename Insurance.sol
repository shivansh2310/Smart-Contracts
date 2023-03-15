// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Insurance is Ownable {
    using SafeMath for uint256;

    uint256 public constant MAX_INSUREES = 100;

    struct Policy {
        address insuree;
        uint256 premium;
        uint256 payout;
        bool active;
    }

    Policy[] public policies;

    mapping(address => uint256) public premiums;
    mapping(address => uint256) public payouts;

    uint256 public totalPremiums;
    uint256 public totalPayouts;

    event PolicyCreated(address indexed insuree, uint256 premium, uint256 payout);
    event PolicyCanceled(address indexed insuree);
    event PolicyExpired(address indexed insuree);

    function createPolicy(uint256 payout) public payable {
        require(policies.length < MAX_INSUREES, "Insurance: Maximum number of insurees reached");
        require(msg.value > 0, "Insurance: Premium must be greater than zero");
        require(payout > 0, "Insurance: Payout must be greater than zero");

        policies.push(Policy({
            insuree: msg.sender,
            premium: msg.value,
            payout: payout,
            active: true
        }));

        premiums[msg.sender] = premiums[msg.sender].add(msg.value);
        payouts[msg.sender] = payouts[msg.sender].add(payout);
        totalPremiums = totalPremiums.add(msg.value);
        totalPayouts = totalPayouts.add(payout);

        emit PolicyCreated(msg.sender, msg.value, payout);
    }

    function cancelPolicy() public {
        for (uint256 i = 0; i < policies.length; i++) {
            if (policies[i].insuree == msg.sender && policies[i].active) {
                policies[i].active = false;

                premiums[msg.sender] = premiums[msg.sender].sub(policies[i].premium);
                payouts[msg.sender] = payouts[msg.sender].sub(policies[i].payout);
                totalPremiums = totalPremiums.sub(policies[i].premium);
                totalPayouts = totalPayouts.sub(policies[i].payout);

                payable(msg.sender).transfer(policies[i].premium);

                emit PolicyCanceled(msg.sender);

                return;
            }
        }

        revert("Insurance: No active policy found");
    }

    function expirePolicy(uint256 index) public onlyOwner {
        require(index < policies.length, "Insurance: Invalid policy index");

        Policy storage policy = policies[index];

        require(policy.active, "Insurance: Policy is already expired");

        policy.active = false;

        premiums[policy.insuree] = premiums[policy.insuree].sub(policy.premium);
        payouts[policy.insuree] = payouts[policy.insuree].sub(policy.payout);
        totalPremiums = totalPremiums.sub(policy.premium);
        totalPayouts = totalPayouts.sub(policy.payout);

        payable(policy.insuree).transfer(policy.premium);

        emit PolicyExpired(policy.insuree);
    }

    function withdrawPremium() public {
        uint256 premium = premiums[msg.sender];
        require(premium > 0, "Insurance: No premiums to withdraw");

        premiums[msg.sender] = 0;

        payable(msg.sender).transfer(premium);
    }

    function withdrawPayout() public {
        uint256 payout = payouts[msg.sender];
        require(payout > 0, "Insurance: No payouts to withdraw");

        payouts[msg.sender] = 0;

        payable(msg.sender).transfer(payout);
    }

}
