// SPDX-License-Identifier: NONE
pragma solidity ^0.8.0;
contract PlebToken {

// Max supply of 130 trillion tokens
 uint256 constant MAX_SUPPLY = 130 * 1e12 *1e18;

// Token name and symbol
string public name = "Pleb Token";
string public symbol = "PLEB";

// Number of decimal places
uint8 public decimals = 18;

// Mapping from account addresses to their token balances
mapping(address => uint256) public balances;
 
  constructor()  {

    balances[msg.sender] = MAX_SUPPLY;
  }

  // ERC20 functions

  // Returns the total supply of the token
  function totalSupply() public pure returns (uint256) {
    return MAX_SUPPLY;
  }

  // Returns the balance of the specified account
  function balanceOf(address account) public view returns (uint256) {
    return balances[account];
  }

  // Transfers `amount` tokens from the caller's account to `recipient`
  function transfer(address recipient, uint256 amount) public {
    require(balances[msg.sender] >= amount, "Insufficient balance");
    balances[msg.sender] -= amount;
    balances[recipient] += amount;
  }

  // Approves `spender` to transfer `amount` tokens on the caller's behalf
  function approve(address spender, uint256 amount) public {
    // Set the approved amount for the spender
    allowed[msg.sender][spender] = amount;
  }

  // Returns the amount of tokens approved by the caller to `spender`
  function allowance(address owner, address spender) public view returns (uint256) {
    return allowed[owner][spender];
  }

  // Transfers `amount` tokens from `sender` to `recipient` on the behalf of `sender`
  function transferFrom(address sender, address recipient, uint256 amount) public {
    require(balances[sender] >= amount, "Insufficient balance");
    require(allowed[sender][msg.sender] >= amount, "Insufficient allowance");
    balances[sender] -= amount;
    balances[recipient] += amount;
    allowed[sender][msg.sender] -= amount;
  }

  // Mapping from accounts to their allowed amounts for other accounts
  mapping(address => mapping(address => uint256)) public allowed;

  // Events
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  // Emits a Transfer event
  function _transfer(address from, address to, uint256 value) internal {
    emit Transfer(from, to, value);
  }

  // Emits an Approval event
  function _approve(address owner, address spender, uint256 value) internal {
    emit Approval(owner, spender, value);
  }
}
