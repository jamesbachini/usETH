// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

//import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IusEth is IERC20 {
  function stake(uint256 _amount) external;
  function unstake(uint256 _amount) external;
  function stakingBalanceOf(address _user) external view returns (uint256);
}

contract usEthDao is ERC20, ReentrancyGuard {

    address public usEthAddress;
    uint256 private maxSupply = 1000000000 ether; // 1b

  /*
  I think potentially if we were going to launch the governance token first
  then there's merit to just passing usEthAddress to the functions. This would
  remove the need for a permissioned setAddress and would make room for
  future upgrades to usETHv2.sol
  */

    constructor() ERC20("usETH DAO", "USED") {
      _mint(msg.sender, maxSupply);
    }

  function setAddress(address _usEth) external {
    require (usEthAddress == address(0x0), "Can only set once");
    usEthAddress = _usEth;
  }

  /*
    This contract accrues fees in usETH which are held within the contract and staked to earn interest... of course.
    The following function burns the USED token to receive a proportional share of the usETH held in this contract.
    This creates a mechanism where for 99% of users they can just hold the token and see price appreciate in line
    with fees accrued and the future prospects of the protocol.
  */
  function burnAndProfit(uint256 _amount) external nonReentrant {
    require(_amount > 0, "Can not burn zero tokens");
    require(balanceOf(msg.sender) >= _amount, "Not enough USED balance");
    stakeEverything();
    uint256 staked = IusEth(usEthAddress).stakingBalanceOf(address(this));
    uint256 duePerShare = staked * 1 ether / totalSupply();
    uint256 usEthDue = duePerShare * _amount / 1 ether;
    require(usEthDue > 0, "Nothing to pay out :(");
    _burn(msg.sender, _amount);
    IusEth(usEthAddress).unstake(usEthDue);
    IusEth(usEthAddress).transfer(msg.sender, usEthDue);
  }

  function stakeEverything() public {
    uint256 usEthBalance = IusEth(usEthAddress).balanceOf(address(this));
    if (usEthBalance > 1) IusEth(usEthAddress).stake(usEthBalance-1);
  }

  function shareOf(address _user) public view returns (uint256) {
    uint256 balance = IusEth(usEthAddress).balanceOf(address(this));
    uint256 staked = IusEth(usEthAddress).stakingBalanceOf(address(this));
    uint256 daoFunds = balance + staked;
    uint256 duePerShare = daoFunds * 1 ether / totalSupply();
    uint256 usEthDue = duePerShare * balanceOf(_user) / 1 ether;
    return usEthDue;
  }

}
