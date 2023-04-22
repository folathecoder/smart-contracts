// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "hardhat/console.sol";

contract Token is ERC20 {
  address payable private owner;
  string private tokenName = "FolaCoin";
  string private tokenSymbol = "FOL";

  modifier onlyOwner {
      require(msg.sender == owner, "Only an owner can call this function");
      _;
  }

  constructor() ERC20(tokenName, tokenSymbol) {
    owner = payable(msg.sender);
  }

    function getOwner() external view returns(address) {
    return owner;
  } 

  function mint(address _account, uint256 _amount) external onlyOwner {
      _mint(_account, _amount);
  }

}