// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PlebToken is ERC20, ERC20Burnable, Ownable {
    uint256 private constant TOTAL_SUPPLY = 130e12 * 1e18;

    constructor() ERC20("PlebToken", "PLEB") {
        _mint(msg.sender, TOTAL_SUPPLY);
    }

    function burnTokens(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}
