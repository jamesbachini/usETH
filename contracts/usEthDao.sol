// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract usEthDao is ERC20, Ownable {

    address public usEthAddress;

    constructor(address _usEthAddress) ERC20("usETH DAO", "USED") {
      _mint(msg.sender, 1000000000 ether);
      usEthAddress = _usEthAddress;
    }

}
