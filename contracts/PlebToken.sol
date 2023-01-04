// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PlebToken is ERC20, ERC20Burnable, Ownable {
    address public plebContract;
    uint256 constant TOTAL_SUP = 130e12 * 1e18;

    constructor() ERC20("PlebToken", "PLEB") {}

    modifier isMinter(address _addr) {
        require((_addr == owner() || _addr == plebContract));
        _;
    }

    modifier isTotalSupplyReached(uint256 amount) {
        require((totalSupply() + amount) < TOTAL_SUP, "Reached Supply");
        _;
    }

    function setPlebContractAddress(address _plebContract) public onlyOwner {
        plebContract = _plebContract;
    }

    function mint(
        address to,
        uint256 amount
    ) external isMinter(msg.sender) isTotalSupplyReached(amount) {
        _mint(to, amount);
    }
}
