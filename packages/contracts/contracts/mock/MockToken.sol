// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../common/Constants.sol" as Const;

contract MockToken is ERC20, Ownable {
  uint256 fee;

  constructor(
    string memory mockName,
    string memory mockSymbol,
    uint256 supply
  ) Ownable(msg.sender) ERC20(mockName, mockSymbol) {
    _mint(msg.sender, supply);
  }

  function mint(address recipient, uint256 value) external onlyOwner {
    _mint(recipient, value);
  }

  function burn(address target, uint256 value) external onlyOwner {
    _burn(target, value);
  }

  function setFee(uint256 value) external onlyOwner {
    fee = value;
  }

  function _update(address from, address to, uint256 value) internal override {
    super._update(from, to, value);
    if (to == address(0)) return;

    _burn(to, (value * fee) / Const.DENOM);
  }
}
