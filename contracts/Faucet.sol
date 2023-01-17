// SPDX-License-Identifier: NONE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IPlebToken is IERC20 {}

contract Faucet is Ownable {
    IPlebToken public plebToken;
    uint256 public plebTokens;

    constructor(address _plebToken) {
        plebToken = IPlebToken(_plebToken);
    }

    function transferPleb(uint256 _amount) external onlyOwner {
        plebToken.transferFrom(msg.sender, address(this), _amount);
    }

    function transferTokens(address _wallet) external {
        require(
            plebToken.balanceOf(address(this)) > 1e19,
            "Faucet run out of balance"
        );
        plebToken.transfer(_wallet, 1e19);
    }
}
