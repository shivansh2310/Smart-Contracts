// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BullToken is ERC20 {
    constructor() ERC20("Bullet", "BULL") {
        _mint(msg.sender, 50000000 * 10 ** decimals());
    }
}
