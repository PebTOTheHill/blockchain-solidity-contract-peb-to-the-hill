// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract PlebToken is ERC20, ERC20Burnable {
    uint256 private constant TOTAL_SUPPLY = 130e12 * 1e18;

    constructor() ERC20("PlebToken", "PLEB") {
        _mint(msg.sender, TOTAL_SUPPLY);
    }

    /**
     * @notice Burn tokens from the supply
     * @param amount No. of tokens
     */
    function burnTokens(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}
